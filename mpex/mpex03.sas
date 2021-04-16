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
/*    NAME: mpex03                                             */
/*   TITLE: Factory Planning 1 (mpex03)                        */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 03 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data product_data;
   input product $ profit;
   datalines;
prod1 10
prod2  6
prod3  8
prod4  4
prod5 11
prod6  9
prod7  3
;

data demand_data;
   input prod1-prod7;
   datalines;
500 1000 300 300  800 200 100
600  500 200   0  400 300 150
300  600   0   0  500 400 100
200  300 400 500  200   0 100
  0  100 500 100 1000 300   0
500  500 100 300 1100 500  60
;

data machine_type_data;
   input machine_type $ num_machines;
   datalines;
grinder 4
vdrill  2
hdrill  3
borer   1
planer  1
;

data machine_type_period_data;
   input machine_type $ period num_down;
   datalines;
grinder 1 1
hdrill  2 2
borer   3 1
vdrill  4 1
grinder 5 1
vdrill  5 1
planer  6 1
hdrill  6 1
;

data machine_type_product_data;
   input machine_type $ prod1-prod7;
   datalines;
grinder 0.5  0.7  0    0    0.3  0.2 0.5
vdrill  0.1  0.2  0    0.3  0    0.6 0
hdrill  0.2  0    0.8  0    0    0   0.6
borer   0.05 0.03 0    0.07 0.1  0   0.08
planer  0    0    0.01 0    0.05 0   0.05
;

%let store_ub = 100;
%let storage_cost_per_unit = 0.5;
%let final_storage = 50;
%let num_hours_per_period = 24 * 2 * 8;

proc optmodel;
   set <str> PRODUCTS;
   num profit {PRODUCTS};
   read data product_data into PRODUCTS=[product] profit;

   set PERIODS;
   num demand {PRODUCTS, PERIODS};
   read data demand_data into PERIODS=[_N_]
      {product in PRODUCTS} <demand[product,_N_]=col(product)>;

   set <str> MACHINE_TYPES;
   num num_machines {MACHINE_TYPES};
   read data machine_type_data into MACHINE_TYPES=[machine_type] num_machines;

   num num_machines_per_period {machine_type in MACHINE_TYPES, PERIODS}
      init num_machines[machine_type];
   num num_machines_down_per_period {MACHINE_TYPES, PERIODS} init 0;
   read data machine_type_period_data into [machine_type period]
      num_machines_down_per_period=num_down;
   for {machine_type in MACHINE_TYPES, period in PERIODS}
      num_machines_per_period[machine_type,period] =
      num_machines_per_period[machine_type,period]
    - num_machines_down_per_period[machine_type,period];
   print num_machines_per_period;

   num production_time {PRODUCTS, MACHINE_TYPES};
   read data machine_type_product_data into [machine_type]
      {product in PRODUCTS}
      <production_time[product,machine_type]=col(product)>;

   var Make {PRODUCTS, PERIODS} >= 0;
   var Sell {product in PRODUCTS, period in PERIODS} >= 0
      <= demand[product,period];

   num last_period = max {period in PERIODS} period;
   var Store {PRODUCTS, PERIODS} >= 0 <= &store_ub;
   for {product in PRODUCTS}
      fix Store[product,last_period] = &final_storage;

   impvar StorageCost =
      sum {product in PRODUCTS, period in PERIODS}
         &storage_cost_per_unit * Store[product,period];
   max TotalProfit =
      sum {product in PRODUCTS, period in PERIODS}
         profit[product] * Sell[product,period]
    - StorageCost;

   con Machine_hours_con {machine_type in MACHINE_TYPES, period in PERIODS}:
      sum {product in PRODUCTS}
         production_time[product,machine_type] * Make[product,period]
   <= &num_hours_per_period * num_machines_per_period[machine_type,period];

   con Flow_balance_con {product in PRODUCTS, period in PERIODS}:
      (if period - 1 in PERIODS then Store[product,period-1] else 0)
    + Make[product,period]
    = Sell[product,period] + Store[product,period];

   solve;
   print Make Sell Store;

   print Machine_hours_con.dual;
   create data sol_data1 from [product period] Make Sell Store;
quit;
