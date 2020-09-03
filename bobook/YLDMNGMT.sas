/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Yield Management Example from section 8.4.2.

*/
/* Data from book. */
data yield_data;
   input port : $9. col1-col6;
   datalines;
SH .0 20.12 24.23 47.23 68.20 59.30
Genoa .0 .0 14.80 24.98 52.45 50.12
Port_Said .0 .0 .0 39.50 60.65 48.23
Dubai .0 .0 .0 .0 49.24 28.34
Bombay .0 .0 .0 .0 .0 20.50
Singapore .0 .0 .0 .0 .0 .0
;

data minimum_data;
   input port : $9. col1-col6;
   datalines;
SH .0 1.500 1.000 5.000 1.800 4.000
Genoa .0 .0 4.000 1.500 2.500 2.000
Port_Said .0 .0 .0 3.000 2.300 1.500
Dubai .0 .0 .0 .0 1.200 1.500
Bombay .0 .0 .0 .0 .0 1.800
Singapore .0 .0 .0 .0 .0 .0
;

data maximum_data;
   input port : $9. col1-col6;
   datalines;
SH .0 4.000 5.000 8.000 6.000 12.000
Genoa .0 .0 10.000 4.000 8.000 6.000
Port_Said .0 .0 .0 8.000 5.000 8.000
Dubai .0 .0 .0 .0 2.900 6.700
Bombay .0 .0 .0 .0 .0 8.000
Singapore .0 .0 .0 .0 .0 .0
;

proc optmodel;
   /* Declare and read the input data. */
   set PORTS = {1..6};
   num yield{PORTS, PORTS};
   read data yield_data into [_N_] {i in 1..6} <yield[_N_, i] = col("col" || i)>;
   num minimum{PORTS, PORTS};
   read data minimum_data into [_N_] {i in 1..6} <minimum[_N_, i] = col("col" || i)>;
   num maximum{PORTS, PORTS};
   read data maximum_data into [_N_] {i in 1..6} <maximum[_N_, i] = col("col" || i)>;

   /* Declare the variables. */
   set PAIRS = {i in PORTS, j in i..6};
   var Ship{<i,j> in PAIRS} >= minimum[i,j] <= maximum[i,j];

   /* Declare objective. */
   max TotalYield = sum {<i,j> in PAIRS} yield[i,j] * Ship[i,j];

   /* Declare constraints. */
   con Capacity {port in PORTS diff {1}}:
      sum {<i,j> in PAIRS: i < port && j >= port} Ship[i,j] <= 25;

   /* Solve the problem. */
   solve;

   /* Print the optimal solution. */
   print Ship ;
quit;
