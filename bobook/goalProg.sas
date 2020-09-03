/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Goal programming example (section 5.4.3).

*/
proc optmodel;
   /* Declare the variables with their bounds. */
   var X >= 0;
   var Y >= 0;

   /* Declare the constraint. */
   con con1: 42*X + 13*Y <= 100;

   /* Declare the first objective. */
   max Obj1 = 5*X + 2*Y - 20;

   /* Solve with the first objective. */
   solve obj Obj1;

   /* Add the first target constraint with a relative target. */
   con Obj1Con: 5*X + 2*Y - 20 >= Obj1.sol - abs(10/100 * Obj1.sol);

   /* Declare the second objective. */
   min Obj2 = -3*X + 15*Y - 48;

   /* Solve with the second objective. */
   solve obj Obj2;

   /* Add the second target constraint with an absolute target. */
   con Obj2Con: -3*X + 15*Y - 48 <= Obj2.sol + 4;

   /* Declare the third objective. */
   max Obj3 = 1.5*X + 21*Y - 3.8;

   /* Solve with the third objective. */
   solve obj Obj3;

   /* Print out the solution and the three objective values for this solution. */
   print X Y Obj1 Obj2 Obj3;
quit;
