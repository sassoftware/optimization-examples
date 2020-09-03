/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Dynamic Reduction of Big-M Coefficients (section 14.1.2.1).

*/
proc optmodel;
   /* Declare input data. */
   set PRODUCTS = {1..7};
   set PAIRS = {i in PRODUCTS, j in PRODUCTS: i ne j};
   num capacities{PRODUCTS} = [100 80 90 60 100 110 100];
   num people{PRODUCTS} = [11 6 6 5 5 4 1];
   num delta = 20;
   num people_max = 20;
   num demand = 120;
   num price{PRODUCTS} = [2 3 4 5 6 7 8];

   /* Declare the initial M and N values. */
   num M{product in PRODUCTS} init capacities[product];
   num N{<i1,i2> in PAIRS} init max(M[i1], M[i2]) - delta;

   /* Declare the variables. */
   var X{PRODUCTS} >= 0;
   var Select{PRODUCTS} binary;

   /* Declare objective. */
   max profit = sum{product in PRODUCTS} price[product] * X[product];

   /* Declare demand constraint. */
   con DemandCon:
      sum{product in PRODUCTS} X[product] = demand;

   /* Declare variable upper bound constraints. */
   con Vub {product in PRODUCTS}:
      X[product] <= M[product] * Select[product];

   /* Declare pairwise production difference constraints. */
   con Difference1 {<i1,i2> in PAIRS}:
      X[i1] - X[i2] <= delta + N[i1,i2] * (2 - Select[i1] - Select[i2]);
   con Difference2 {<i1,i2> in PAIRS}:
      X[i2] - X[i1] <= delta + N[i1,i2] * (2 - Select[i1] - Select[i2]);

   /* Declare people knapsack constraint. */
   con PeopleCon:
      sum {product in PRODUCTS} people[product] * Select[product] <= people_max;

   /* Solve the problem. Disable some techniques to show bigger improvements. */
   solve with milp / cuts=none presolver=none heuristics=none;

   /* Declare a helper set and an auxilliary objective. */
   set S init {1};
   max bigM = sum {product in S} X[product];

   /* Loop over products and optimize for each of the bigMs. */
   for {product in PRODUCTS} do;
      S = {product};
   	  Fix Select[product] = 1;
      solve obj bigM;
	  M[product] = bigM.sol;
	  Unfix Select[product];
   end;

   /* Solve the problem. Disable some techniques to show bigger improvements. */
   solve with milp obj profit / cuts=none presolver=none heuristics=none;

   /* Print the bigM values that we achieved. */
   print M;
quit;
