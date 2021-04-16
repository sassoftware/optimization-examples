/* Copyright © 2021, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples

A description of the examples is available at:
https://go.documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/ormpex/titlepage.htm
*/
/***************************************************************/
/*                                                             */
/*          S A S   S A M P L E   L I B R A R Y                */
/*                                                             */
/*    NAME: mpex25                                             */
/*   TITLE: Car Rental 1 (mpex25)                              */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*    KEYS: OR                                                 */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 25 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data depot_data;
   input depot $10.;
   datalines;
Glasgow
Manchester
Birmingham
Plymouth
;

data demand_data;
   input day $10. Glasgow Manchester Birmingham Plymouth;
   datalines;
Monday    100 250  95 160
Tuesday   150 143 195  99
Wednesday 135  80 242  55
Thursday   83 225 111  96
Friday    120 210  70 115
Saturday  230  98 124  80
;

data length_data;
   input length prob cost price_same price_diff;
   datalines;
1 0.55 20  50  70
2 0.20 25  70 100
3 0.25 30 120 150
;

data transition_prob_data;
   input i $10. Glasgow Manchester Birmingham Plymouth;
   datalines;
Glasgow    60 20 10 10
Manchester 15 55 25  5
Birmingham 15 20 54 11
Plymouth    8 12 27 53
;

data transfer_cost_data;
   input i $10. Glasgow Manchester Birmingham Plymouth;
   datalines;
Glasgow     . 20 30 50
Manchester 20  . 15 35
Birmingham 30 15  . 25
Plymouth   50 35 25  .
;

data repair_data;
   input depot $10. repair_capacity;
   datalines;
Manchester 12
Birmingham 20
;

%let opportunity_cost_per_week = 15;
%let transfer_length = 1;
%let repair_length = 1;
%let damage_prob = 0.10;
%let damage_charge = 100;
%let saturday_discount = 20;

