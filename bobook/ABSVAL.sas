/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Modeling Absolute Value Terms example (section 6.5).

*/
proc optmodel;
   /* Declare the variables. */
   var X1 >= 0 <= 3;
   var X2 >= 0 <= 4;
   var APlus;
   var AMinus;
   var delta binary;

   /* Compute be bound (A in the book). */
   num bound = max(abs(1) * X1.ub, abs(-2) * X2.ub);

   /* Declare the objective. */
   max Z = APlus + AMinus;

   /* Declare the constraints. */
   con Con1: X1 - 2*X2 = APlus - AMinus;
   con Con2: APlus <= bound * delta;
   con Con3: AMinus <= bound * (1 - delta);

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Print the created problem. */
   expand;

   /* Print out the results. */
   print bound Z X1 X2 delta APlus AMinus;
quit;
