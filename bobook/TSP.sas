/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Traveling salesman example, exercise 7.1.

*/

/* Distance data in sparse, lower triangular format from the book. */
data distance_data;
   input from to distance;
   datalines;
1 2 185
1 3 270
1 4 315
1 5 124
1 6 123
1 7 99
1 8 180
2 3 215
2 4 219
2 5 187
2 6 154
2 7 210
2 8 190
3 4 210
3 5 220
3 6 238
3 7 198
3 8 150
4 5 218
4 6 134
4 7 157
4 8 149
5 6 168
5 7 143
5 8 129
6 7 198
6 8 201
7 8 180
;

proc optmodel;
   /* Declare the input data. */
   set VERTICES = {1..8};
   num distance{VERTICES, VERTICES} init .;
   read data distance_data into [from to] distance;
   for {i in VERTICES, j in VERTICES} do;
      if i = j then distance[i,j] = 0;
      else if distance[i,j] = . then distance[i,j] = distance[j,i];
   end;
   print distance;

   /* Declare the variables. */
   var Use{VERTICES, VERTICES} binary;
   var Subtour{i in VERTICES: i > 1} >= 0;

   /* Declare the objective function. */
   min TotalDistance = sum {i in VERTICES, j in VERTICES: i ne j} distance[i,j] * Use[i,j];

   /* The enter once constraints. */
   con EnterOnce{j in VERTICES}:
      sum {i in VERTICES: i ne j} Use[i,j] = 1;

   /* The leave once constraints. */
   con LeaveOnce{i in VERTICES}:
      sum {j in VERTICES: i ne j} Use[i,j] = 1;

   /* Subtour elimination constraints. */
   con SubtourElimination{i in VERTICES, j in VERTICES: i > 1 && j > 1 && i ne j}:
      Subtour[i] - Subtour[j] + (card(VERTICES) - 1)*Use[i,j] <= card(VERTICES) - 2;

   /* Solve the problem, the MILP solver is selected automatically. */
   solve;

   /* Print the optimal solution. */
   print Subtour;
   print {i in VERTICES, j in VERTICES: Use[i,j].sol > 0.5} Use;
quit;

/* 
This is an alternative, SAS-specific, way to solve this problem using the SAS built-in TSP solver.
*/
proc optmodel;
   /* Declare the input data. */
   set <num,num> LINKS;
   num distance{LINKS};
   read data distance_data into LINKS=[from to] distance;
   print distance;

   /* Solve the problem. */
   set <num,num> TOUR;
   solve with network / tsp links=(weight=distance) out=(tour=TOUR);

   /* Print the optimal solution. */
   put TOUR=;
   print {<i,j> in TOUR} distance;
quit;
