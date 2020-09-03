/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Solution to Exercise 6.7, manufacturing example with fixed cost.

*/
%let numPeriods = 4;

/* Table of investment data from the book. */
data investment_data;
   input investment year1 year2 year3 year4;
   datalines;
1 -100 -50 150 150
2 -100 -40 50 200
3 40 -100 50 50
4 -200 100 100 200
5 -150 0 150 100
;


proc optmodel;
   /* Declare and read input data. */
   set PERIODS = {1..&numPeriods};
   set INVESTMENTS;
   num investment_gains{INVESTMENTS, PERIODS};
   read data investment_data into INVESTMENTS=[investment] {period in PERIODS} <investment_gains[investment, period] = col("year"||period)>;
   num intrest_rate = 0.15;

   /* We define a set that only contains those variables we need. */
   set <num, num, num> TOUPLES = {<investment, period, year> in INVESTMENTS cross PERIODS cross PERIODS: 
      year + period <= &numPeriods + 1};

   /* Declare variables. */
   /* If Invest[1,2,3] is 1 that means we have an investment in product 1 that started in year 2
      and is now in its third year. */
   var Invest{TOUPLES} binary;

   /* Maximize the net present value for the years 1 to n. */
   max NetPresentValue = sum {current_year in PERIODS} (sum {<investment, period, year> in TOUPLES: period + year - 1 = current_year} investment_gains[investment, year] * Invest[investment, period, year] / (1+intrest_rate)**current_year);

   /* Constraints that ensure that if an investment is started the Invest variable is
   set to 1 for all following periods. */
   con Consecutive{<investment, period, year> in TOUPLES: year > 1}:
      Invest[investment, period, year - 1] = Invest[investment, period, year];

   /* Cashoutflow constraint. */
   con Cashoutflow{current_year in PERIODS}:
      sum {<investment, period, year> in TOUPLES: period + year - 1 = current_year} 
         investment_gains[investment, year] * Invest[investment, period, year] >= -250;

   /* One per year. */
   con OnePerYear{period in PERIODS}:
      sum {<investment, (period), year> in TOUPLES}
      Invest[investment, period, year] >= 1;    

   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Inspect the generated problem. */
   expand; 

   /* Print out the investments to start in each year. */
   print {<investment, period, year> in TOUPLES: Invest[investment, period, year].sol > 0.5} Invest;
quit;
