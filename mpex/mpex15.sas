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
/*    NAME: mpex15                                             */
/*   TITLE: Tariff Rates (Power Generation) (mpex15)           */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 15 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data period_data;
   input length demand;
   datalines;
6 15000
3 30000
6 25000
3 40000
6 27000
;

data type_data;
   input num_avail min_level max_level unit_cost excess_cost startup_cost;
   datalines;
12  850 2000 1000 2    2000
10 1250 1750 2600 1.30 1000
 5 1500 4000 3000 3     500
;

%let reserve = 0.15;

proc optmodel;
   set PERIODS;
   num length {PERIODS};
   num demand {PERIODS};
   read data period_data into PERIODS=[_N_] length demand;

   set TYPES;
   num num_avail {TYPES};
   num min_level {TYPES};
   num max_level {TYPES};
   num unit_cost {TYPES};
   num excess_cost {TYPES};
   num startup_cost {TYPES};
   read data type_data into TYPES=[_N_]
      num_avail min_level max_level unit_cost excess_cost startup_cost;

   var NumWorking {PERIODS, type in TYPES} >= 0 <= num_avail[type] integer;
   var Excess {PERIODS, TYPES} >= 0;
   var NumStartup {PERIODS, type in TYPES} >= 0 <= num_avail[type] integer;

   impvar Output {period in PERIODS, type in TYPES} =
      min_level[type] * NumWorking[period,type] + Excess[period,type];

   min TotalCost =
      sum {period in PERIODS, type in TYPES} (
         unit_cost[type] * length[period] * NumWorking[period,type]
         + excess_cost[type] * length[period] * Excess[period,type]
         + startup_cost[type] * NumStartup[period,type]);

   con Demand_con {period in PERIODS}:
      sum {type in TYPES} Output[period,type]
   >= demand[period];

   con Reserve_con {period in PERIODS}:
      sum {type in TYPES} max_level[type] * NumWorking[period,type]
   >= (1 + &reserve) * demand[period];

   con Excess_ub {period in PERIODS, type in TYPES}:
      Excess[period,type]
   <= (max_level[type] - min_level[type]) * NumWorking[period,type];

   con Startup_con {period in PERIODS, type in TYPES}:
      NumStartup[period,type]
   >= NumWorking[period,type]
    - (if period - 1 in PERIODS then NumWorking[period-1,type]
       else NumWorking[card(PERIODS),type]);

   solve;
   print NumWorking NumStartup Excess Output;
   create data sol_data from [period type] NumWorking NumStartup Excess Output;

   fix NumWorking;
   fix NumStartup;
   solve with LP relaxint;
   print NumWorking NumStartup Excess Output;
   print {period in PERIODS} (demand_con[period].dual / length[period]);

   unfix NumWorking;
   unfix NumStartup;
   solve with LP relaxint;
   print NumWorking NumStartup Excess Output;
   print {period in PERIODS} (demand_con[period].dual / length[period]);
   print {period in PERIODS} (reserve_con[period].dual / length[period]);
quit;
