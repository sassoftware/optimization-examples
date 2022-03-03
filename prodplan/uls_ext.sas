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
   /* This is the set of allowed production edges. If numPeriods is large, this set will be too big. */
   set EDGES = {i in PERIODS, t in PERIODS: i <= t};

   /* The input parameters. */
   num demand{PERIODS};
   num variable_cost{PERIODS};
   num fixed_cost{PERIODS};
   num store_cost{PERIODS};

   /* Read the data from the data set. */
   read data uls_data into PERIODS=[_N_] demand variable_cost fixed_cost store_cost;

   /* The decision variables. */
   /* How much should be produced in period i for period t. */
   var ProduceInFor{EDGES} >= 0;
   /* This needs to be 1 if we produce anything in period i, 0 otherwise. */
   var Use{PERIODS} binary;
   /* The Produce and Store variables are not directly in the problem anymore.
      We use impvar here to express and report them if needed. */
   impvar Produce{i in PERIODS} = sum{<(i),t> in EDGES} ProduceInFor[i,t];
   impvar Store{t in PERIODS} = sum{<i,j> in EDGES: t in i..j-1} ProduceInFor[i,j];

   /* The demand satisfaction constraint. */
   con demand_satisfaction{t in PERIODS}:
      sum{<i,(t)> in EDGES} ProduceInFor[i,t] = demand[t];

   /* The variable upper bound constraints. Because we have one per edge, these are a lot tighter than in the basic formulation. */
   con vub{<i,t> in EDGES}:
      ProduceInFor[i,t] <= demand[t] * Use[i];

   /* The objective function. Using the impvars here to make it easier. OPTMODEL calculates the new costs for us. */
   min total_cost = sum{t in PERIODS} (variable_cost[t] * Produce[t] + fixed_cost[t] * Use[t] + store_cost[t] * Store[t]);

   /* Solve with the milp solver. This will run out of memory if numPeriods gets too big. */
   solve with milp;

   /* Print the optimal solution and the demand. */
   print Produce Use Store demand;
quit;
