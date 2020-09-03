/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Bus crew scheduling, section 7.8.4.

*/
/* The shift data from the book. Transposed for easier reading. */
data shift_data;
   input shift cost;
   datalines;
6 100
7 90
8 80
9 50
14 60
15 70
16 80
17 100
;

/* The demand data from the book. Transposed for easier reading. */
data demand_data;
   input time demand;
   datalines;
6 3
7 9
8 10
10 6
12 7
14 6
16 8
17 10
19 8
20 3
23 2
24 2
;

proc optmodel;
   /* Declare the input data. */
   set HOURS = {6..24};

   /* Fill in only the demand that is given in the table, assume other demand to be 0. */
   num demand{HOURS} init 0;
   read data demand_data into [time] demand[time] = demand;

   /* Shifts have to be 8 hours, so they can start after 16. */
   set SHIFTS;
   num cost{SHIFTS};
   read data shift_data into SHIFTS=[shift] cost;

   /* Add the first indication table from the book (W_h). */
   num shift_length = 8;
   num indication_table{1..shift_length} = [1 1 1 0 1 1 1 1];

   /* Declare variables. */
   var NumShifts{SHIFTS} >= 0 integer;

   /* Declare objective. */
   min TotalCost = sum {shift in SHIFTS} cost[shift] * NumShifts[shift];

   /* Declare the constraints. */
   con CoverDemand{hour in HOURS}:
      sum {shift in SHIFTS: hour >= shift && hour < shift + shift_length} indication_table[hour - shift + 1] * NumShifts[shift] >= demand[hour];

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Print out the solution. */
   print NumShifts;
quit;
