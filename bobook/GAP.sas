/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 7.2.

*/
/* Cost table from the book. */
data cost_data;
   input container $10. load1-load8;
   datalines;
Container1 27 12 12 16 24 31 41 13
Container2 14 5 37 9 36 25 1 34
Container3 34 34 20 9 19 19 3 34
;

/* Weight table from the book. */
data weight_data;
   input container $10. load1-load8;
   datalines;
Container1 21 13 9 5 7 15 5 24
Container2 20 8 18 25 6 6 9 6
Container3 16 16 18 24 11 11 16 18
;

proc optmodel;
   /* Declare and read input data. */
   set <str> CONTAINERS;
   num size{CONTAINERS} = [26 25 34];
   set LOADS = {1..8};
   num cost{CONTAINERS, LOADS};
   num weight{CONTAINERS, LOADS};
   read data cost_data into CONTAINERS=[container] {load in LOADS} <cost[container, load] = col("load"||load)>;
   read data weight_data into [container] {load in LOADS} <weight[container, load] = col("load"||load)>;

   /* Declare the variables. */
   var Assign{CONTAINERS, LOADS} binary;

   /* Declare the objective function. */
   min TotalCost = sum {container in CONTAINERS, load in LOADS} cost[container, load] * Assign[container, load];

   /* All loads need to be assigned to exactly one container. */
   con Assignment{load in LOADS}:
      sum {container in CONTAINERS} Assign[container, load] = 1;

   /* Weight constraint. */
   con WeightLimit{container in CONTAINERS}:
      sum {load in LOADS} weight[container, load] * Assign[container, load] <= size[container];

   /* Solve the problem, the MILP solver is selected automatically. */
   solve;

   /* Print the optimal solution. */
   print Assign;
quit;
