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
   solve;

   /* Add the first target constraint with a relative target. */
   num Obj1sol;
   Obj1sol = Obj1.sol;
   con Obj1Con: Obj1 >= Obj1sol - abs(10/100 * Obj1sol);

   /* Declare the second objective. */
   min Obj2 = -3*X + 15*Y - 48;

   /* Solve with the second objective.
      Note that we don't need to specify the objective since the last 
      objective declared is used by default. We still do it for emphasis.*/
   solve obj Obj2;

   /* Add the second target constraint with an absolute target. */
   num Obj2sol;
   Obj2sol = Obj2.sol;
   con Obj2Con: Obj2 <= Obj2sol + 4;

   /* Declare the third objective. */
   max Obj3 = 1.5*X + 21*Y - 3.8;

   /* Solve with the third objective. 
      Note that the same holds here, i.e. we specify the Obj3 for emphasis.*/
   solve obj Obj3;

   /* Print out the solution and the three objective values for this solution. */
   print X Y Obj1 Obj2 Obj3;
quit;
