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
/*    NAME: mpex06                                             */
/*   TITLE: Refinery Optimization (mpex06)                     */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 06 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data crude_data;
   input crude $ crude_ub;
   datalines;
crude1 20000
crude2 30000
;

data arc_data;
   input i $18. j $18. multiplier;
   datalines;
source            crude1            6
source            crude2            6
crude1            light_naphtha     0.1
crude1            medium_naphtha    0.2
crude1            heavy_naphtha     0.2
crude1            light_oil         0.12
crude1            heavy_oil         0.2
crude1            residuum          0.13
crude2            light_naphtha     0.15
crude2            medium_naphtha    0.25
crude2            heavy_naphtha     0.18
crude2            light_oil         0.08
crude2            heavy_oil         0.19
crude2            residuum          0.12
light_naphtha     regular_petrol    .
light_naphtha     premium_petrol    .
medium_naphtha    regular_petrol    .
medium_naphtha    premium_petrol    .
heavy_naphtha     regular_petrol    .
heavy_naphtha     premium_petrol    .
light_naphtha     reformed_gasoline 0.6
medium_naphtha    reformed_gasoline 0.52
heavy_naphtha     reformed_gasoline 0.45
light_oil         jet_fuel          .
light_oil         fuel_oil          .
heavy_oil         jet_fuel          .
heavy_oil         fuel_oil          .
light_oil         light_oil_cracked 2
light_oil_cracked cracked_oil       0.68
light_oil_cracked cracked_gasoline  0.28
heavy_oil         heavy_oil_cracked 2
heavy_oil_cracked cracked_oil       0.75
heavy_oil_cracked cracked_gasoline  0.2
cracked_oil       jet_fuel          .
cracked_oil       fuel_oil          .
reformed_gasoline regular_petrol    .
reformed_gasoline premium_petrol    .
cracked_gasoline  regular_petrol    .
cracked_gasoline  premium_petrol    .
residuum          lube_oil          0.5
residuum          jet_fuel          .
residuum          fuel_oil          .
;

data octane_data;
   input i $18. octane;
   datalines;
light_naphtha      90
medium_naphtha     80
heavy_naphtha      70
reformed_gasoline 115
cracked_gasoline  105
;

data petrol_data;
   input petrol $15. octane_lb;
   datalines;
regular_petrol 84
premium_petrol 94
;

data vapour_pressure_data;
   input oil $12. vapour_pressure;
   datalines;
light_oil   1.0
heavy_oil   0.6
cracked_oil 1.5
residuum    0.05
;

data fuel_oil_ratio_data;
   input oil $12. coefficient;
   datalines;
light_oil   10
cracked_oil  4
heavy_oil    3
residuum     1
;

data final_product_data;
   input product $15. profit;
   datalines;
premium_petrol 700
regular_petrol 600
jet_fuel       400
fuel_oil       350
lube_oil       150
;

%let vapour_pressure_ub = 1;
%let crude_total_ub = 45000;
%let naphtha_ub = 10000;
%let cracked_oil_ub = 8000;
%let lube_oil_lb = 500;
%let lube_oil_ub = 1000;
%let premium_ratio = 0.40;

