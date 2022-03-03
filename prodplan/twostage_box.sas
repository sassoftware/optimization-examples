/* Copyright © 2022, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*
This is a two-stage production planning example that tries to be somewhat realistic.

Setup: A company has two sets of machines. All products are created on one of the first machines and then
finished on the second set of machines.

Input is a list of orders and their due date. There can be multiple orders for the same product with different due dates.

The first stage machines have a fixed output per time period. All order have to be multiples of that number (no waste).

There is one inventory that stores both products between stage1 and stage2 and final products.

The goal is to minimize storage throughout the whole process.

Here an additional complication is that the storage is organized in boxes. The real goal is to minimize the number of boxes used.
Below you find different objectives to minimize total Storage, total number of boxes, and maximum number of boxes.
*/

/* We assume hourly planning for one week. */
%let num_periods = 40;
/* How many machines at each stage can be changed. */
%let num_machines_stage1 = 5;
%let num_machines_stage2 = 2;
%let changeover_cost_stage1 = 1;
%let changeover_cost_stage2 = 1;
%let box_capacity = 20;

/* Order data
   Quantities need to be multiples of stage 1 productions.
   Orders have to have unique due_by or need to be combined.
*/
data order_data;
	input product_nr $ quantity due_by;
   datalines;
1001   5 8
1001   5 16
1001  60 24
1001   5 32
1001  60 40
2001  30 24
2001  90 32
2001 120 40
3001 120 6
3001 120 10
3001 120 20
3001 120 24
3001 200 40
4001 200 40
5001  10 1
5001  10 8
5001  10 15
5001  10 23
5001  10 31
5001  10 38
;

/* Product data */
data product_data;
	input product_nr $ production_stage1 production_stage2;
   datalines;
1001 5 50
2001 10 50
3001 20 50
4001 40 50
5001 10 50
;

/* Data checking. */
proc sort data=order_data;
	by product_nr;
run;
proc sort data=product_data;
	by product_nr;
run;
data _NULL_;
	merge order_data product_data;
	by product_nr;
	/* Check that order is multiple of stage 1 batch size. */
	if mod(quantity,production_stage1) ne 0 then do;
		put "ERROR: Order quantity must be multiple of the products stage 1 production.";
		abort;
	end;
	/* Check that order can be fulfilled in planning period.
	   These are just very basic tests, problem can still be infeasible.
	*/
	if quantity > due_by * production_stage1 * &num_machines_stage1 then do;
		put "ERROR: Order quantity to big for due date in stage 1.";
		abort;
	end;
	if quantity > due_by * production_stage2 * &num_machines_stage2 then do;
		put "ERROR: Order quantity to big for due date in stage 2.";
		abort;
	end;
run;

