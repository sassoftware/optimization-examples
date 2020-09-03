/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 4.1 in Chapter 4

*/
proc optmodel;
   /* Declare variables. */
   var Pattern{1..6} >= 0;
   var Surplus{1..3} >= 0;

   /* State objective. It is named TotalWaste. */
   min TotalWaste = 3*Pattern[2] + Pattern[3] + Pattern[4] + 4*Pattern[5] + 2*Pattern[6] + 5*Surplus[1] + 7*Surplus[2] + 9*Surplus[3];

   /* State constraints. They are named Con1-3. */
   con Con1: 4*Pattern[1] + 2*Pattern[2] + 2*Pattern[3] + Pattern[4] = 30000 + Surplus[1];
   con Con2: Pattern[2] + 2*Pattern[4] + Pattern[5] = 30000 + Surplus[2];
   con Con3: Pattern[3] + Pattern[5] + 2*Pattern[6] = 20000 + Surplus[3];
 
   /* Solve the optimization problem. The solver is chosen automatically. */
   solve;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Pattern Surplus;
quit;
