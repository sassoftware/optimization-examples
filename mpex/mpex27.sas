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
/*    NAME: mpex27                                             */
/*   TITLE: Lost Baggage Distribution (mpex27)                 */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*    KEYS: OR                                                 */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 27 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data time_data;
   input location $11.
      Heathrow Harrow Ealing Holborn Sutton Dartford Bromley Greenwich
      Barking Hammersmith Kingston Richmond Battersea Islington Woolwich;
   datalines;
Heathrow    0 20 25 35 65 90 85 80 86 25 35 20 44 35 82
Harrow      .  0 15 35 60 55 57 85 90 25 35 30 37 20 40
Ealing      .  .  0 30 50 70 55 50 65 10 25 15 24 20 90
Holborn     .  .  .  0 45 60 53 55 47 12 22 20 12 10 21
Sutton      .  .  .  .  0 46 15 45 75 25 11 19 15 25 25
Dartford    .  .  .  .  .  0 15 15 25 45 65 53 43 63 70
Bromley     .  .  .  .  .  .  0 17 25 41 25 33 27 45 30
Greenwich   .  .  .  .  .  .  .  0 25 40 34 32 20 30 10
Barking     .  .  .  .  .  .  .  .  0 65 70 72 61 45 13
Hammersmith .  .  .  .  .  .  .  .  .  0 20  8  7 15 25
Kingston    .  .  .  .  .  .  .  .  .  .  0  5 12 45 65
Richmond    .  .  .  .  .  .  .  .  .  .  .  0 14 34 56
Battersea   .  .  .  .  .  .  .  .  .  .  .  .  0 30 40
Islington   .  .  .  .  .  .  .  .  .  .  .  .  .  0 27
Woolwich    .  .  .  .  .  .  .  .  .  .  .  .  .  .  0
;

%let num_vehicles = 6;
%let time_limit = 120;
%let depot = Heathrow;

%macro findConnectedComponents;
   if card(ARCS_SOL) > 0 then do;
      solve with NETWORK /
         direction = directed
         links     = (include=ARCS_SOL)
         subgraph  = (nodes=NODES_SOL)
         concomp
         out       = (concomp=component_id);
      COMPONENT_IDS = setof {i in NODES_SOL} component_id[i];
      for {c in COMPONENT_IDS} COMPONENT[c] = {};
      for {i in NODES_SOL} do;
         ci = component_id[i];
         COMPONENT[ci] = COMPONENT[ci] union {i};
      end;
   end;
   else COMPONENT_IDS = {};
%mend findConnectedComponents;

%macro subtourEliminationLoop;
   /* loop until each vehicle's support graph is connected */
   do until (and {v in VEHICLES} num_components[v] <= 1);
      solve;
      /* find connected components for each vehicle */
      for {v in VEHICLES} do;
         NODES_SOL = {i in NODES: UseNode[i,v].sol > 0.5};
         ARCS_SOL = {<i,j> in ARCS: UseArc[i,j,v].sol > 0.5};
         %findConnectedComponents;
         num_components[v] = card(COMPONENT_IDS);
         /* create subtour from each component not containing depot node */
         for {k in COMPONENT_IDS: depot not in COMPONENT[k]} do;
            num_subtours = num_subtours + 1;
            SUBTOUR[num_subtours] = COMPONENT[k];
            put SUBTOUR[num_subtours]=;
         end;
      end;
      print UseVehicle TimeUsed num_components;
   end;
%mend subtourEliminationLoop;

proc optmodel;
   num num_vehicles init &num_vehicles;
   set VEHICLES = 1..num_vehicles;
   str depot = "&depot";
   set <str> NODES;
   read data time_data into NODES=[location];
   set ARCS init NODES cross NODES;
   num travel_time {ARCS};
   read data time_data into [i=location]
      {j in NODES} <travel_time[i,j]=col(j)>;

   for {<i,j> in ARCS: travel_time[i,j] = .}
      travel_time[i,j] = travel_time[j,i];
   /* ignore travel time back to depot */
   for {i in NODES}
      travel_time[i,depot] = 0;
   /* remove self-loops */
   ARCS = ARCS diff setof {i in NODES} <i,i>;
   print travel_time;

   var UseNode {NODES, VEHICLES} binary;
   var UseArc {ARCS, VEHICLES} binary;
   var UseVehicle {VEHICLES} binary;
   var TimeUsed {v in VEHICLES} >= 0 <= &time_limit;

   min NumVehiclesUsed =
      sum {v in VEHICLES} UseVehicle[v];

   con NodeCover {i in NODES diff {depot}}:
      sum {v in VEHICLES} UseNode[i,v] = 1;

   con Outflow {i in NODES, v in VEHICLES}:
      sum {<(i),j> in ARCS} UseArc[i,j,v] = UseNode[i,v];

   con Inflow {j in NODES, v in VEHICLES}:
      sum {<i,(j)> in ARCS} UseArc[i,j,v] = UseNode[j,v];

   con UseVehicle_con1 {i in NODES, v in VEHICLES}:
      UseNode[i,v] <= UseVehicle[v];

   con UseVehicle_con2 {v in VEHICLES}:
      UseVehicle[v] <= UseNode[depot,v];

   con TimeUsed_con {v in VEHICLES}:
      TimeUsed[v] = sum {<i,j> in ARCS} travel_time[i,j] * UseArc[i,j,v];

   /* several alternatives for symmetry-breaking constraints */
   con Symmetry {v in VEHICLES diff {1}}:
      sum {i in NODES} UseNode[i,v] <= sum {i in NODES} UseNode[i,v-1];
*  con Symmetry {v in VEHICLES diff {1}}:
      UseVehicle[v] <= UseVehicle[v-1];
*  con Symmetry {v in VEHICLES diff {1}}:
      TimeUsed[v] <= TimeUsed[v-1];

   num num_subtours init 0;

   /* subset of nodes not containing depot node */
   set <str> SUBTOUR {1..num_subtours};

   /* if node k in SUBTOUR[s] is used by vehicle v, then
      must use at least two arcs across partition induced by SUBTOUR[s] */
   con Subtour_elimination
      {s in 1..num_subtours, k in SUBTOUR[s], v in VEHICLES}:
      sum {i in NODES diff SUBTOUR[s], j in SUBTOUR[s]: <i,j> in ARCS}
         UseArc[i,j,v]
    + sum {i in SUBTOUR[s], j in NODES diff SUBTOUR[s]: <i,j> in ARCS}
         UseArc[i,j,v]
   >= 2 * UseNode[k,v];

   num num_components {VEHICLES};
   set <str> NODES_SOL;
   set <str,str> ARCS_SOL;
   num component_id {NODES_SOL};
   set COMPONENT_IDS;
   set <str> COMPONENT {COMPONENT_IDS};
   num ci;

   %subtourEliminationLoop;
   num_vehicles = round(NumVehiclesUsed.sol);

   var MaxTimeUsed >= 0 <= &time_limit;

   min Makespan = MaxTimeUsed;

   con MaxTimeUsed_con {v in VEHICLES}:
      MaxTimeUsed >= TimeUsed[v];

   %subtourEliminationLoop;
   for {v in VEHICLES: UseVehicle[v].sol > 0.5} do;
      print v;
      print {<i,j> in ARCS: UseArc[i,j,v].sol > 0.5} travel_time[i,j];
   end;
quit;
