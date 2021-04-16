/* Copyright © 2021, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples

A description of the examples is available at:
https://go.documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/ormpex/titlepage.htm
*/
/***************************************************************/
/*                                                             */
/*          S A S   S A M P L E   L I B R A R Y                */
/*                                                             */
/*    NAME: mpex07                                             */
/*   TITLE: Mining (mpex07)                                    */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*    KEYS: OR                                                 */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 07 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data mine_data;
   input mine $ cost extract_ub quality;
   datalines;
mine1 5 2   1.0
mine2 4 2.5 0.7
mine3 4 1.3 1.5
mine4 5 3   0.5
;

data year_data;
   input year quality_required;
   datalines;
1 0.9
2 0.8
3 1.2
4 0.6
5 1.0
;

%let max_num_worked_per_year = 3;
%let revenue_per_ton = 10;
%let discount_rate = 0.10;

proc optmodel;
   set <str> MINES;
   num cost {MINES};
   num extract_ub {MINES};
   num quality {MINES};
   read data mine_data into MINES=[mine] cost extract_ub quality;

   set YEARS;
   num quality_required {YEARS};
   read data year_data into YEARS=[year] quality_required;

   var IsOpen {MINES, YEARS} binary;
   var IsWorked {MINES, YEARS} binary;
   var Extract {mine in MINES, YEARS} >= 0 <= extract_ub[mine];

   impvar ExtractedPerYear {year in YEARS}
      = sum {mine in MINES} Extract[mine,year];

   num discount {year in YEARS} = 1 / (1 + &discount_rate)^(year - 1);
   print discount;

   impvar TotalRevenue =
      &revenue_per_ton * sum {year in YEARS} discount[year] *
         ExtractedPerYear[year];
   impvar TotalCost =
      sum {mine in MINES, year in YEARS} discount[year] * cost[mine] *
         IsOpen[mine,year];
   max TotalProfit = TotalRevenue - TotalCost;

   con Link {mine in MINES, year in YEARS}:
      Extract[mine,year] <= Extract[mine,year].ub * IsWorked[mine,year];

   con Cardinality {year in YEARS}:
      sum {mine in MINES} IsWorked[mine,year] <= &max_num_worked_per_year;

   con Worked_implies_open {mine in MINES, year in YEARS}:
      IsWorked[mine,year] <= IsOpen[mine,year];
   con Continuity {mine in MINES, year in YEARS diff {1}}:
      IsOpen[mine,year] <= IsOpen[mine,year-1];

   con Quality_con {year in YEARS}:
      sum {mine in MINES} quality[mine] * Extract[mine,year]
    = quality_required[year] * ExtractedPerYear[year];

   num quality_sol {year in YEARS} =
      (sum {mine in MINES} quality[mine] * Extract[mine,year].sol) /
         ExtractedPerYear[year].sol;

   solve;
   print IsOpen IsWorked Extract;
   print ExtractedPerYear quality_sol quality_required;
   create data sol_data1 from [mine year] IsOpen IsWorked Extract;
   create data sol_data2 from [year] ExtractedPerYear;
quit;
