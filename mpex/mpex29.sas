/* Copyright © 2021, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples

A description of the examples is available at:
https://go.documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/ormpex/titlepage.htm
*/
/***************************************************************/
/*                                                             */
/*          S A S   S A M P L E   L I B R A R Y                */
/*                                                             */
/*    NAME: mpex29                                             */
/*   TITLE: Protein Comparison (mpex29)                        */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*    KEYS: OR                                                 */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 29 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/



data edge_data1;
   input i j;
   datalines;
1 2
2 9
3 4
3 5
5 6
6 7
7 9
8 9
;

data edge_data2;
   input i j;
   datalines;
1 4
2 3
4 6
4 7
5 6
6 8
7 8
7 10
9 10
10 11
;


proc optmodel;
   set <num,num> EDGES {1..2};
   read data edge_data1 into EDGES[1]=[i j];
   read data edge_data2 into EDGES[2]=[i j];


   set NODES {g in 1..2} init union {<i,j> in EDGES[g]} {i,j};
   for {g in 1..2} NODES[g] = 1..card(NODES[g]) inter NODES[g];


   set IJ = NODES[1] cross NODES[2];
   set EDGE_PAIRS = {<i,j> in IJ, <k,l> in IJ: i < k and j ne l and
      (<i,k> in EDGES[1]) and (<j,l> in EDGES[2])};


   /* Assign[i,j] = 1 if node i in NODES[1] assigned to node j in NODES[2] */
   var Assign {IJ} binary;

   /* IsCorrespondingEdge[i,j,k,l] = 1 if edge <i,k> in EDGES[1]
      corresponds to edge <j,l> in EDGES[2] */
   var IsCorrespondingEdge {EDGE_PAIRS} binary;

   /* maximize number of corresponding edges */
   max NumCorrespondingEdges =
      sum {<i,j,k,l> in EDGE_PAIRS} IsCorrespondingEdge[i,j,k,l];

   /* assign each i to at most one j */
   con Assign_i {i in NODES[1]}:
      sum {<(i),j> in IJ} Assign[i,j] <= 1;

   /* assign at most one i to each j */
   con Assign_j {j in NODES[2]}:
      sum {<i,(j)> in IJ} Assign[i,j] <= 1;

   /* disallow crossing edges */
   con NoCrossover {<i,j> in IJ, <k,l> in IJ: i < k and j > l}:
      Assign[i,j] + Assign[k,l] <= 1;

   /* if IsCorrespondingEdge[i,j,k,l] = 1 then Assign[i,j] = Assign[k,l] = 1 */
   con Corresponding1 {<i,j,k,l> in EDGE_PAIRS}:
      IsCorrespondingEdge[i,j,k,l] <= Assign[i,j];
   con Corresponding2 {<i,j,k,l> in EDGE_PAIRS}:
      IsCorrespondingEdge[i,j,k,l] <= Assign[k,l];


   solve;
   file print;
   for {<i,j> in IJ: Assign[i,j].sol > 0.5}
      put ('Node '||i||' in graph 1 corresponds to node '||j||' in graph 2.');
   for {<i,j,k,l> in EDGE_PAIRS: IsCorrespondingEdge[i,j,k,l].sol > 0.5} do;
      put ('Edge ('||i||','||k||') in graph 1 corresponds to') @@;
      put ('edge ('||j||','||l||') in graph 2.');
   end;
quit;
