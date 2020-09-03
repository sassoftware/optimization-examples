/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by John M. Wilson and Josef Kallrath.

Blending Problem, section 2.7.1.

In this version of the example the data is read from a
SAS data set. The SAS data set could be read 
from any data source that is available to SAS,
such as a text file, a spreadsheet or a database.

*/

/* Addtional ore types can be added here to create bigger 
   instances without changing the model below.
   As written here the name of the ore may not exceed 8
   characters but this can be adjusted by changing the 
   format for type.
*/
data ore_data;
   format type $8.;
   input type grade cost avail;
   datalines;
Ore1 2.1 85.00 60
Ore2 6.3 93.00 45
;

proc optmodel;
   /* Declare the problem data */
   set <str> ORETYPE;
   num grade{ORETYPE};
   num cost{ORETYPE};
   num avail{ORETYPE};
   num grade_lower = 4;
   num grade_upper = 5;

   /* Read the problem data. */
   read data ore_data into ORETYPE=[type] grade cost avail;

   /* Declare variables. 
      We include the limit constraint as an upper bound. */
   var Amount{j in ORETYPE} >= 0 <= avail[j];

   /* State the objective. */
   max Net_profit = sum{j in ORETYPE} (125 - cost[j]) * Amount[j];

   /* Define the final grade as an implied variable or printing. */
   impvar FinalGrade = (sum{j in ORETYPE} grade[j] * Amount[j]) / sum{j in ORETYPE} Amount[j];

   /* State the final grade constraints. */
   con Grade_max: sum{j in ORETYPE} (grade_upper - grade[j]) * Amount[j] >= 0;
   con Grade_min: sum{j in ORETYPE} (grade[j] - grade_lower) * Amount[j] >= 0;

   /* Solve the optimization problem. The solver is chosen automatically. */
   solve;

   /* Print the optimization problem. */
   expand;

   /* Print the values of the variables in the optimal solution. */
   print Amount;

   /* Print the final grade for this solution. */
   print FinalGrade;
quit;
