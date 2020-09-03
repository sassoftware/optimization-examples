/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Exercise 6.6, slab optimization.

*/
proc optmodel;
   /* Define a set for the slabs. */
   set SLABS = {1..36};
   /* Define a set for each pipeline. */
   set PIPELINE1 = {2, 3, 4};
   set PIPELINE2 = {7, 16, 17, 18};
   set PIPELINE3 = {10,11,12}; 
   set PIPELINE4 = {13, 14};
   set PIPELINE5 = {25, 34, 33, 32};

   /* Declare the variables. */
   var Open{SLABS} binary;
   var Damage{SLABS} binary;

   /* Declare the objective function. */
   min TotalDamage = sum {slab in SLABS} Damage[slab];

   /* Constraints that describe that one slab for each pipeline has to be opened. */
   con OneFromPipeline1:
      sum {slab in PIPELINE1} Open[slab] >= 1;
   con OneFromPipeline2:
      sum {slab in PIPELINE2} Open[slab] >= 1;
   con OneFromPipeline3:
      sum {slab in PIPELINE3} Open[slab] >= 1;
   con OneFromPipeline4:
      sum {slab in PIPELINE4} Open[slab] >= 1;
   con OneFromPipeline5:
      sum {slab in PIPELINE5} Open[slab] >= 1;

   /* Contraints that link the Damage variables to the Open variables. */
   con SlabDamage{slab in SLABS}:
      (if slab - 1 in SLABS then Damage[slab - 1])
      + (if slab + 1 in SLABS then Damage[slab + 1])
      + (if slab - 9 in SLABS then Damage[slab - 9])
      + (if slab + 9 in SLABS then Damage[slab + 9])
      + Damage[slab]
      >= 
      (1
      + (if slab - 1 in SLABS then 1)
      + (if slab + 1 in SLABS then 1)
      + (if slab - 9 in SLABS then 1)
      + (if slab + 9 in SLABS then 1))
      * Open[slab];

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Print the solution. */
   print TotalDamage Open Damage;
quit;
