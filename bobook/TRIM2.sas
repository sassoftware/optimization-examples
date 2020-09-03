/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Solution to Exercise 4.2 in Chapter 4

*/
data loss_data;
   input pattern $9. loss;
   datalines;
pattern01 10
pattern02 2
pattern03 0
pattern04 6
pattern05 4
pattern06 2
pattern07 10
pattern08 8
pattern09 6
pattern10 4
;

data pattern_data;
   input width $4. pattern01-pattern10 demand;
   datalines;
12cm 5 4 4 2 2 2 0 0 0 0 10
20cm 0 1 0 2 1 0 3 2 1 0 13
22cm 0 0 1 0 1 2 0 1 2 3 8
;

proc optmodel;
   /* Define problem data. */
   set <str> WIDTHS;
   num demand{WIDTHS};
   set <str> PATTERNS;
   num loss{PATTERNS};
   num width_from_pattern{WIDTHS, PATTERNS};

   /* Read problem data. */
   read data loss_data into PATTERNS=[pattern] loss;
   read data pattern_data into WIDTHS=[width] {p in PATTERNS} <width_from_pattern[width,p] = col(p)> demand;

   /* Declare variables. */
   var RollsCut{PATTERNS} >= 0 integer;

   /* State the two objectives mentioned. */ 
   min Waste = sum{p in PATTERNS} loss[p] * RollsCut[p];
   min RollsUsed = sum{p in PATTERNS} RollsCut[p];

   /* State the constraints. */
   con Satisfy_demand {w in WIDTHS}: sum{p in PATTERNS} width_from_pattern[w,p] * RollsCut[p] >= demand[w];
 
   /* Solve the optimization problem. The solver is chosen automatically. First use the Waste objective. */
   solve objective Waste;

   /* Print the values of the variables in the optimal solution. */
   print RollsCut;

   /* Solve the optimization problem. The solver is chosen automatically. Now use the RollsUsed objective. */
   solve objective RollsUsed;

   /* Print the values of the variables in the optimal solution. */
   print RollsCut;
quit;
