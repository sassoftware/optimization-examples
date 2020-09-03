/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 5.2, data envelopment analysis.

*/

/* Data table identifying the data. */
data input_data;
   input input $;
   datalines;
SalesA
SalesB
SalesC
;

/* Input data for the DEA, transposed for easier reading.*/
data dea_data;
   input site $ Cost SalesA SalesB SalesC;
   datalines;
Paris 110 50 50 50
London 150 50 100 40
Bonn 200 100 90 60
;

proc optmodel;
   /* Declare and read problem data. */
   set <str> SITES;
   set <str> INPUTS;
   num cost{SITES};
   num values{SITES, INPUTS};
   read data input_data into INPUTS=[input];
   read data dea_data into SITES=[site] cost {input in INPUTS} <values[site, input] = col(input)>;

   /* Set a very small number. */
   num epsilon = 1E-6;

   /* Define the variables. */
   var weight{INPUTS} >= epsilon;

   /* Define the objectives for the three different problems to solve. */
   max Paris = 1/cost['Paris'] * (sum {input in INPUTS} values['Paris', input] * weight[input]);
   max London = 1/cost['London'] * (sum {input in INPUTS} values['London', input] * weight[input]);
   max Bonn = 1/cost['Bonn'] * (sum {input in INPUTS} values['Bonn', input] * weight[input]);

   /* Add the efficiency bound constraint. */
   con EfficiencyBound{site in SITES}:
      (sum {input in INPUTS} values[site, input] * weight[input]) / cost[site] <= 1.0;

   /* Solve the three difference sites and print their weights. */
   solve obj Paris;
   print weight;

   solve obj London;
   print weight;

   solve obj Bonn;
   print weight;
quit;
