/* Copyright � 2022, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*
This is a basic example of uncapacitated lot-sizing using the basic formulation.

See the file uls_extended.sas for an extended formulation for the same problem.
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

    /* The decision variables. */
    /* How many items should be produced in time period t. */
    /* Note that is correct to just put a "big M" as bound on the Produce variables.
       But that would not result in a good, tight formulation. The tight bound
       can be computed as the demand in all remaining periods (we never have to
       produce more than that). */
    var Produce{t in PERIODS} >= 0 <= sum{i in PERIODS: i >= t} demand[i] /*100000*/;
    /* This needs to be 1 if we produce anything in period t, 0 otherwise. */
    var Use{PERIODS} binary;
    /* How many items are in storage at the end of time period t. */
    var Store{PERIODS} >= 0;

    /* The flow balance constraints. We make sure that the amount in storage plus
    the production in each each period match the demand plus anything that is stored
    for later.*/
    con flow_balance{t in PERIODS}:
        (if (t > 1) then Store[t-1]) + Produce[t] = demand[t] + Store[t];

    /* The variable upper bound constraints.  How tight this constraint is depends on the bound we put on
       the Produce variables. If we use a good bound, it is tighter, a generic big M results in looser
       constraints.*/
    con vub_bigM{t in PERIODS}:
        Produce[t] <= Produce[t].ub * Use[t];

    /* The objective function. It minimizes the variable, fixed and storage costs. */
    min total_cost = sum{t in PERIODS} (variable_cost[t] * Produce[t] + fixed_cost[t] * Use[t] + store_cost[t] * Store[t]);

    /* Solve with the MILP solver. */
    solve with milp;

    /* Print the optimal solution and the demand. */
    print Produce Use Store demand;
quit;
