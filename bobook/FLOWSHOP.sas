/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 7.7, flowshop problem.

*/
%let numMachines = 4;

/* Input table from the book, transposed. */
data job_data;
   input job machine1-machine&numMachines;
   datalines;
1 10 9 6 2
2 12 7 4 2
3 14 6 3 1
4 15 4 2 1
5 13 8 4 3
6 12 7 5 3
;

proc optmodel;
   /* Declare and read input data. */
   set MACHINES = {1..&numMachines};
   set JOBS;
   num processing_time {JOBS, MACHINES};
   read data job_data into JOBS=[job] {machine in MACHINES} <processing_time[job, machine] = col("machine" || machine)>;
   num numJobs = card(JOBS);

   /* Declare the variables. Assign[i, j] is 1 if a job i is assigned to a position in the schedule j. */
   var Assign{JOBS, JOBS} binary;
   /* Start[i,k] is the time at which a job in schedule position j starts on machine k. */
   var Start{JOBS, MACHINES} >= 0;

   /* Declare the objective. Minimize the total time to completion of all jobs. */
   min Makespan = Start[numJobs, &numMachines] + sum {i in JOBS} processing_time[i, &numMachines] * Assign[i, numJobs];

   /* Declare the constraints. */
   /* All jobs need to be completed. */
   con AllJobs {j in JOBS}:
      sum {i in JOBS} Assign[i, j] = 1;

   /* All position need to be used. */
   con AllPositions {i in JOBS}:
      sum {j in JOBS} Assign[i, j] = 1;

   /* No idle time in schedule. */
   con Idletime1 {j in JOBS diff {numJobs}}:
      Start[j + 1, 1] = Start[j, 1] + sum {i in JOBS} processing_time[i, 1] * Assign[i, j];
   Fix Start[1,1] = 0;
   con Idletime2 {k in MACHINES diff {&numMachines}}:
      Start[1, k+1] = Start[1, k] + sum {i in JOBS} processing_time[i, k] * Assign[i, 1];

   /* Precedence contstaints. */
   con Precedence1 {j in JOBS diff {1}, k in MACHINES diff {&numMachines}}:
      Start[j, k+1] >= Start[j,k] + sum {i in JOBS} processing_time[i, k] * Assign[i, j];
   con Precedence2 {j in JOBS diff {numJobs}, k in MACHINES diff {1}}:
      Start[j+1, k] >= Start[j,k] + sum {i in JOBS} processing_time[i, k] * Assign[i, j];

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Print the Start variables to see what the schedule is. */
   print Start;

   /* Print the Assign variables to see which job is in which position of the schedule. */
   print Assign;

quit;
