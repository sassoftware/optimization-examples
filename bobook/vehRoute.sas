/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Heating Oil Delivery Vehicle Routing (section 7.2.3).

*/

data distance_data;
   input site to1 to2 to3 to4 to5 to6 to7;
   datalines;
1 0 148 55 32 70 140 73
2 148 0 93 180 99 12 72
3 55 93 0 85 20 83 28
4 32 180 85 0 100 174 99
5 70 99 20 100 0 85 49
6 140 12 83 174 85 0 73
7 73 72 28 99 49 73 0
run;

proc optmodel;
   /* Declare input data. */
   set SITES = {1..7};
   set CLIENTS = SITES diff {1};
   num demand{SITES} = [0 14000 3000 6000 16000 15000 5000];
   num distance{SITES, SITES};
   num capacity = 39000;

   /* Read distance data. */
   read data distance_data into [site] {dest in SITES} <distance[site,dest] = col("to" || dest)>;

   /* Declare set of pairs. */
   set PAIRS = {i in SITES, j in SITES: i ne j};

   /* Declare variables. */
   var Proceed{PAIRS} binary;
   var Delivered{client in CLIENTS} >= demand[client] <= capacity;

   /* Declare the objective. */
   min TotalDistance = sum {<i,j> in PAIRS} distance[i,j] * Proceed[i,j];

   /* Ech client once constraints. */
   con EachOnceOne {j in CLIENTS}:
      sum {i in SITES: i ne j} Proceed[i,j] = 1;
   con EachOnceTwo {i in CLIENTS}:
      sum {j in SITES: i ne j} Proceed[i,j] = 1;

   /* First in tour constraint. */
   con FirstInTour {client in CLIENTS}:
      Delivered[client] <= capacity + (demand[client] - capacity) * Proceed[1,client];

   /* Delivered relationship constraint. */
   con DeliveredRel {i in CLIENTS, j in CLIENTS: i ne j}:
      Delivered[j] >= Delivered[i] + demand[j] - capacity + capacity * Proceed[i,j] + (capacity - demand[j] - demand[i]) * Proceed[j,i];

   /* Solve the problem. */
   solve;

   /* Print solution. */
   print {<i,j> in PAIRS: Proceed[i,j].sol > 0.5} Proceed;
quit;
