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
/*    NAME: mpex05                                             */
/*   TITLE: Manpower Planning (mpex05)                         */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 05 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data demand_data;
   input period unskilled semiskilled skilled;
   datalines;
0 2000 1500 1000
1 1000 1400 1000
2  500 2000 1500
3    0 2500 2000
;

data worker_data;
   input worker $12. waste_new waste_old recruit_ub redundancy_cost
      overmanning_cost shorttime_ub shorttime_cost;
   datalines;
unskilled   0.25 0.10 500 200 1500 50 500
semiskilled 0.20 0.05 800 500 2000 50 400
skilled     0.10 0.05 500 500 3000 50 400
;

data retrain_data;
   input worker1 $12. worker2 $12. retrain_ub retrain_cost;
   datalines;
unskilled   semiskilled 200 400
semiskilled skilled       . 500
;

data downgrade_data;
   input worker1 $12. worker2 $12.;
   datalines;
semiskilled unskilled
skilled     semiskilled
skilled     unskilled
;

%let semiskill_retrain_frac_ub = 0.25;
%let downgrade_leave_frac = 0.5;
%let overmanning_ub = 150;
%let shorttime_frac = 0.5;

proc optmodel;
   set <str> WORKERS;
   num waste_new {WORKERS};
   num waste_old {WORKERS};
   num recruit_ub {WORKERS};
   num redundancy_cost {WORKERS};
   num overmanning_cost {WORKERS};
   num shorttime_ub {WORKERS};
   num shorttime_cost {WORKERS};
   read data worker_data into WORKERS=[worker]
      waste_new waste_old recruit_ub redundancy_cost overmanning_cost
      shorttime_ub shorttime_cost;

   set PERIODS0;
   num demand {WORKERS, PERIODS0};
   read data demand_data into PERIODS0=[period]
      {worker in WORKERS} <demand[worker,period]=col(worker)>;

   var NumWorkers {WORKERS, PERIODS0} >= 0;
   for {worker in WORKERS} fix NumWorkers[worker,0] = demand[worker,0];

   set PERIODS = PERIODS0 diff {0};
   var NumRecruits {worker in WORKERS, PERIODS} >= 0 <= recruit_ub[worker];
   var NumRedundant {WORKERS, PERIODS} >= 0;
   var NumShortTime {worker in WORKERS, PERIODS} >= 0 <= shorttime_ub[worker];
   var NumExcess {WORKERS, PERIODS} >= 0;

   set <str,str> RETRAIN_PAIRS;
   num retrain_ub {RETRAIN_PAIRS};
   num retrain_cost {RETRAIN_PAIRS};
   read data retrain_data into RETRAIN_PAIRS=[worker1 worker2]
      retrain_ub retrain_cost;

   var NumRetrain {RETRAIN_PAIRS, PERIODS} >= 0;
   for {<i,j> in RETRAIN_PAIRS: retrain_ub[i,j] ne .}
      for {period in PERIODS} NumRetrain[i,j,period].ub = retrain_ub[i,j];

   set <str,str> DOWNGRADE_PAIRS;
   read data downgrade_data into DOWNGRADE_PAIRS=[worker1 worker2];
   var NumDowngrade {DOWNGRADE_PAIRS, PERIODS} >= 0;

   con Demand_con {worker in WORKERS, period in PERIODS}:
      NumWorkers[worker,period]
    - (1 - &shorttime_frac) * NumShortTime[worker,period]
    - NumExcess[worker,period]
    = demand[worker,period];

   con Flow_balance_con {worker in WORKERS, period in PERIODS}:
      NumWorkers[worker,period]
    = (1 - waste_old[worker]) * NumWorkers[worker,period-1]
    + (1 - waste_new[worker]) * NumRecruits[worker,period]
    + (1 - waste_old[worker]) *
         sum {<i,(worker)> in RETRAIN_PAIRS} NumRetrain[i,worker,period]
    + (1 - &downgrade_leave_frac) *
         sum {<i,(worker)> in DOWNGRADE_PAIRS} NumDowngrade[i,worker,period]
    - sum {<(worker),j> in RETRAIN_PAIRS} NumRetrain[worker,j,period]
    - sum {<(worker),j> in DOWNGRADE_PAIRS} NumDowngrade[worker,j,period]
    - NumRedundant[worker,period];

   con Semiskill_retrain_con {period in PERIODS}:
      NumRetrain['semiskilled','skilled',period]
   <= &semiskill_retrain_frac_ub * NumWorkers['skilled',period];

   con Overmanning_con {period in PERIODS}:
      sum {worker in WORKERS} NumExcess[worker,period] <= &overmanning_ub;

   min Redundancy =
      sum {worker in WORKERS, period in PERIODS} NumRedundant[worker,period];
   min Cost =
      sum {worker in WORKERS, period in PERIODS} (
         redundancy_cost[worker] * NumRedundant[worker,period]
       + shorttime_cost[worker] * NumShorttime[worker,period]
       + overmanning_cost[worker] * NumExcess[worker,period])
    + sum {<i,j> in RETRAIN_PAIRS, period in PERIODS}
         retrain_cost[i,j] * NumRetrain[i,j,period];

   solve obj Redundancy;
   print Redundancy Cost;
   print NumWorkers NumRecruits NumRedundant NumShortTime NumExcess;
   print NumRetrain;
   print NumDowngrade;
   create data sol_data1 from [worker period]
      NumWorkers NumRecruits NumRedundant NumShortTime NumExcess;
   create data sol_data2 from [worker1 worker2 period] NumRetrain NumDowngrade;

   solve obj Cost;
   print Redundancy Cost;
   print NumWorkers NumRecruits NumRedundant NumShortTime NumExcess;
   print NumRetrain;
   print NumDowngrade;
   create data sol_data3 from [worker period]
      NumWorkers NumRecruits NumRedundant NumShortTime NumExcess;
   create data sol_data4 from [worker1 worker2 period] NumRetrain NumDowngrade;
quit;
