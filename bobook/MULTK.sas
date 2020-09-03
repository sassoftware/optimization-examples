/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 7.4.

*/
data component_data;
   input weights values;
   datalines;
40 80
10 20
40 60
30 40
50 60
50 60
55 65
25 25
40 30
;

proc optmodel;
   /* Declare and read input data. */
   set <str> BOARDS = {"Board1", "Board2", "Board3"};
   num weight_limit{BOARDS} = [80 90 85];
   set COMPONENTS;
   num weights{COMPONENTS};
   num values{COMPONENTS};
   read data component_data into COMPONENTS=[_N_] weights values;

   /* Declare the variables. */
   var Assign{BOARDS, COMPONENTS} binary;

   /* Declare the objective. */
   max TotalValue = sum {board in BOARDS, component in COMPONENTS} values[component] * Assign[board, component];

   /* Each component only once. */
   con OnlyOnce {component in COMPONENTS}:
      sum {board in BOARDS} Assign[board, component] <= 1;

   /* Define the weight constraints. */
   con WeightMax {board in BOARDS}:
      sum {component in COMPONENTS} weights[component] * Assign[board, component] <= weight_limit[board];

   /* Solve the problem. */
   solve;

   /* Print the optimal solution. */
   print Assign;
quit;