/* Optimization model */
proc optmodel;
	/* Define the sets. Note that we don't need orders in the model. */
	set <num> PERIODS = 1..&num_periods;
	set <str> PRODUCTS;
	set <num> MACHINES_STAGE1 = 1..&num_machines_stage1;
	set <num> MACHINES_STAGE2 = 1..&num_machines_stage2;
	set <str> STATES = PRODUCTS union {"CHANGE"};

	/* The orders only decide how much product is needed by what time. In the model we want to
	   work on a product level, so we convert the order data into demand data for products. */
	num demand{PERIODS,PRODUCTS} init 0;
	num production_stage1{PRODUCTS};
	num production_stage2{PRODUCTS};

	read data product_data into PRODUCTS=[product_nr] production_stage1 production_stage2;
	/* This statement here is the reason why due_by needs to be unique. */
	read data order_data into [product_nr due_by] demand[due_by,product_nr]=quantity;

	/* Variables */
	/* The Produce variables indicate the amount of a product we produce in a period on a given machine in each stage. */
	var Produce_Stage1{PERIODS,PRODUCTS,MACHINES_STAGE1} >= 0;
	var Produce_Stage2{PERIODS,PRODUCTS,MACHINES_STAGE2} >= 0;
	/* The Use variables indicate that a machine used a certain state in a period. States are products or CHANGE.
	   Machines can also be in an idle state, we don't define that, it is assumed that a machine is idle if it has no other state.
	*/
	var Use_Stage1{PERIODS,MACHINES_STAGE1,STATES} binary;
	var Use_Stage2{PERIODS,MACHINES_STAGE2,STATES} binary;
	/* The Store variables indicate the amount of a product we store at the end of a period in each stage.*/
	var Store_Stage1{PERIODS,PRODUCTS} >= 0;
	var Store_Stage2{PERIODS,PRODUCTS} >= 0;

	/* The Boxes variables store the number of boxes needed to store each product. */
	var Boxes_Stage1{PERIODS,PRODUCTS} >=0 integer;
	var Boxes_Stage2{PERIODS,PRODUCTS} >=0 integer;

	/* Constraints */
	/* Flow balance constraints for stage 1. */
	con flowbalance_stage1{t in PERIODS, p in PRODUCTS}:
		(if (t > 1) then Store_Stage1[t-1,p]) + sum{m in MACHINES_STAGE1} Produce_Stage1[t,p,m] - Store_Stage1[t,p] = sum{m in MACHINES_STAGE2} Produce_Stage2[t,p,m];

	/* Flow balance constraints for stage 2. */
	con flowbalance_stage2{t in PERIODS, p in PRODUCTS}:
		(if (t > 1) then Store_Stage2[t-1,p]) + sum{m in MACHINES_STAGE2} Produce_Stage2[t,p,m] - Store_Stage2[t,p] = demand[t,p];

	/* Machine usage constraint for stage 1. Note that these are equalities! */
	con machine_usage_stage1{t in PERIODS, p in PRODUCTS, m in MACHINES_STAGE1}:
		Produce_Stage1[t,p,m] = production_stage1[p] * Use_stage1[t,m,p];

	/* Machine usage constraint for stage 2. */
	con machine_usage_stage2{t in PERIODS, p in PRODUCTS, m in MACHINES_STAGE2}:
		Produce_Stage2[t,p,m] <= production_stage2[p] * Use_stage2[t,m,p];

	/* Each machine can only be in one state in each period. */
	con one_state_per_machine_stage1{t in PERIODS, m in MACHINES_STAGE1}:
		sum{s in STATES} Use_Stage1[t,m,s] <= 1;
	con one_state_per_machine_stage2{t in PERIODS, m in MACHINES_STAGE2}:
		sum{s in STATES} Use_Stage2[t,m,s] <= 1;

	/* If we change products, we need to have one CHANGE period.
	   Note that is allows keeping a machine set up for a product but not producing (stage 2 only).
	*/
	con changeover_stage1{t in PERIODS, p in PRODUCTS, m in MACHINES_STAGE1: t > 1}:
		Use_Stage1[t,m,p] + Use_Stage1[t,m,"CHANGE"] >= Use_Stage1[t-1,m,p];
	con changeover_stage2{t in PERIODS, p in PRODUCTS, m in MACHINES_STAGE2: t > 1}:
		Use_Stage2[t,m,p] + Use_Stage2[t,m,"CHANGE"] >= Use_Stage2[t-1,m,p];

	/* These constraint link the Boxes variables to the Store variables. */
	con box_constraint_stage1{t in PERIODS, p in PRODUCTS}:
		Store_Stage1[t,p] <= &box_capacity * Boxes_Stage1[t,p];
	con box_constraint_stage2{t in PERIODS, p in PRODUCTS}:
		Store_Stage2[t,p] <= &box_capacity * Boxes_Stage2[t,p];

	/* Manually linearize to minimize the maximum number of boxes. */
	/*var MaxNumBoxes >=0;
	con max_boxes{t in PERIODS}:
		MaxNumBoxes >= sum{p in PRODUCTS} (Boxes_Stage1[t,p] + Boxes_Stage2[t,p]);
	min NumBoxes = MaxNumBoxes;
	solve with milp;
	*/

	/* Automatically linearize to minimize the maximum number of boxes. Only available in newer versions of SAS. */
	min NumBoxes = max{t in PERIODS} sum{p in PRODUCTS} (Boxes_Stage1[t,p] + Boxes_Stage2[t,p]);
	solve with milp linearize;

	/* Alternative objective: Minimize the total number of box used.
	   Run this to see the difference between optimizing the number of boxes and the maximum number of boxes.*/
	/*min StorageBoxes = sum{t in PERIODS, p in PRODUCTS} Boxes_Stage1[t,p]
				+ sum{t in PERIODS, p in PRODUCTS} Boxes_Stage2[t,p];
	solve with milp;
	impvar NeededBoxes{t in PERIODS} = sum{p in PRODUCTS} (ceil(Store_Stage1[t,p]/&box_capacity) + ceil(Store_Stage2[t,p]/&box_capacity));
	print NeededBoxes;*/


	/* Create an output data set. */
	create data production_plan from [t]={PERIODS}
		{p in PRODUCTS}<col("stage1_"||p)=(sum{m in MACHINES_STAGE1} Produce_Stage1[t,p,m])>
		stage1_machines_used=(sum{p in PRODUCTS, m in MACHINES_STAGE1} Use_Stage1[t,m,p])
		stage1_machines_changed=(sum{m in MACHINES_STAGE1} Use_Stage1[t,m,"CHANGE"])
		{p in PRODUCTS}<col("stage2_"||p)=(sum{m in MACHINES_STAGE2} Produce_Stage2[t,p,m])>
		stage2_machines_used=(sum{p in PRODUCTS, m in MACHINES_STAGE2} Use_Stage2[t,m,p])
		stage2_machines_changed=(sum{m in MACHINES_STAGE2} Use_Stage2[t,m,"CHANGE"]);
quit;
