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
/*    NAME: mpex19                                             */
/*   TITLE: Distribution 1 (mpex19)                            */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 19 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/


data arc_data;
   input j $11. i $11. cost;
   datalines;
Newcastle  Liverpool  0.5
Birmingham Liverpool  0.5
Birmingham Brighton   0.3
London     Liverpool  1.0
London     Brighton   0.5
Exeter     Liverpool  0.2
Exeter     Brighton   0.2
C1         Liverpool  1.0
C1         Brighton   2.0
C1         Birmingham 1.0
C2         Newcastle  1.5
C2         Birmingham 0.5
C2         London     1.5
C3         Liverpool  1.5
C3         Newcastle  0.5
C3         Birmingham 0.5
C3         London     2.0
C3         Exeter     0.2
C4         Liverpool  2.0
C4         Newcastle  1.5
C4         Birmingham 1.0
C4         Exeter     1.5
C5         Birmingham 0.5
C5         London     0.5
C5         Exeter     0.5
C6         Liverpool  1.0
C6         Newcastle  1.0
C6         London     1.5
C6         Exeter     1.5
;

data customer_data;
   input customer $ demand;
   datalines;
C1 50000
C2 10000
C3 40000
C4 35000
C5 60000
C6 20000
;

data factory_data;
   input factory $10. capacity;
   datalines;
Liverpool 150000
Brighton  200000
;

data depot_data;
   input depot $11. throughput;
   datalines;
Newcastle   70000
Birmingham  50000
London     100000
Exeter      40000
;

data preferred_arc_data;
   input j $ i $11.;
   datalines;
C1 Liverpool
C2 Newcastle
C5 Birmingham
C6 Exeter
C6 London
;



proc optmodel;
   set <str,str> ARCS;
   num cost {ARCS};
   read data arc_data into ARCS=[i j] cost;

   set <str> FACTORIES;
   num capacity {FACTORIES};
   read data factory_data into FACTORIES=[factory] capacity;

   set <str> DEPOTS;
   num throughput {DEPOTS};
   read data depot_data into DEPOTS=[depot] throughput;

   set <str> CUSTOMERS;
   num demand {CUSTOMERS};
   read data customer_data into CUSTOMERS=[customer] demand;



   set NODES = FACTORIES union DEPOTS union CUSTOMERS;
   num supply {NODES} init 0;
   for {i in FACTORIES} supply[i] = capacity[i];
   for {i in CUSTOMERS} supply[i] = -demand[i];



   var Flow {ARCS} >= 0;

   con Flow_balance_con {i in NODES}:
      sum {<(i),j> in ARCS} Flow[i,j] - sum {<j,(i)> in ARCS} Flow[j,i]
   <= supply[i];

   con Depot_con {i in DEPOTS}:
      sum {<(i),j> in ARCS} Flow[i,j] <= throughput[i];

   min TotalCost = sum {<i,j> in ARCS} cost[i,j] * Flow[i,j];



   put 'Minimizing TotalCost...';
   solve;
   print {<i,j> in ARCS: Flow[i,j].sol > 0} Flow;
   print Flow_balance_con.body Flow_balance_con.ub Flow_balance_con.dual;
   print Depot_con.body Depot_con.ub Depot_con.dual;



   put 'Minimizing TotalCost by using network simplex...';
   solve with LP / algorithm=ns;
   print {<i,j> in ARCS: Flow[i,j].sol > 0} Flow;
   print Flow_balance_con.body Flow_balance_con.ub Flow_balance_con.dual;
   print Depot_con.body Depot_con.ub Depot_con.dual;



   set <str,str> PREFERRED_ARCS;
   read data preferred_arc_data into PREFERRED_ARCS=[i j];
   set CUSTOMERS_WITH_PREFERENCES = setof {<i,j> in PREFERRED_ARCS} j;
   min NonpreferredFlow =
      sum {<i,j> in ARCS diff PREFERRED_ARCS: j in CUSTOMERS_WITH_PREFERENCES}
         Flow[i,j];

   put 'Minimizing NonpreferredFlow...';
   solve;
   print TotalCost NonpreferredFlow;
   print {<i,j> in ARCS: Flow[i,j].sol > 0} Flow;
   print
      {<i,j> in ARCS diff PREFERRED_ARCS: j in CUSTOMERS_WITH_PREFERENCES}
         Flow;



   con Objective_cut:
      NonpreferredFlow <= NonpreferredFlow.sol;



   put 'Minimizing TotalCost with constrained NonpreferredFlow...';
   solve obj TotalCost;
   print TotalCost NonpreferredFlow;
   print {<i,j> in ARCS: Flow[i,j].sol > 0} Flow;
   print
      {<i,j> in ARCS diff PREFERRED_ARCS: j in CUSTOMERS_WITH_PREFERENCES}
         Flow;
quit;
