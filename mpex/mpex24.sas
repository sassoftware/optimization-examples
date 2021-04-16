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
/*    NAME: mpex24                                             */
/*   TITLE: Yield Management (mpex24)                          */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 24 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data class_data;
   input class $9. num_seats;
   datalines;
First    37
Business 38
Economy  47
;

data price_data;
   input period class $9. price1-price3;
   datalines;
1 First    1200 1000  950
1 Business  900  800  600
1 Economy   500  300  200
2 First    1400 1300 1150
2 Business 1100  900  750
2 Economy   700  400  350
3 First    1500  900  850
3 Business  820  800  500
3 Economy   480  470  450
;

data scenario_data;
   input prob;
   datalines;
0.1
0.7
0.2
;

data demand_data;
   input period scenario class $9. demand1-demand3;
   datalines;
1 1 First    10 15 20
1 1 Business 20 25 35
1 1 Economy  45 55 60
1 2 First    20 25 35
1 2 Business 40 42 45
1 2 Economy  50 52 63
1 3 First    45 50 60
1 3 Business 45 46 47
1 3 Economy  55 56 64
2 1 First    20 25 35
2 1 Business 42 45 46
2 1 Economy  50 52 60
2 2 First    10 40 50
2 2 Business 50 60 80
2 2 Economy  60 65 90
2 3 First    50 55 80
2 3 Business 20 30 50
2 3 Economy  10 40 60
3 1 First    30 35 40
3 1 Business 40 50 55
3 1 Economy  50 60 80
3 2 First    30 40 60
3 2 Business 10 40 45
3 2 Economy  50 60 70
3 3 First    50 70 80
3 3 Business 40 45 60
3 3 Economy  60 65 70
;

data actual_demand_data;
   input period class $9. demand1-demand3;
   datalines;
1 First    25 30 40
1 Business 50 40 45
1 Economy  50 53 65
2 First    22 45 50
2 Business 45 55 75
2 Economy  50 60 80
3 First    45 60 75
3 Business 20 40 50
3 Economy  55 60 75
;

%let num_periods = 3;
%let num_planes = 6;
%let plane_cost = 50000;
%let transfer_fraction_ub = 0.10;
%let num_options = 3;

