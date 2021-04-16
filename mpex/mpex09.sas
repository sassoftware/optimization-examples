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
/*    NAME: mpex09                                             */
/*   TITLE: Economic Planning (mpex09)                         */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 09 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data industry_data;
   input industry $9. init_stocks init_productive_capacity demand;
   datalines;
coal      150 300 60
steel      80 350 60
transport 100 280 30
;

data production_data;
   input input $9. coal steel transport;
   datalines;
coal      0.1 0.5 0.4
steel     0.1 0.1 0.2
transport 0.2 0.1 0.2
manpower  0.6 0.3 0.2
;

data productive_capacity_data;
   input input $9. coal steel transport;
   datalines;
coal      0.0 0.7 0.9
steel     0.1 0.1 0.2
transport 0.2 0.1 0.2
manpower  0.4 0.2 0.1
;

%let manpower_capacity = 470;
%let num_years = 5;

proc optmodel;
   num num_years = &num_years;
   set YEARS = 1..num_years;
   set YEARS0 = {0} union YEARS;

   set <str> INDUSTRIES;
   num init_stocks {INDUSTRIES};
   num init_productive_capacity {INDUSTRIES};
   num demand {INDUSTRIES};
   read data industry_data into INDUSTRIES=[industry]
      init_stocks init_productive_capacity demand;

   set <str> INPUTS;
   num production_coeff {INPUTS, INDUSTRIES};
   read data production_data into INPUTS=[input]
      {j in INDUSTRIES} <production_coeff[input,j]=col(j)>;

   num productive_capacity_coeff {INPUTS, INDUSTRIES};
   read data productive_capacity_data into INPUTS=[input]
      {j in INDUSTRIES} <productive_capacity_coeff[input,j]=col(j)>;

   var StaticProduction {INDUSTRIES} >= 0;
   min Zero = 0;
   con Static_con {i in INDUSTRIES}:
      StaticProduction[i]
    = demand[i] + sum {j in INDUSTRIES} production_coeff[i,j] *
      StaticProduction[j];

   solve;
   print StaticProduction;

   num final_demand {INDUSTRIES};
   for {i in INDUSTRIES} final_demand[i] = StaticProduction[i].sol;

   var Production {INDUSTRIES, 0..num_years+1} >= 0;
   var Stock {INDUSTRIES, 0..num_years+1} >= 0;
   var ExtraCapacity {INDUSTRIES, 1..num_years+2} >= 0;
   impvar ProductiveCapacity {i in INDUSTRIES, year in 1..num_years+1} =
      init_productive_capacity[i] + sum {y in 2..year} ExtraCapacity[i,y];
   for {i in INDUSTRIES} do;
      Production[i,0].ub = 0;
      Stock[i,0].lb = init_stocks[i];
      Stock[i,0].ub = init_stocks[i];
   end;

   max TotalProductiveCapacity =
      sum {i in INDUSTRIES} ProductiveCapacity[i,num_years];
   max TotalProduction =
      sum {i in INDUSTRIES, year in 4..5} Production[i,year];
   max TotalManpower =
      sum {i in INDUSTRIES, year in YEARS} (
         production_coeff['manpower',i] * Production[i,year+1]
       + productive_capacity_coeff['manpower',i] * ExtraCapacity[i,year+2]);

   con Continuity_con {i in INDUSTRIES, year in YEARS0}:
      Stock[i,year] + Production[i,year]
    = (if year in YEARS then demand[i] else 0)
    + sum {j in INDUSTRIES} (
         production_coeff[i,j] * Production[j,year+1]
       + productive_capacity_coeff[i,j] * ExtraCapacity[j,year+2])
    + Stock[i,year+1];

   con Manpower_con {year in 1..num_years+1}:
      sum {j in INDUSTRIES} (
         production_coeff['manpower',j] * Production[j,year]
       + productive_capacity_coeff['manpower',j] * ExtraCapacity[j,year+1])
    <= &manpower_capacity;

   con Capacity_con {i in INDUSTRIES, year in 1..num_years+1}:
      Production[i,year] <= ProductiveCapacity[i,year];

   for {i in INDUSTRIES}
      Production[i,num_years+1].lb = final_demand[i];

   for {i in INDUSTRIES, year in num_years+1..num_years+2}
      ExtraCapacity[i,year].ub = 0;

   problem Problem1 include
      Production Stock ExtraCapacity
      TotalProductiveCapacity
      Continuity_con Manpower_con Capacity_con;

   problem Problem2 from Problem1 include
      TotalProduction;

   problem Problem3 include
      Production Stock ExtraCapacity
      TotalManpower
      Continuity_con Capacity_con;

   use problem Problem1;
   solve;
   print Production Stock ExtraCapacity ProductiveCapacity Manpower_con.body;

   use problem Problem2;
   for {i in INDUSTRIES, year in YEARS} do;
      Continuity_con[i,year].lb = 0;
      Continuity_con[i,year].ub = 0;
   end;
   solve;
   print Production Stock ExtraCapacity ProductiveCapacity Manpower_con.body;

   use problem Problem3;
   for {i in INDUSTRIES, year in YEARS} do;
      Continuity_con[i,year].lb = demand[i];
      Continuity_con[i,year].ub = demand[i];
   end;
   solve;
   print Production Stock ExtraCapacity ProductiveCapacity Manpower_con.body;
quit;
