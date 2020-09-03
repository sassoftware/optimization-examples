/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Calves and pigs problem, section 2.6.1 and 3.3.1.

*/
proc optmodel;
   /* Set the budget */
   num budget = 3.5;

   /* Declare variables and set lower and upper bounds. */
   var Calves >= 0 <= 2 integer;
   var Pigs >= 0 <= 2 integer;

   /* State objective. It is named profit. */
   max Profit = 3*Calves + 2*Pigs;

   /* State the budget constraint. */
   con Con1: Calves + Pigs <= budget;
 
   /* Solve the optimization problem. The solver is chosen automatically. */
   solve;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Calves Pigs;
quit;
