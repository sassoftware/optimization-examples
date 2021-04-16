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
/*    NAME: mpex01                                             */
/*   TITLE: Food Manufacture 1 (mpex01)                        */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*    KEYS: OR                                                 */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 01 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data cost_data;
   input veg1-veg2 oil1-oil3;
   datalines;
110  120  130  110  115
130  130  110   90  115
110  140  130  100   95
120  110  120  120  125
100  120  150  110  105
 90  100  140   80  135
;

data hardness_data;
   input oil $ hardness;
   datalines;
veg1 8.8
veg2 6.1
oil1 2.0
oil2 4.2
oil3 5.0
;

%let revenue_per_ton = 150;
%let veg_ub = 200;
%let nonveg_ub = 250;
%let store_ub = 1000;
%let storage_cost_per_ton = 5;
%let hardness_lb = 3;
%let hardness_ub = 6;
%let init_storage = 500;

proc optmodel;
   set <str> OILS;
   num hardness {OILS};
   read data hardness_data into OILS=[oil] hardness;
   print hardness;

   set PERIODS;
   num cost {OILS, PERIODS};
   read data cost_data into PERIODS=[_N_] {oil in OILS}
      <cost[oil,_N_]=col(oil)>;
   print cost;

   /* tons of raw oil to buy per period */
   var Buy {OILS, PERIODS} >= 0;
   var Use {OILS, PERIODS} >= 0;
   impvar Manufacture {period in PERIODS} = sum {oil in OILS} Use[oil,period];

   num last_period = max {period in PERIODS} period;
   var Store {OILS, PERIODS union {0}} >= 0 <= &store_ub;
   for {oil in OILS} do;
      fix Store[oil,0]           = &init_storage;
      fix Store[oil,last_period] = &init_storage;
   end;

   set VEG = {oil in OILS: substr(oil,1,3) = 'veg'};
   set NONVEG = OILS diff VEG;

   impvar Revenue =
      sum {period in PERIODS} &revenue_per_ton * Manufacture[period];
   impvar RawCost =
      sum {oil in OILS, period in PERIODS} cost[oil,period] * Buy[oil,period];
   impvar StorageCost =
      sum {oil in OILS, period in PERIODS}
         &storage_cost_per_ton * Store[oil,period];
   max Profit = Revenue - RawCost - StorageCost;

   con Veg_ub_con {period in PERIODS}:
      sum {oil in VEG} Use[oil,period] <= &veg_ub;

   con Nonveg_ub_con {period in PERIODS}:
      sum {oil in NONVEG} Use[oil,period] <= &nonveg_ub;

   con Flow_balance_con {oil in OILS, period in PERIODS}:
      Store[oil,period-1] + Buy[oil,period]
         = Use[oil,period] + Store[oil,period];

   con Hardness_ub_con {period in PERIODS}:
      sum {oil in OILS} hardness[oil] * Use[oil,period]
      >= &hardness_lb * Manufacture[period];

   con Hardness_lb_con {period in PERIODS}:
      sum {oil in OILS} hardness[oil] * Use[oil,period]
      <= &hardness_ub * Manufacture[period];

   expand;

   num hardness_sol {period in PERIODS} =
      (sum {oil in OILS} hardness[oil] * Use[oil,period].sol)
         / Manufacture[period].sol;

   solve;
   print Buy Use Store Manufacture hardness_sol;

   create data sol_data1 from [oil period] Buy Use Store;
   create data sol_data2 from [period] Manufacture;

   solve with lp / algorithm=ps;
   print Buy Use Store Manufacture hardness_sol;
   solve with lp / algorithm=ip;
   print Buy Use Store Manufacture hardness_sol;
   solve with lp / algorithm=ns;
   print Buy Use Store Manufacture hardness_sol;
quit;
