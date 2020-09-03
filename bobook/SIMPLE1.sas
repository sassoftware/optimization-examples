/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 2.2 in Chapter 2

*/
proc optmodel;
   /* Declare variables. */
   var W >= 0;
   var X >= 0;
   var Y >= 0;
   var Z >= 0;

   /* State objective. It is named Profit. */
   max Profit = 4*W + 3*X + 2*Y + 5*Z;

   /* State constraints. They are named Con1-3. */
   con Con1: 2*W +   X + 2*Y +   Z <= 500;
   con Con2: 2*W + 3*X +     + 2*Z <= 460;
   con Con3:         X + 4*Y       <= 420;

   /* For c) uncomment this constraint. */
   *con Con4:   W + 2*X +   Y +   Z <= 340;

   /* For d) uncomment this constraint and comment out Con2. */
   *con Con2d: 1.5*W + 2*X +   + 2*Z <= 460;

 
   /* Solve the optimization problem. The solver is chosen automatically.*/
   solve;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print W X Y Z;
quit;
