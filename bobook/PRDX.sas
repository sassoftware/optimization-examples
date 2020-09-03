/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Production Planning Exercise from section 2.5.1.1.

*/

/* The first table from the book */
data machine_data;
   input machine $ A B C;
   datalines;
M1 2.2 1.8 1.9
M2 2.4 2.0 2.1
;

/* The second table fromt he book transposed. */
data profit_data;
   input product $ profit;
   datalines;
A 24.7
B 22.4
C 19.7
;

proc optmodel;
   /* Declare the inptu data. */
   set <str> PRODUCTS;
   set <str> MACHINES;
   num profit{PRODUCTS};
   num machine_hours{MACHINES, PRODUCTS};

   /* Read the second table first so that we know which products we have. */
   read data profit_data into PRODUCTS=[product] profit;

   /* Read the first table using the PRODUCTS set. */
   read data machine_data into MACHINES=[machine] 
      {product in PRODUCTS} <machine_hours[machine, product] = col(product)>;

   /* Declare the variables. */
   var A >= 0;
   var B >= 0;
   var C >= 0;

   /* Define the objective. We could use sums and better variable names but this stays close to what is in the book. */
   max TotalProfit = profit["A"] * A + profit["B"] * B + profit["C"] * C;

   /* Define the constraints. We could use sums and better variable names but this stays close to what is in the book. */
   con Machine1: machine_hours["M1","A"] * A + machine_hours["M1","B"] * B + machine_hours["M1","C"] * C <= 8;
   con Machine2: machine_hours["M2","A"] * A + machine_hours["M2","B"] * B + machine_hours["M2","C"] * C <= 10;

   /* Solve the problem. The solver is choses automatically. */
   solve;

   /*Print out the problem. */
   expand;

   /* Print the solution. We use a format to show as many decimals of the objective value as the book. */
   print TotalProfit 7.4 A B C;
quit;
