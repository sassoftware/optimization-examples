/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 7.5.

*/
/* Table from the book, transposed for easier reading. */
data investment_data;
   input cost yield;
   datalines;
5 16
7 22
4 12
3 8
;

proc optmodel;
   /* Declare and read input data. */
   set INVESTMENTS;
   num cost{INVESTMENTS};
   num yield{INVESTMENTS};
   num budget = 14;
   read data investment_data into INVESTMENTS=[_N_] cost yield;

   /* Declare variables. */
   var Invest{INVESTMENTS} binary;

   /* Declare the objective function. */
   max TotalYield = sum {investment in INVESTMENTS} yield[investment] * Invest[investment];

   /* Budget constraint. */
   con BudgetConstraint:
      sum {investment in INVESTMENTS} cost[investment] * Invest[investment] <= budget;

   /* Solve the problem. */
   solve;

   /* Print the optimal solution. */
   print Invest;
quit;