proc optmodel;
   set <str,str> ARCS;
   num arc_mult {ARCS} init 1;
   read data arc_data nomiss into ARCS=[i j] arc_mult=multiplier;
   var Flow {ARCS} >= 0;

   set <str> FINAL_PRODUCTS;
   num profit {FINAL_PRODUCTS};
   read data final_product_data into FINAL_PRODUCTS=[product] profit;

   for {product in FINAL_PRODUCTS} profit[product] = profit[product] / 100;

   ARCS = ARCS union (FINAL_PRODUCTS cross {'sink'});

   set NODES = union {<i,j> in ARCS} {i,j};

   max TotalProfit = sum {i in FINAL_PRODUCTS} profit[i] * Flow[i,'sink'];

   con Flow_balance {i in NODES diff {'source','sink'}}:
      sum {<(i),j> in ARCS} Flow[i,j]
         = sum {<j,(i)> in ARCS} arc_mult[j,i] * Flow[j,i];

   set <str> CRUDES;
   var CrudeDistilled {CRUDES} >= 0;

   read data crude_data into CRUDES=[crude] CrudeDistilled.ub=crude_ub;
   con Distillation {<i,j> in ARCS: i in CRUDES}:
      Flow[i,j] = CrudeDistilled[i];

   set OILS = {'light_oil','heavy_oil'};
   set CRACKED_OILS = setof {i in OILS} i||'_cracked';
   var OilCracked {CRACKED_OILS} >= 0;
   con Cracking {<i,j> in ARCS: i in CRACKED_OILS}:
      Flow[i,j] = OilCracked[i];

   num octane {NODES} init .;
   read data octane_data nomiss into [i] octane;

   set <str> PETROLS;
   num octane_lb {PETROLS};
   read data petrol_data into PETROLS=[petrol] octane_lb;

   num vapour_pressure {NODES} init .;
   read data vapour_pressure_data nomiss into [oil] vapour_pressure;

   con Blending_petrol {petrol in PETROLS}:
      sum {<i,(petrol)> in ARCS}
         octane[i] * arc_mult[i,petrol] * Flow[i,petrol]
   >= octane_lb[petrol] *
      sum {<i,(petrol)> in ARCS} arc_mult[i,petrol] * Flow[i,petrol];

   con Blending_jet_fuel:
      sum {<i,'jet_fuel'> in ARCS}
         vapour_pressure[i] * arc_mult[i,'jet_fuel'] * Flow[i,'jet_fuel']
   <= &vapour_pressure_ub *
      sum {<i,'jet_fuel'> in ARCS} arc_mult[i,'jet_fuel'] * Flow[i,'jet_fuel'];

   num fuel_oil_coefficient {NODES} init 0;
   read data fuel_oil_ratio_data nomiss into [oil]
      fuel_oil_coefficient=coefficient;
   num sum_fuel_oil_coefficient
      = sum {<i,'fuel_oil'> in ARCS} fuel_oil_coefficient[i];
   con Blending_fuel_oil {<i,'fuel_oil'> in ARCS}:
      sum_fuel_oil_coefficient * Flow[i,'fuel_oil']
   = fuel_oil_coefficient[i] * sum {<j,'fuel_oil'> in ARCS} Flow[j,'fuel_oil'];

   con Crude_total_ub_con:
      sum {i in CRUDES} CrudeDistilled[i] <= &crude_total_ub;

   con Naphtha_ub_con:
      sum {<i,'reformed_gasoline'> in ARCS: index(i,'naphtha') > 0}
         Flow[i,'reformed_gasoline']
   <= &naphtha_ub;

   con Cracked_oil_ub_con:
      sum {<i,'cracked_oil'> in ARCS} Flow[i,'cracked_oil'] <= &cracked_oil_ub;

   con Lube_oil_range_con:
      &lube_oil_lb <= Flow['lube_oil','sink'] <= &lube_oil_ub;

   con Premium_ratio_con:
      sum {<'premium_petrol',j> in ARCS} Flow['premium_petrol',j]
   >= &premium_ratio *
      sum {<'regular_petrol',j> in ARCS} Flow['regular_petrol',j];

   num octane_sol {petrol in PETROLS} =
      (sum {<i,(petrol)> in ARCS}
         octane[i] * arc_mult[i,petrol] * Flow[i,petrol].sol) /
      (sum {<i,(petrol)> in ARCS} arc_mult[i,petrol] * Flow[i,petrol].sol);

   num vapour_pressure_sol =
      (sum {<i,'jet_fuel'> in ARCS} vapour_pressure[i] *
         arc_mult[i,'jet_fuel'] * Flow[i,'jet_fuel'].sol)
      / (sum {<i,'jet_fuel'> in ARCS} arc_mult[i,'jet_fuel'] *
         Flow[i,'jet_fuel'].sol);

   num fuel_oil_ratio_sol {<i,'fuel_oil'> in ARCS} =
      (arc_mult[i,'fuel_oil'] * Flow[i,'fuel_oil'].sol) /
      (sum {<j,'fuel_oil'> in ARCS} arc_mult[j,'fuel_oil'] *
         Flow[j,'fuel_oil'].sol);

   solve;
   print CrudeDistilled;
   print OilCracked Flow;
   print octane_sol octane_lb;

   print {<i,'jet_fuel'> in ARCS} vapour_pressure vapour_pressure_sol;
   print {<i,'fuel_oil'> in ARCS} fuel_oil_coefficient fuel_oil_ratio_sol;
   create data sol_data1 from [i j] Flow;
quit;
