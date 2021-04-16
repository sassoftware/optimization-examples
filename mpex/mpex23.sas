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
/*    NAME: mpex23                                             */
/*   TITLE: Milk Collection (mpex23)                           */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL, SGPLOT, TEMPLATE                         */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 23 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/


data farm_data;
   farm = _N_;
   input east north frequency requirement;
   datalines;
 0  0 2 0
-3  3 2 5
 1 11 2 4
 4  7 2 3
-5  9 2 6
-5 -2 2 7
-4 -7 2 3
 6  0 2 4
 3 -6 2 6
-1 -3 2 5
 0 -6 1 4
 6  4 1 7
 2  5 1 3
-2  8 1 4
 6 10 1 5
 1  8 1 6
-3  1 1 8
-6  5 1 5
 2  9 1 7
-6 -5 1 6
 5 -4 1 6
;

%let distance_scale = 10;
%let num_days = 2;
%let capacity = 80;
%let depot = 1;

proc template;
   Define style styles.mystyle;
   Parent=styles.default;
   Style graphdata1 from graphdata1 / MarkerSymbol="plus";
   Style graphdata2 from graphdata2 / MarkerSymbol="asterisk";
   end;
run;

ods listing style=mystyle;
proc sgplot data=farm_data;
   scatter y=north x=east / group=frequency datalabel=farm;
   xaxis display=(nolabel);
   yaxis display=(nolabel);
run;


proc optmodel;
   set NODES;
   num east {NODES};
   num north {NODES};
   num frequency {NODES};
   num requirement {NODES};
   read data farm_data into NODES=[_N_] east north frequency requirement;

   set EDGES = {i in NODES, j in NODES: i < j};
   num distance {<i,j> in EDGES} =
      &distance_scale * sqrt((east[i]-east[j])^2+(north[i]-north[j])^2);

   set DAYS = 1..&num_days;

   var UseNode {NODES, DAYS} binary;
   var UseEdge {EDGES, DAYS} binary;

   min TotalDistance
      = sum {<i,j> in EDGES, d in DAYS} distance[i,j] * UseEdge[i,j,d];

   con Capacity_con {d in DAYS}:
      sum {i in NODES} requirement[i] * UseNode[i,d] <= &capacity;

   con Frequency_con {i in NODES}:
      sum {d in DAYS} UseNode[i,d] = frequency[i];

   con Two_match {k in NODES, d in DAYS}:
      sum {<i,j> in EDGES: k in {i,j}} UseEdge[i,j,d] = 2 * UseNode[k,d];

   /* several alternatives for symmetry-breaking constraints */
*  con Symmetry {d in DAYS diff {1}}:
      sum {<i,j> in EDGES} distance[i,j] * UseEdge[i,j,d]
   <= sum {<i,j> in EDGES} distance[i,j] * UseEdge[i,j,d-1];
*  con Symmetry {d in DAYS diff {1}}:
      sum {i in NODES} requirement[i] * UseNode[i,d]
   <= sum {i in NODES} requirement[i] * UseNode[i,d-1];
   con Symmetry {d in DAYS diff {1}}:
      sum {i in NODES} UseNode[i,d]
   <= sum {i in NODES} UseNode[i,d-1];

   num num_subtours init 0;
   /* subset of nodes not containing depot node */
   set SUBTOUR {1..num_subtours};
   /* if node k in SUBTOUR[s] is used on day d, then
      must use at least two edges across partition induced by SUBTOUR[s] */
   con Subtour_elimination {s in 1..num_subtours, k in SUBTOUR[s], d in DAYS}:
      sum {i in NODES diff SUBTOUR[s], j in SUBTOUR[s]: <i,j> in EDGES}
         UseEdge[i,j,d]
    + sum {i in SUBTOUR[s], j in NODES diff SUBTOUR[s]: <i,j> in EDGES}
         UseEdge[i,j,d]
   >= 2 * UseNode[k,d];

   num iter init 0;
   num num_iters init 0;
   set ITERS = 1..num_iters;
   num num_components {DAYS};
   set NODES_TEMP;
   set <num,num> EDGES_SOL {ITERS, DAYS};
   num component_id {NODES_TEMP};
   set COMPONENT_IDS;
   set COMPONENT {COMPONENT_IDS};
   num ci;
   num cj;

   /* loop until each day's support graph is connected */
   do until (and {d in DAYS} num_components[d] = 1);
      iter = iter + 1;
      num_iters = iter;
      solve;
      /* find connected components for each day */
      for {d in DAYS} do;
         NODES_TEMP = {i in NODES: UseNode[i,d].sol > 0.5};
         EDGES_SOL[iter,d] = {<i,j> in EDGES: UseEdge[i,j,d].sol > 0.5};
         /* initialize each node to its own component */
         COMPONENT_IDS = NODES_TEMP;
         num_components[d] = card(NODES_TEMP);
         for {i in NODES_TEMP} do;
            component_id[i] = i;
            COMPONENT[i] = {i};
         end;
         /* if i and j are in different components, merge the two components */
         for {<i,j> in EDGES_SOL[iter,d]} do;
            ci = component_id[i];
            cj = component_id[j];
            if ci ne cj then do;
               /* update smaller component */
               if card(COMPONENT[ci]) < card(COMPONENT[cj]) then do;
                  for {k in COMPONENT[ci]} component_id[k] = cj;
                  COMPONENT[cj] = COMPONENT[cj] union COMPONENT[ci];
                  COMPONENT_IDS = COMPONENT_IDS diff {ci};
               end;
               else do;
                  for {k in COMPONENT[cj]} component_id[k] = ci;
                  COMPONENT[ci] = COMPONENT[ci] union COMPONENT[cj];
                  COMPONENT_IDS = COMPONENT_IDS diff {cj};
               end;
            end;
         end;
         num_components[d] = card(COMPONENT_IDS);
         put num_components[d]=;
         /* create subtour from each component not containing depot node */
         for {k in COMPONENT_IDS: &depot not in COMPONENT[k]} do;
            num_subtours = num_subtours + 1;
            SUBTOUR[num_subtours] = COMPONENT[k];
            put SUBTOUR[num_subtours]=;
         end;
      end;
      print capacity_con.body capacity_con.ub;
      print num_components;
   end;

   create data sol_data from
      [iter d i j]={it in ITERS, d in DAYS, <i,j> in EDGES_SOL[it,d]}
      x1=east[i] y1=north[i] x2=east[j] y2=north[j];
   call symput('num_iters',put(num_iters,best.));
quit;

%macro showPlots;
   %do iter = 1 %to &num_iters;
      %do d = 1 %to &num_days;
         /* create annotate data set to draw subtours */
         data sganno(keep=drawspace linethickness function x1 y1 x2 y2);
            retain drawspace "datavalue" linethickness 1;
            set sol_data;
            where iter = &iter and d = &d;
            function = 'line';
         run;

         title1 "iter = &iter, day = &d";
         title2;
         proc sgplot data=farm_data sganno=sganno;
            scatter y=north x=east / group=frequency datalabel=farm;
            xaxis display=(nolabel);
            yaxis display=(nolabel);
         run;
      %end;
   %end;
%mend showPlots;
%showPlots;
