/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 3.1 in Chapter 3 (Section 3.7).

This is the first part, stating the primal problem.

*/

proc optmodel;
   /* Declare variables. */
   var X{1..3} >= 0;

   /* State the objective. */
   max Objective = 2*X[1] + 3*X[2] + X[3];

   /* State the constraints. */
   con Con1: 2*X[1] +   X[2] + X[3] <= 20;
   con Con2:   X[1] + 2*X[2]        <= 30;

   /* Solve the optimization problem. The solver is chosen automatically.*/
   solve;

   /* Print the optimization problem.*/
   expand;

   /* Print the values of the variables in the optimal solution. */
   print X;
quit;
