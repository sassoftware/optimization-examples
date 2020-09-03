/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 3.3 in Chapter 3 (Section 3.7).

*/
/* First state the primal problem. */
proc optmodel;
   /* Declare variables. We do not include the
      upper bound here to show the relationship
      between the primal and the dual more clearly*/
   var Premium >= 0;
   var Standard >= 0;

   /* State the objective. */
   max Profit = 800*Premium + 600*Standard;

   /* State the constraints. */
   con Max_num_boats: Premium + Standard <= 350;
   con Upper_bound: Premium <= 200;
   con No_fewer_premium: Premium >= Standard;
   con Maintenance: 4*Premium + 3*Standard <= 1400;

   /* Solve the optimization problem. The solver is chosen automatically.*/
   solve;

   /* Print the optimization problem.*/
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Premium Standard;
quit;

/* Now state the dual problem. */
proc optmodel;
   /* Declare variables. */
   var Y{1..4} >= 0;

   /* State the objective. */
   min Dual_obj = 350*Y[1] + 200*Y[2] + 1400*Y[4];

   /* State the constraints. */
   con Dual_con1: Y[1] + Y[2] - Y[3] + 4*Y[4] >= 800;
   con Dual_con2: Y[1]        + Y[3] + 3*Y[4] >= 600;

   /* Solve the optimization problem. The solver is chosen automatically.*/
   solve;

   /* Print the optimization problem.*/
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Y;
quit;
