/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 4.3 in Chapter 4

*/
data node_data;
   input node supply_demand;
   datalines;
1 10
2 10
3 0
4 0
5 0
6 0
7 0
8 -5
9 -10
10 -5
;

data arc_data;
   input from to cost;
   datalines;
1 3 2
1 4 2
2 4 3
2 5 5
3 8 5
3 4 2
4 7 2
4 5 4
5 10 3
6 3 3
6 8 5
6 9 2
7 6 3
7 9 2
7 10 5
;

proc optmodel;
   /* Declare input data. */
   set NODES;
   num supply_demand{NODES};
   set <num, num> ARCS;
   num cost{ARCS};

   /* Read the input data. */
   read data node_data into NODES=[node] supply_demand;
   read data arc_data into ARCS=[from to] cost;

   /* Declare variables. */
   var Flow{ARCS} >= 0;

   /* State objective. */
   min Objective = sum {<i,j> in ARCS} cost[i,j] * Flow[i,j];

   /* State constraints. */
   con Balance {i in NODES}:
      sum {<(i),j> in ARCS} Flow[i,j] - sum {<j,(i)> in ARCS} Flow[j,i] = supply_demand[i];
 
   /* Solve the optimization problem. We choose the network simplex algorithm. */
   solve with lp / algorithm=ns;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Flow;
quit;