proc optmodel;
   set PERIODS = 1..&num_periods;

   set <str> CLASSES;
   num num_seats {CLASSES};
   read data class_data into CLASSES=[class] num_seats;

   set OPTIONS = 1..&num_options;

   num price {PERIODS, CLASSES, OPTIONS};
   read data price_data into [period class]
      {option in OPTIONS} <price[period,class,option]=col('price'||option)>;

   set SCENARIOS;
   num prob {SCENARIOS};
   read data scenario_data into SCENARIOS=[_N_] prob;
   set SCENARIOS2 = SCENARIOS cross SCENARIOS;
   set SCENARIOS3 = SCENARIOS2 cross SCENARIOS;

   num demand {PERIODS, SCENARIOS, CLASSES, OPTIONS};
   read data demand_data into [period scenario class]
      {option in OPTIONS}
      <demand[period,scenario,class,option]=col('demand'||option)>;

   num actual_demand {PERIODS, CLASSES, OPTIONS};
   read data actual_demand_data into [period class]
      {option in OPTIONS}
      <actual_demand[period,class,option]=col('demand'||option)>;

   num actual_price {PERIODS, CLASSES};
   num actual_sales {PERIODS, CLASSES};
   num actual_revenue {PERIODS, CLASSES};

   num current_period;

   var P1 {CLASSES, OPTIONS} binary;
   var P2 {SCENARIOS, CLASSES, OPTIONS} binary;
   var P3 {SCENARIOS2, CLASSES, OPTIONS} binary;

   var S1 {SCENARIOS, CLASSES, OPTIONS} >= 0;
   var S2 {SCENARIOS2, CLASSES, OPTIONS} >= 0;
   var S3 {SCENARIOS3, CLASSES, OPTIONS} >= 0;

   var R1 {SCENARIOS, CLASSES, OPTIONS} >= 0;
   var R2 {SCENARIOS2, CLASSES, OPTIONS} >= 0;
   var R3 {SCENARIOS3, CLASSES, OPTIONS} >= 0;

   var TransferFrom {SCENARIOS3, CLASSES} >= 0;
   var TransferTo {SCENARIOS3, CLASSES} >= 0;

   var NumPlanes >= 0 <= &num_planes integer;

   con NumPlanes_con {<i,j,k> in SCENARIOS3, class in CLASSES}:
      sum {option in OPTIONS}
         (S1[i,class,option] + S2[i,j,class,option] + S3[i,j,k,class,option])
    + TransferFrom[i,j,k,class] - TransferTo[i,j,k,class]
   <= num_seats[class] * NumPlanes;

   for {<i,j,k> in SCENARIOS3, class in CLASSES} do;
      TransferFrom[i,j,k,class].ub = &transfer_fraction_ub * num_seats[class];
      TransferTo[i,j,k,class].ub   = &transfer_fraction_ub * num_seats[class];
   end;
   con Balance_con {<i,j,k> in SCENARIOS3}:
      sum {class in CLASSES} TransferFrom[i,j,k,class]
    = sum {class in CLASSES} TransferTo[i,j,k,class];

   con P1_con {class in CLASSES}:
      sum {option in OPTIONS} P1[class,option] = 1;
   con P2_con {i in SCENARIOS, class in CLASSES}:
      sum {option in OPTIONS} P2[i,class,option] = 1;
   con P3_con {<i,j> in SCENARIOS2, class in CLASSES}:
      sum {option in OPTIONS} P3[i,j,class,option] = 1;

   con S1_con {i in SCENARIOS, class in CLASSES, option in OPTIONS}:
      S1[i,class,option] <= demand[1,i,class,option] * P1[class,option];
   con S2_con {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS}:
      S2[i,j,class,option] <= demand[2,j,class,option] * P2[i,class,option];
   con S3_con {<i,j,k> in SCENARIOS3, class in CLASSES, option in OPTIONS}:
      S3[i,j,k,class,option] <= demand[3,k,class,option] *
         P3[i,j,class,option];

   /* R1[i,class,option] =
      price[1,class,option] * P1[class,option] * S1[i,class,option] */
   con R1_con_a {i in SCENARIOS, class in CLASSES, option in OPTIONS}:
      R1[i,class,option] <= price[1,class,option] * S1[i,class,option];
   con R1_con_b {i in SCENARIOS, class in CLASSES, option in OPTIONS}:
      price[1,class,option] * S1[i,class,option] - R1[i,class,option]
   <= price[1,class,option] * demand[1,i,class,option] *
         (1 - P1[class,option]);

   /* R2[i,j,class,option] =
      price[2,class,option] * P2[i,class,option] * S2[i,j,class,option] */
   con R2_con_a {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS}:
      R2[i,j,class,option] <= price[2,class,option] * S2[i,j,class,option];
   con R2_con_b {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS}:
      price[2,class,option] * S2[i,j,class,option] - R2[i,j,class,option]
   <= price[2,class,option] * demand[2,j,class,option] *
         (1 - P2[i,class,option]);

   /* R3[i,j,k,class,option] =
      price[3,class,option] * P3[i,j,class,option] * S3[i,j,k,class,option] */
   con R3_con_a {<i,j,k> in SCENARIOS3, class in CLASSES, option in OPTIONS}:
      R3[i,j,k,class,option] <= price[3,class,option] * S3[i,j,k,class,option];
   con R3_con_b {<i,j,k> in SCENARIOS3, class in CLASSES, option in OPTIONS}:
      price[3,class,option] * S3[i,j,k,class,option] - R3[i,j,k,class,option]
   <= price[3,class,option] * demand[3,k,class,option] *
         (1 - P3[i,j,class,option]);

   max ExpectedYield =
      (if current_period <= 1
       then sum {i in SCENARIOS, class in CLASSES, option in OPTIONS}
               prob[i] * R1[i,class,option])
    + (if current_period <= 2
       then sum {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS}
               prob[i] * prob[j] * R2[i,j,class,option])
    + (if current_period <= 3
       then sum {<i,j,k> in SCENARIOS3, class in CLASSES, option in OPTIONS}
               prob[i] * prob[j] * prob[k] * R3[i,j,k,class,option])
    + sum {period in 1..current_period-1, class in CLASSES}
         actual_revenue[period,class]
    - &plane_cost * NumPlanes;

   num price_sol_1 {class in CLASSES} =
      sum {option in OPTIONS} price[1,class,option] * P1[class,option].sol;
   num price_sol_2 {class in CLASSES, i in SCENARIOS} =
      sum {option in OPTIONS} price[2,class,option] * P2[i,class,option].sol;
   num price_sol_3 {class in CLASSES, <i,j> in SCENARIOS2} =
      sum {option in OPTIONS} price[3,class,option] * P3[i,j,class,option].sol;

   num remaining_seats {class in CLASSES} =
      num_seats[class] * NumPlanes.sol
    - sum {period in 1..current_period-1} actual_sales[period,class];
   num sell_up_to_1 {class in CLASSES} =
      min(
         max {i in SCENARIOS, option in OPTIONS} S1[i,class,option].sol,
         remaining_seats[class]);
   num sell_up_to_2 {class in CLASSES} =
      min(
         max {<i,j> in SCENARIOS2, option in OPTIONS} S2[i,j,class,option].sol,
         remaining_seats[class]);
   num sell_up_to_3 {class in CLASSES} =
      min(
         max {<i,j,k> in SCENARIOS3, option in OPTIONS}
         S3[i,j,k,class,option].sol, remaining_seats[class]);

   current_period = 1;
   solve;
   for {i in SCENARIOS, class in CLASSES, option in OPTIONS}
      S1[i,class,option] = round(S1[i,class,option].sol);
   print price_sol_1;
   print sell_up_to_1;
   print {i in SCENARIOS, class in CLASSES, option in OPTIONS:
      S1[i,class,option].sol > 0} S1;
   print price_sol_2;
   print price_sol_3;
   print NumPlanes ExpectedYield;

   for {class in CLASSES, option in OPTIONS} do;
      if P1[class,option].sol > 0.5 then do;
         fix P1[class,option] = 1;
         actual_price[1,class] = price_sol_1[class];
         actual_sales[1,class] =
            min(sell_up_to_1[class], actual_demand[1,class,option]);
         for {i in SCENARIOS} fix S1[i,class,option] = actual_sales[1,class];
      end;
      else fix P1[class,option] = 0;
   end;
   for {class in CLASSES}
      actual_revenue[1,class] = actual_price[1,class] * actual_sales[1,class];
   print actual_price actual_sales actual_revenue;

   drop P1_con S1_con R1_con_a R1_con_b;
   current_period = 2;
   solve;
   for {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS}
      S2[i,j,class,option] = round(S2[i,j,class,option].sol);
   print price_sol_2;
   print sell_up_to_2;
   print {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS:
      i = 1 and S2[1,j,class,option].sol > 0} S2;
   print price_sol_3;
   print NumPlanes ExpectedYield;

   for {i in SCENARIOS, class in CLASSES, option in OPTIONS} do;
      if P2[i,class,option].sol > 0.5 then do;
         fix P2[i,class,option] = 1;
         actual_price[2,class] = price_sol_2[class,i];
         actual_sales[2,class] =
            min(sell_up_to_2[class], actual_demand[2,class,option]);
         for {j in SCENARIOS} fix S2[i,j,class,option] = actual_sales[2,class];
      end;
      else fix P2[i,class,option] = 0;
   end;
   for {class in CLASSES}
      actual_revenue[2,class] = actual_price[2,class] * actual_sales[2,class];
   print actual_price actual_sales actual_revenue;

   current_period = 3;
   drop P2_con S2_con R2_con_a R2_con_b;
   solve;

   for {<i,j,k> in SCENARIOS3, class in CLASSES, option in OPTIONS}
      S3[i,j,k,class,option] = round(S3[i,j,k,class,option].sol);
   print price_sol_3;
   print sell_up_to_3;
   print {<i,j,k> in SCENARIOS3, class in CLASSES, option in OPTIONS:
      <i,j> in {<1,1>} and S3[i,j,k,class,option].sol > 0} S3;
   print NumPlanes ExpectedYield;

   for {<i,j> in SCENARIOS2, class in CLASSES, option in OPTIONS} do;
      if P3[i,j,class,option].sol > 0.5 then do;
         fix P3[i,j,class,option] = 1;
         actual_price[3,class] = price_sol_3[class,i,j];
         actual_sales[3,class] =
            min(sell_up_to_3[class], actual_demand[3,class,option]);
         for {k in SCENARIOS} fix S3[i,j,k,class,option]
            = actual_sales[3,class];
      end;
      else fix P3[i,j,class,option] = 0;
   end;

   for {class in CLASSES}
      actual_revenue[3,class] = actual_price[3,class] * actual_sales[3,class];
   print actual_price actual_sales actual_revenue;

   current_period = 4;
   print ExpectedYield;