proc optmodel;
   set <str> DEPOTS;
   read data depot_data into DEPOTS=[depot];

   set DAYS;
   str day_name {DAYS};
   num demand {DEPOTS, DAYS};
   read data demand_data into DAYS=[_N_];
   num num_days = card(DAYS);
   DAYS = 0..num_days-1;
   read data demand_data into [_N_]
      {depot in DEPOTS} <demand[depot,_N_-1]=col(depot)>;

   set LENGTHS;
   num length_prob {LENGTHS};
   num cost {LENGTHS};
   num price_same {LENGTHS};
   num price_diff {LENGTHS};
   read data length_data into LENGTHS=[length]
      length_prob=prob cost price_same price_diff;

   num transition_prob {DEPOTS, DEPOTS};
   read data transition_prob_data into [i]
      {j in DEPOTS} <transition_prob[i,j]=col(j)>;
   for {i in DEPOTS, j in DEPOTS}
      transition_prob[i,j] = transition_prob[i,j] / 100;

   num transfer_cost {DEPOTS, DEPOTS} init 0;
   read data transfer_cost_data nomiss into [i]
      {j in DEPOTS} <transfer_cost[i,j]=col(j)>;

   num repair_capacity {DEPOTS} init 0;
   read data repair_data into [depot] repair_capacity;

   num rental_price {i in DEPOTS, j in DEPOTS, day in DAYS, length in LENGTHS} =
      (if i = j then price_same[length] else price_diff[length])
    - (if day = 5 and length = 1 then &saturday_discount);

   num max_length = max {length in LENGTHS} length;
   num mod {s in -max_length..num_days+max_length} = mod(s+num_days,num_days);

   var NumCars >= 0;

   var NumUndamagedCarsStart {DEPOTS, DAYS} >= 0;
   var NumDamagedCarsStart {DEPOTS, DAYS} >= 0;

   var NumCarsRented_i_day {i in DEPOTS, day in DAYS} >= 0 <= demand[i,day];
   impvar NumCarsRented
      {i in DEPOTS, j in DEPOTS, day in DAYS, length in LENGTHS} =
      transition_prob[i,j] * length_prob[length] * NumCarsRented_i_day[i,day];

   var NumUndamagedCarsIdle {DEPOTS, DAYS} >= 0;
   var NumDamagedCarsIdle {DEPOTS, DAYS} >= 0;

   var NumUndamagedCarsTransferred {i in DEPOTS, DEPOTS diff {i}, DAYS} >= 0;
   var NumDamagedCarsTransferred {i in DEPOTS, DEPOTS diff {i}, DAYS} >= 0;
   impvar NumCarsTransferred {i in DEPOTS, j in DEPOTS diff {i}, day in DAYS} =
      NumUndamagedCarsTransferred[i,j,day]
    + NumDamagedCarsTransferred[i,j,day];

   var NumDamagedCarsRepaired {i in DEPOTS, DAYS} >= 0 <= repair_capacity[i];

   max Profit =
      sum {i in DEPOTS, j in DEPOTS, day in DAYS, length in LENGTHS}
         (rental_price[i,j,day,length] - cost[length])
       * NumCarsRented[i,j,day,length]
    + sum {i in DEPOTS, day in DAYS}
         &damage_prob * &damage_charge * NumCarsRented_i_day[i,day]
    - sum {i in DEPOTS, j in DEPOTS diff {i}, day in DAYS}
         transfer_cost[i,j] * NumCarsTransferred[i,j,day]
    - &opportunity_cost_per_week * NumCars;

   con Undamaged_Inflow_con {i in DEPOTS, day in DAYS}:
      NumUndamagedCarsStart[i,day]
    = (1 - &damage_prob) * sum {j in DEPOTS, length in LENGTHS}
         NumCarsRented[j,i,mod[day-length],length]
    + sum {j in DEPOTS diff {i}}
         NumUndamagedCarsTransferred[j,i,mod[day-&transfer_length]]
    + NumDamagedCarsRepaired[i,mod[day-&repair_length]]
    + NumUndamagedCarsIdle[i,mod[day-1]];

   con Damaged_Inflow_con {i in DEPOTS, day in DAYS}:
      NumDamagedCarsStart[i,day]
    = &damage_prob * sum {j in DEPOTS, length in LENGTHS}
         NumCarsRented[j,i,mod[day-length],length]
    + sum {j in DEPOTS diff {i}}
         NumDamagedCarsTransferred[j,i,mod[day-&transfer_length]]
    + NumDamagedCarsIdle[i,mod[day-1]];

   con Undamaged_Outflow_con {i in DEPOTS, day in DAYS}:
      NumUndamagedCarsStart[i,day]
    = NumCarsRented_i_day[i,day]
    + sum {j in DEPOTS diff {i}} NumUndamagedCarsTransferred[i,j,day]
    + NumUndamagedCarsIdle[i,day];

   con Damaged_Outflow_con {i in DEPOTS, day in DAYS}:
      NumDamagedCarsStart[i,day]
    = NumDamagedCarsRepaired[i,day]
    + sum {j in DEPOTS diff {i}} NumDamagedCarsTransferred[i,j,day]
    + NumDamagedCarsIdle[i,day];

   con NumCars_con:
      NumCars = sum {i in DEPOTS} (
         length_prob[3] * NumCarsRented_i_day[i,0]
       + sum {length in 2..3} length_prob[length] * NumCarsRented_i_day[i,1]
       + NumUndamagedCarsStart[i,2]
       + NumDamagedCarsStart[i,2]);

   solve;
   for {j in 1.._NVAR_} _VAR_[j] = round(_VAR_[j].sol);

   print NumCars;
   print NumUndamagedCarsStart;
   print NumDamagedCarsStart;
   print NumCarsRented_i_day;
   print {i in DEPOTS, j in DEPOTS diff {i}, day in DAYS:
      NumDamagedCarsTransferred[i,j,day].sol > 0} NumDamagedCarsTransferred;
   print NumDamagedCarsRepaired.dual;
quit;
