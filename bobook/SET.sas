/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 7.6, set covering problem.

*/
/* The container data from the book brought into a format that is easy to read. */
data container_data;
   input id item;
   datalines;
1 1
1 8
1 11
1 17
2 2
2 8
2 9
2 11
2 12
3 3
3 4
3 5
3 6
3 15
4 7
4 8
4 12
4 14
4 16
5 6
5 9
5 12
5 15
5 20
6 10
6 13
6 18
6 19
7 6
7 8
7 12
7 15
8 12
8 14
8 16
8 18
9 1
9 5
9 10
9 20
10 7
10 13
10 17
10 19
;

proc optmodel;
   /* To read the container data we need an auxilliary set of the pairs in the input.*/
   set <num,num> PAIRS;
   read data container_data into PAIRS=[id item];
   set IDS = setof {<id,item> in PAIRS} id;

   /* This is a lost of sets. */
   set ITEMS init {};
   set CONTAINERS {IDS} init {};
   for {<id,item> in PAIRS} do;
      CONTAINERS[id] = CONTAINERS[id] union {item};
	  ITEMS = ITEMS union {item};
   end;

   /* Decleare the variables. */
   var Mark{ITEMS} binary;

   /* Declare the objective function. We use the mod function to decide if even or odd. */
   min TotalCost = sum {item in ITEMS} (if mod(item, 2) = 1 then 50 else 100)*Mark[item];

   /* Contraint that each container has to have a marked item. */
   con AllMarked {id in IDs}: sum {item in CONTAINERS[id]} Mark[item] >= 1;

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Print the solution. */
   print {item in ITEMS: Mark[item].sol > 0.5} Mark;
quit;
