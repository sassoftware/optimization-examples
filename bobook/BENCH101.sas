/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Park bench manufacturing, first problem (Exercise 10.1).

*/
data requirement_data;
   input product $9. Beechwood Steel Labor;
   datalines;
Superior 14.2 1.83 1
Executive 22.4 1.94 1.26
;

data price_data;
   input product $9. Q1 Q2 Q3 Q4;
   datalines;
Superior 850 890 860 750
Executive 1050 1200 900 810
;

data beechwood_cost_data;
   input Q1 Q2 Q3 Q4;
   datalines;
28 34 22 18
;

data labor_limit_data;
   input Q1 Q2 Q3 Q4;
   datalines;
48 42 23 46
;

data initial_stock_data;
   input product $9. initial_stock;
   datalines;
Superior 2
Executive 4
;

data demand_data;
   input product $9. Q1 Q2 Q3 Q4;
   datalines;
Superior 10 20 30 10
Executive 8 25 30 5
;

proc optmodel;
   /* Declare the sets. */
   set PERIODS = {1..4};
   set <str> PRODUCTS;

   /* Declare the requirement data. We don't use a set for the materials since in exercise 10.2 we extend the problem.*/
   num beechwood_required{PRODUCTS};
   num steel_required{PRODUCTS};
   num labor_required{PRODUCTS};

   /* Read the requirement data. */
   read data requirement_data into PRODUCTS=[product] 
      beechwood_required[product]=Beechwood steel_required[product]=Steel labor_required[product]=Labor;

   /* Declare the price data. */
   num selling_price{PRODUCTS,PERIODS};

   /* Read the selling price data. */
   read data price_data into [product] {period in PERIODS} <selling_price[product,period]=col("Q" || period)>;

   /* Declare cost data. */
   num beechwood_cost{PERIODS};
   num steel_cost = 100;
   num labor_cost = 90;

   /* Read the beechwood cost data. */
   read data beechwood_cost_data into {period in PERIODS} <beechwood_cost[period]=col("Q" || period)>;

   /* Declare the labor limits. */
   num labor_limit{PERIODS};

   /* Read the labor limits. */
   read data labor_limit_data into {period in PERIODS} <labor_limit[period]=col("Q" || period)>;

   /* Declare the storage limit and cost. */
   num stoarge_limit = 10;
   num storage_cost = 82;

   /* Declare the initial stock. */
   num initial_stock{PRODUCTS};

   /* Read the initial stock. */
   read data initial_stock_data into [product] initial_stock;

   /* Declare the demand data. */
   num max_demand{PRODUCTS,PERIODS};

   /* Read the demand data. */
   read data demand_data into [product] {period in PERIODS} <max_demand[product,period]=col("Q" || period)>;

   /* Declare variables. */
   var Build{PRODUCTS,PERIODS} >= 0;
   var Sell{product in PRODUCTS, period in PERIODS} >= 0 <= max_demand[product, period];
   var Store{PRODUCTS,PERIODS} >= 0;
   var BeechwoodUsed{PERIODS} >= 0;
   var SteelUsed{PERIODS} >= 0;
   var LaborUsed{period in PERIODS} >= 0 <= labor_limit[period];

   /* Declare the objective. */
   max Profit = sum{product in PRODUCTS, period in PERIODS} selling_price[product, period] * Sell[product, period]
      - sum{product in PRODUCTS, period in PERIODS} storage_cost * Store[product, period]
	  - sum{period in PERIODS} beechwood_cost[period] * BeechwoodUsed[period]
	  - sum{period in PERIODS} steel_cost * SteelUsed[period]
	  - sum{period in PERIODS} labor_cost * LaborUsed[period];

   /* Flow balance constraints. */
   con FlowBalance {product in PRODUCTS, period in PERIODS}:
      (if period = 1 then initial_stock[product] else Store[product, period - 1])
	  + Build[product, period]
	  =
	  Sell[product, period]
	  + Store[product, period];	  

   /* Handle final stock requirement. */
   for {product in PRODUCTS}
      fix Store[product,4] = initial_stock[product];
   
   /* Material constraints. */
   con BeechwoodConstraint {period in PERIODS}:
      sum {product in PRODUCTS} beechwood_required[product] * Build[product, period] <= BeechwoodUsed[period];
   con SteelConstraint {period in PERIODS}:
      sum {product in PRODUCTS} steel_required[product] * Build[product, period] <= SteelUsed[period];
   con LaborConstraint {period in PERIODS}:
      sum {product in PRODUCTS} labor_required[product] * Build[product, period] <= LaborUsed[period];

   /* Solve the problem, the dual simplex solver is used by default. */
   solve; 

   /* Print output. */
   print Sell Sell.dual Build Build.dual Store Store.dual;
   print BeechwoodUsed SteelUsed LaborUsed;
   print FlowBalance.dual;
   print BeechwoodConstraint.dual SteelConstraint.dual LaborConstraint.dual;
quit;
