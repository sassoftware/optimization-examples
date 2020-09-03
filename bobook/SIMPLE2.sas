/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 2.3 in Chapter 2

*/
proc optmodel;
   /* Declare variables. */
   var X{1..4} >= 0;

   /* State objective. It is named Profit. */
   max Profit = 15*X[1] + 6*X[2] + 9*X[3] + 2*X[4];

   /* State constraints. They are named Con1-3. */
   con Con1: 10*x[1] + 5*x[2] + 25*X[3] + 3*X[4] <= 100;
   con Con2: 12*x[1] + 4*x[2] + 12*X[3] +   X[4] <=  96;
   con Con3:  7*x[1]                    +   X[4] <=  70;
 
   /* Solve the optimization problem. The solver is chosen automatically. */
   solve;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print X;
quit;

/* For b), modify the coefficient of X[5] in Con3. */
proc optmodel;
   /* Coefficient for x[5] in the third constraint. */
   num coef = 1000;

   /* Declare variables. */
   var X{1..5} >= 0;

   /* State objective. It is named Profit. */
   max Profit = 15*X[1] + 6*X[2] + 9*X[3] + 2*X[4] + 10*X[5];

   /* State constraints. They are named Con1-3.*/
   con Con1: 10*x[1] + 5*x[2] + 25*X[3] + 3*X[4] + 4*X[5] <= 100;
   con Con2: 12*x[1] + 4*x[2] + 12*X[3] +   X[4] + 1*X[5] <=  96;
   con Con3:  7*x[1]                    +   X[4] + coef*X[5] <=  70;
 
   /* Solve the optimization problem. The solver is chosen automatically. */
   solve;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print X;
quit;
