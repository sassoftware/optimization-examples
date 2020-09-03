/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Burglar example from section 7.1.1.

*/
data knapsack_data;
   input values weights;
   datalines;
15 2
100 20
90 20
60 30
40 40
15 30
10 60
1 10
;

proc optmodel;
   /* Declare and read the input data. */
   set ITEMS;
   num values{ITEMS};
   num weights{ITEMS};
   read data knapsack_data into ITEMS=[_N_] values weights;
   num capacity = 102;

   /* Declare variables, a 1 means the burglar puts the item into his knapsack. */
   var X{ITEMS} binary;

   /* The objective is to maximize the total value of the items selected. */
   max Gain = sum {item in ITEMS} values[item]*X[item];

   /* State the knapsack constraint */
   con Knapsack:
      sum {item in ITEMS} weights[item]*X[item] <= capacity;

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Show the generated problem. */
   expand;

   /* Output the solution. */
   print Gain X;
quit;
