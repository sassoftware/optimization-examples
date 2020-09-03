/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Fractional programming (section 11.2).

*/
proc optmodel;
   /* Declare the variables. */
   var Y1 >= 0;
   var Y2 >= 0;
   var W >= 0;

   /* Declare implied variables for the original variables. */
   impvar X1 = Y1 / W;
   impvar X2 = Y2 / W;

   /* Declare the objective. */
   min Z = Y1 + W;
   con Y1 + Y2 - W <= 0,
       Y2 + 2*W = 1;

   /* Solve with the default LP solver (dual simplex). */
   solve;

   /* Print the solution. */
   print Y1 Y2 W X1 X2;
quit;
