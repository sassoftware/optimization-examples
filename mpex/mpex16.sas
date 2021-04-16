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
/*    NAME: mpex16                                             */
/*   TITLE: Hydro Power (mpex16)                               */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 16 from the Mathematical Programming       */
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

data hydro_data;
   input hydro $ level unit_cost depth_rate startup_cost;
   datalines;
A  900  90 0.31 1500
B 1400 150 0.47 1200
;

%let reserve = 0.15;
%let min_depth = 15;
%let max_depth = 20;
%let midnight_depth = 16;
%let meters_per_mwh = 1/3000;

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

   set <str> HYDROS;
   num hydro_level {HYDROS};
   num hydro_unit_cost {HYDROS};
   num hydro_depth_rate {HYDROS};
   num hydro_startup_cost {HYDROS};
   read data hydro_data into HYDROS=[hydro]
      hydro_level=level hydro_unit_cost=unit_cost hydro_depth_rate=depth_rate
      hydro_startup_cost=startup_cost;

   var HydroNumWorking {PERIODS, HYDROS} binary;
   var HydroNumStartup {PERIODS, HYDROS} binary;
   var Depth {PERIODS} >= &min_depth <= &max_depth;
   fix Depth[1] = &midnight_depth;
   var Pump {PERIODS} >= 0;

   impvar HydroOutput {period in PERIODS, hydro in HYDROS} =
      hydro_level[hydro] * HydroNumWorking[period,hydro];

   min TotalCost =
      sum {period in PERIODS, type in TYPES} (
         unit_cost[type] * length[period] * NumWorking[period,type]
         + excess_cost[type] * length[period] * Excess[period,type]
         + startup_cost[type] * NumStartup[period,type])
      + sum {period in PERIODS, hydro in HYDROS} (
         hydro_unit_cost[hydro] * length[period] *
            HydroNumWorking[period,hydro]
         + hydro_startup_cost[hydro] * HydroNumStartup[period,hydro]);

   con Demand_con {period in PERIODS}:
      sum {type in TYPES} Output[period,type]
    + sum {hydro in HYDROS} HydroOutput[period,hydro]
    - Pump[period]
   >= demand[period];

   con Reserve_con {period in PERIODS}:
      sum {type in TYPES} max_level[type] * NumWorking[period,type]
    + sum {hydro in HYDROS} hydro_level[hydro] *
         HydroNumWorking[period,hydro].ub
   >= (1 + &reserve) * demand[period];

   con Excess_ub {period in PERIODS, type in TYPES}:
      Excess[period,type]
   <= (max_level[type] - min_level[type]) * NumWorking[period,type];

   con Startup_con {period in PERIODS, type in TYPES}:
      NumStartup[period,type]
   >= NumWorking[period,type]
    - (if period - 1 in PERIODS then NumWorking[period-1,type]
       else NumWorking[card(PERIODS),type]);

   con Hydro_startup_con {period in PERIODS, hydro in HYDROS}:
      HydroNumStartup[period,hydro]
   >= HydroNumWorking[period,hydro]
    - (if period - 1 in PERIODS then HydroNumWorking[period-1,hydro]
       else HydroNumWorking[card(PERIODS),hydro]);

   con Depth_con {period in PERIODS}:
      (if period + 1 in PERIODS then Depth[period+1] else Depth[1])
    = Depth[period]
    + &meters_per_mwh * length[period] * Pump[period]
    - sum {hydro in HYDROS} hydro_depth_rate[hydro] * length[period] *
         HydroNumWorking[period,hydro];

   solve;
   print NumWorking NumStartup Excess Output;
   print HydroNumWorking HydroNumStartup HydroOutput;
   print Pump Depth;
   create data sol_data1 from [period type]
      NumWorking NumStartup Excess Output;
   create data sol_data2 from [period hydro]
      HydroNumWorking HydroNumStartup HydroOutput;
   create data sol_data3 from [period] Pump Depth;
quit;
