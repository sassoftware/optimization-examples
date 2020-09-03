/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 3.1 in Chapter 3 (Section 3.7).

This is the second part, stating the dual problem.

*/

proc optmodel;
   /* Declare variables. */
   var Y{1..2} >= 0;

   /* State the objective. */
   min DualObjective = 20*Y[1] + 30*Y[2];

   /* State the constraints. */
   con DualCon1: 2*Y[1] +   Y[2] >= 2;
   con DualCon2: Y[1]   + 2*Y[2] >= 3;
   con DualCon3: Y[1]            >= 1;

   /* Solve the optimization problem. The solver is chosen automatically.*/
   solve;

   /* Print the optimization problem.*/
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Y;
quit;
