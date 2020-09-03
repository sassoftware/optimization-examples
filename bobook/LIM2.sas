/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 6.7, manufacturing example with fixed cost.

*/
%let numPeriods = 4;

/* Product requirement table, we treat intermediate products the same as others. */
data product_requirements;
   input product $ R1 R2 I1 I2;
   datalines;
P1 8 10 4 2
P2 6 12 3 3
;

data intermediate_requirements;
   input intermediate $ R1 R2;
   datalines;
I1 1.0 0.7
I2 0.6 1.2
;

/* Selling price table as in the book. */
data price_data;
   input product $ Month1 Month2 Month3 Month4;
   datalines;
P1 100 105 107 90
P2 90 100 110 115
;

/* Product cost table combined with stock data and including intermediates again. */
data cost_data;
   input product $ Month1 Month2 Month3 Month4 initial_stock storage_cost;
   datalines;
P1 40 42 55 35 40 3
P2 38 35 44 40 38 3
I1 6 6.2 5.3 4.8 60 1
I2 5.1 5.2 5.0 5.1 50 1
;

/* Ressource table as in the book. */
data resource_data;
   input resource $ Month1 Month2 Month3 Month4;
   datalines;
R1 200 300 100 200
R2 250 400 50 240
;

proc optmodel;
   /* Declare and read input data. */
   set PERIODS = {1..&numPeriods};
   set <str> ENDPRODUCTS;
   set <str> INTERMEDIATES; 
   set <str> RESOURCES;

   /* Read the resources so we know which resources exist. */
   num resource_available{RESOURCES, PERIODS};
   read data resource_data into RESOURCES=[resource] {period in PERIODS} <resource_available[resource, period]= col("Month"||period)>;

   /* Read the intermediates from the intermediates requirements. */ 
   num intermediate_requirements{INTERMEDIATES, RESOURCES};
   read data intermediate_requirements into INTERMEDIATES=[intermediate] {resource in RESOURCES} <intermediate_requirements[intermediate, resource]= col(resource)>;

   /* Read the products from the product requirements. */
   num product_requirements{ENDPRODUCTS, INTERMEDIATES union RESOURCES};
   read data product_requirements into ENDPRODUCTS=[product] {resource in INTERMEDIATES union RESOURCES} <product_requirements[product, resource]= col(resource)>;

   /* Read the price data. */
   num price{ENDPRODUCTS, PERIODS} init 0;
   read data price_data into ENDPRODUCTS=[product] {period in PERIODS} <price[product, period]= col("Month"||period)>;

   /* Read additional product data for both end products and intermediates. */
   set <str> PRODUCTS;
   num cost{PRODUCTS, PERIODS};
   num initial_stock{PRODUCTS union INTERMEDIATES};
   num storage_cost{PRODUCTS union INTERMEDIATES};
   read data cost_data into PRODUCTS=[product] {period in PERIODS} <cost[product, period]= col("Month"||period)> initial_stock storage_cost;

   /* Declare the variables and set bounds. */
   var Use{resource in INTERMEDIATES union RESOURCES, period in PERIODS} >= 0 integer;
   var Sell{ENDPRODUCTS, PERIODS} >= 0 <= 30 integer;
   var Produce{PRODUCTS, PERIODS} >= 0 integer;
   var Store{PRODUCTS, PERIODS} >= 0 integer;
   var BuyI1{PERIODS} >= 0 integer;
   var BuyI1FixedCost{PERIODS} binary;

   /* State the objective. */
   max TotalProfit = sum{endproduct in ENDPRODUCTS, period in PERIODS} price[endproduct,period] * Sell[endproduct,period] 
      - sum{product in PRODUCTS, period in PERIODS} cost[product, period] * Produce[product,period] 
      - sum{product in PRODUCTS, period in PERIODS} storage_cost[product] * Store[product,period]
      - sum{period in PERIODS} BuyI1[period] - sum{period in PERIODS} 400*BuyI1FixedCost[period];

   /* Resource constraints. */
   con ResourceConstraints {resource in RESOURCES, period in PERIODS}:
      sum {endproduct in ENDPRODUCTS} product_requirements[endproduct, resource] * Produce[endproduct,period] 
      + sum {intermediate in INTERMEDIATES} intermediate_requirements[intermediate, resource] * Produce[intermediate,period] 
      <= Use[resource, period];
   con IntermediateConstraints {intermediate in INTERMEDIATES, period in PERIODS}:
      sum {endproduct in ENDPRODUCTS} product_requirements[endproduct, intermediate] * Produce[endproduct,period] 
      <= Use[intermediate, period];
   con ResourceAvailability{resource in RESOURCES, period in PERIODS}:
      Use[resource, period] <= resource_available[resource, period];

   /* Flow balance constraints. */
   con FlowBalance {product in PRODUCTS, period in PERIODS}:
      (if period - 1 in PERIODS then Store[product,period - 1] else initial_stock[product])
      + Produce[product,period]
      + (if product = "I1" then BuyI1[period])
      = Store[product,period]
      + (if product in ENDPRODUCTS then Sell[product,period])
      + (if product in INTERMEDIATES then Use[product,period]);

   /* The final stock needs to match the initial stock*/
   num last_period = max {period in PERIODS} period;
   for {product in PRODUCTS}
      fix Store[product,last_period] = initial_stock[product];

   /* Constraints for handling the fixed cost on I1 purchases. */
   con FixedCost {period in PERIODS}:
      BuyI1[period] <= 400*BuyI1FixedCost[period];
 
   /* Solve the optimization problem. The solver is chosen automatically.*/
   solve;

   /* Print the optimization problem. */
   expand;

   /* */
   print Produce Store Use Sell BuyI1 BuyI1FixedCost;
quit;
