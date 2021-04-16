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
/*    NAME: mpex20                                             */
/*   TITLE: Depot Location (Distribution 2) (mpex20)           */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 20 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data arc_data;
   input j $12. i $12. cost;
   datalines;
Newcastle   Liverpool   0.5
Birmingham  Liverpool   0.5
Birmingham  Brighton    0.3
London      Liverpool   1.0
London      Brighton    0.5
Exeter      Liverpool   0.2
Exeter      Brighton    0.2
C1          Liverpool   1.0
C1          Brighton    2.0
C1          Birmingham  1.0
C2          Newcastle   1.5
C2          Birmingham  0.5
C2          London      1.5
C3          Liverpool   1.5
C3          Newcastle   0.5
C3          Birmingham  0.5
C3          London      2.0
C3          Exeter      0.2
C4          Liverpool   2.0
C4          Newcastle   1.5
C4          Birmingham  1.0
C4          Exeter      1.5
C5          Birmingham  0.5
C5          London      0.5
C5          Exeter      0.5
C6          Liverpool   1.0
C6          Newcastle   1.0
C6          London      1.5
C6          Exeter      1.5
Bristol     Liverpool   0.6
Bristol     Brighton    0.4
Northampton Liverpool   0.4
Northampton Brighton    0.3
C1          Bristol     1.2
C2          Bristol     0.6
C2          Northampton 0.4
C3          Bristol     0.5
C4          Northampton 0.5
C5          Bristol     0.3
C5          Northampton 0.6
C6          Bristol     0.8
C6          Northampton 0.9
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
   input depot $12. throughput cost savings;
   datalines;
Newcastle    70000     0 10000
Birmingham   50000     0     .
London      100000     0     .
Exeter       40000     0  5000
Bristol      30000 12000     0
Northampton  25000  4000     0
;

data expand_depot_data;
   input depot $12. throughput cost;
   datalines;
Birmingham   20000  3000
;

%let max_num_depots = 4;

proc optmodel;
   set <str,str> ARCS;
   num cost {ARCS};
   read data arc_data into ARCS=[i j] cost;

   set <str> FACTORIES;
   num capacity {FACTORIES};
   read data factory_data into FACTORIES=[factory] capacity;

   set <str> DEPOTS;
   num throughput {DEPOTS};
   num open_cost {DEPOTS};
   num close_savings {DEPOTS};
   read data depot_data into DEPOTS=[depot]
      throughput open_cost=cost close_savings=savings;

   set <str> EXPAND_DEPOTS;
   num expand_throughput {EXPAND_DEPOTS};
   num expand_cost {EXPAND_DEPOTS};
   read data expand_depot_data into EXPAND_DEPOTS=[depot]
      expand_throughput=throughput expand_cost=cost;

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

   var IsOpen {DEPOTS} binary;
   var Expand {EXPAND_DEPOTS} binary;

   con Max_num_depots_con:
      sum {i in DEPOTS} IsOpen[i] <= &max_num_depots;

   con Depot_con {i in DEPOTS}:
      sum {<(i),j> in ARCS} Flow[i,j]
   <= throughput[i] * IsOpen[i]
   + (if i in EXPAND_DEPOTS then expand_throughput[i] * Expand[i]);

   con Expand_con {i in EXPAND_DEPOTS}:
      Expand[i] <= IsOpen[i];

   for {i in DEPOTS: close_savings[i] = .} do;
      close_savings[i] = 0;
      fix IsOpen[i] = 1;
   end;

   impvar FixedCost =
      sum {depot in DEPOTS}
         (open_cost[depot] * IsOpen[depot] -
            close_savings[depot] * (1 - IsOpen[depot]))
    + sum {depot in EXPAND_DEPOTS} expand_cost[depot] * Expand[depot];
   impvar VariableCost = sum {<i,j> in ARCS} cost[i,j] * Flow[i,j];
   min TotalCost = FixedCost + VariableCost;

   solve;
   print FixedCost VariableCost TotalCost;
   print {<i,j> in ARCS: Flow[i,j].sol > 0} Flow;
   print IsOpen Expand;
quit;