quit;
proc optmodel;
   set PERIODS = 1..&num_periods;

   set <str> CLASSES;
   num num_seats {CLASSES};
   read data class_data into CLASSES=[class] num_seats;

   set OPTIONS = 1..&num_options;

   num price {PERIODS, CLASSES, OPTIONS};
   read data price_data into [period class]
      {option in OPTIONS} <price[period,class,option]=col('price'||option)>;

   set SCENARIOS;
   num prob {SCENARIOS};
   read data scenario_data into SCENARIOS=[_N_] prob;

   num demand {PERIODS, SCENARIOS, CLASSES, OPTIONS};
   read data demand_data into [period scenario class]
      {option in OPTIONS}
      <demand[period,scenario,class,option]=col('demand'||option)>;

   num actual_demand {PERIODS, CLASSES, OPTIONS};
   read data actual_demand_data into [period class]
      {option in OPTIONS}
      <actual_demand[period,class,option]=col('demand'||option)>;

   num actual_price {PERIODS, CLASSES};
   num actual_sales {PERIODS, CLASSES};
   num actual_revenue {PERIODS, CLASSES};

   num expected_demand {period in PERIODS, class in CLASSES, option in OPTIONS}
      = sum {scenario in SCENARIOS}
         prob[scenario] * demand[period,scenario,class,option];

   var P {PERIODS, CLASSES, OPTIONS} binary;
   var S {PERIODS, CLASSES, OPTIONS} >= 0;
   var R {PERIODS, CLASSES, OPTIONS} >= 0;

   var TransferFrom {CLASSES} >= 0;
   var TransferTo {CLASSES} >= 0;

   var NumPlanes >= 0 <= &num_planes integer;

   con NumPlanes_con {class in CLASSES}:
      sum {period in PERIODS, option in OPTIONS} S[period,class,option]
    + TransferFrom[class] - TransferTo[class]
   <= num_seats[class] * NumPlanes;

   for {class in CLASSES} do;
      TransferFrom[class].ub = &transfer_fraction_ub * num_seats[class];
      TransferTo[class].ub   = &transfer_fraction_ub * num_seats[class];
   end;
   con Balance_con:
      sum {class in CLASSES} TransferFrom[class]
    = sum {class in CLASSES} TransferTo[class];

   con P_con {period in PERIODS, class in CLASSES}:
      sum {option in OPTIONS} P[period,class,option] = 1;

   con S_con {period in PERIODS, class in CLASSES, option in OPTIONS}:
      S[period,class,option]
   <= expected_demand[period,class,option] * P[period,class,option];

   /* R[period,class,option] =
      price[period,class,option] * P[period,class,option] *
         S[period,class,option] */
   con R_con_a {period in PERIODS, class in CLASSES, option in OPTIONS}:
      R[period,class,option] <= price[period,class,option] *
         S[period,class,option];
   con R_con_b {period in PERIODS, class in CLASSES, option in OPTIONS}:
      price[period,class,option] * S[period,class,option] -
         R[period,class,option]
   <= price[period,class,option] * expected_demand[period,class,option]
      * (1 - P[period,class,option]);

   max Yield =
      sum {period in PERIODS, class in CLASSES, option in OPTIONS}
         R[period,class,option]
    - &plane_cost * NumPlanes;

   num price_sol {period in PERIODS, class in CLASSES} =
      sum {option in OPTIONS} price[period,class,option] *
         P[period,class,option].sol;

   solve;
   for {period in PERIODS, class in CLASSES, option in OPTIONS}
      S[period,class,option] = round(S[period,class,option].sol);
   print price_sol;
   print {period in PERIODS, class in CLASSES, option in OPTIONS:
      S[period,class,option].sol > 0} S;
   print NumPlanes Yield;
   for {period in PERIODS, class in CLASSES, option in OPTIONS} do;
      if P[period,class,option].sol > 0.5 then do;
         actual_price[period,class] = price_sol[period,class];
         actual_sales[period,class] =
            min(S[period,class,option], actual_demand[period,class,option]);
         actual_revenue[period,class] =
            actual_price[period,class] * actual_sales[period,class];
         R[period,class,option] = actual_revenue[period,class];
      end;
   end;
   print actual_price actual_sales actual_revenue;
   print Yield;

   drop S_con R_con_b;

   con S_con_actual {period in PERIODS, class in CLASSES, option in OPTIONS}:
      S[period,class,option]
   <= actual_demand[period,class,option] * P[period,class,option];

   con R_con_b_actual {period in PERIODS, class in CLASSES, option in OPTIONS}:
      price[period,class,option] * S[period,class,option] -
         R[period,class,option]
   <= price[period,class,option] * actual_demand[period,class,option]
      * (1 - P[period,class,option]);

   solve;
   for {period in PERIODS, class in CLASSES, option in OPTIONS}
      S[period,class,option] = round(S[period,class,option].sol);
   print price_sol;
   print {period in PERIODS, class in CLASSES, option in OPTIONS:
      S[period,class,option].sol > 0} S;
   print NumPlanes Yield;

   for {period in PERIODS, class in CLASSES, option in OPTIONS} do;
      if P[period,class,option].sol > 0.5 then do;
         actual_price[period,class] = price_sol[period,class];
         actual_sales[period,class] = S[period,class,option];
         actual_revenue[period,class] =
            actual_price[period,class] * actual_sales[period,class];
         R[period,class,option] = actual_revenue[period,class];
      end;
   end;
   print actual_price actual_sales actual_revenue;
quit;
