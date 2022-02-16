/* Copyright © 2022, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*
This is an example of an extended formulation for the uncapacitated lot-sizing problem.

See the file uls.sas for a basic formulation for the same problem.
*/

/* This code generates the input data for an uncapacitated lot-sizing problem instance. */
%let seed = 23;
%let numPeriods = 10; /* Number of time periods. */
%let demand_min = 1; /* Define the range for the demands. */
%let demand_max = 10;
%let variable_cost_min = 1; /* Define the range for the variable cost. */
%let variable_cost_max = 5;
%let fixed_cost_min = 20; /* Define the range for the fixed cost. */
%let fixed_cost_max = 30;
%let store_cost_min = 1; /* Define the range for the storage cost. */
%let store_cost_max = 3;
data uls_data;
   call streaminit(&seed); /* set random number seed */
   do i = 1 to &numPeriods;
      demand = rand('INTEGER',&demand_min,&demand_max);
      variable_cost = rand('INTEGER',&variable_cost_min,&variable_cost_max);
      fixed_cost = rand('INTEGER',&fixed_cost_min,&fixed_cost_max);
      store_cost = rand('INTEGER',&store_cost_min,&store_cost_max);
      output;
   end;
   drop i;
run;

proc optmodel;
   /* The set for the time periods. */
   set PERIODS;

   /* The input parameters. */
   num demand{PERIODS};
   num variable_cost{PERIODS};
   num fixed_cost{PERIODS};
   num store_cost{PERIODS};

   /* Read the data from the data set. */
   read data uls_data into PERIODS=[_N_] demand variable_cost fixed_cost store_cost;

   /* Add a sink node with index n+1. */
   num source = 1;
   num sink = card(PERIODS)+1;
   set SOURCES init {source};
   set SINKS init {sink};
   set NODES = PERIODS union SINKS;
   set <num,num,num,num,num> PATHS; /* source, sink, order, from, to */

   /* Define the edges. */
   set EDGES = {i in NODES, j in NODES: i < j};

   /* This array is just here to simplify notation. We store the demand between periods i and j. */
   /* This is done recursively to avoid computing things twice. */
   num demand_between{i in NODES, j in NODES} init if i > j-1 then 0 else demand_between[i,j-1] + demand[j-1];

   /* The weight needs to be redefined to match our formulation. */
   /* This is done recursively and in several steps for performance reasons. */
   num store_sum{i in NODES, j in NODES} init if i > j-1 then 0 else store_sum[i,j-1] + store_cost[j-1];
   num storedemand_sum{<i,j> in EDGES} init
      if <i,j-1> not in EDGES then sum{t in i..j-1} store_cost[t] * demand_between[t+1,j]
      else storedemand_sum[i,j-1] + store_sum[i,j-1] * demand[j-1];
   num weight{<i,j> in EDGES} init fixed_cost[i] + variable_cost[i] * demand_between[i,j] + storedemand_sum[i,j];

   /* This will store the objective value. */
   num length{SOURCES,SINKS};

   /* Solve this using the network solver. */
   solve with NETWORK /
      direction = directed
      links     = (weight=weight)
      shortpath = (source=SOURCES sink=SINKS)
      out       = (sppaths=PATHS spweights=length)
   ;

   /* Print the optimal objective value in the results and in the log. */
   print "Optimal objective value = " length[source,sink];

   /* This code translates the path output from the network solver into the same outputs that we get from other formulations. */
   num produce{PERIODS} init 0;
   num use{PERIODS} init 0;
   num store{PERIODS} init 0;
   for {<so, si, o, f, t> in PATHS} do;
      produce[f] = demand_between[f,t];
      use[f] = 1;
      for {i in PERIODS: f <= i AND i < t}
         store[i]=demand_between[i+1,t];
   end;

   /* Print the optimal solution and the demand. */
   print produce use store demand;
quit;
