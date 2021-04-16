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
/*    NAME: mpex04                                             */
/*   TITLE: Factory Planning 2 (mpex04)                        */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 04 from the Mathematical Programming       */
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

data machine_type_data;
   input machine_type $ num_machines num_machines_needing_maintenance;
   datalines;
grinder 4 2
vdrill  2 2
hdrill  3 3
borer   1 1
planer  1 1
;

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

   num num_machines_needing_maintenance {MACHINE_TYPES};
   read data machine_type_data into MACHINE_TYPES=[machine_type]
      num_machines num_machines_needing_maintenance;

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

   var NumMachinesDown {MACHINE_TYPES, PERIODS} >= 0 integer;

   con Machine_hours_con {machine_type in MACHINE_TYPES, period in PERIODS}:
      sum {product in PRODUCTS}
         production_time[product,machine_type] * Make[product,period]
   <= &num_hours_per_period *
      (num_machines[machine_type] - NumMachinesDown[machine_type,period]);

   con Maintenance_con {machine_type in MACHINE_TYPES}:
      sum {period in PERIODS} NumMachinesDown[machine_type,period]
    = num_machines_needing_maintenance[machine_type];

   con Flow_balance_con {product in PRODUCTS, period in PERIODS}:
      (if period - 1 in PERIODS then Store[product,period-1] else 0)
    + Make[product,period]
    = Sell[product,period] + Store[product,period];

   solve;
   print Make best4. Sell best4. Store best4.;
   print NumMachinesDown best4.;
   create data sol_data1 from [product period] Make Sell Store;
   create data sol_data2 from [machine_type period] NumMachinesDown;
quit;
