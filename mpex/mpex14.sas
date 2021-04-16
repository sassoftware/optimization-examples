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
/*    NAME: mpex14                                             */
/*   TITLE: Opencast Mining (mpex14)                           */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 14 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data block_data;
   input level row column percent;
   datalines;
1 1 1  1.5
1 1 2  1.5
1 1 3  1.5
1 1 4  0.75
1 2 1  1.5
1 2 2  2.0
1 2 3  1.5
1 2 4  0.75
1 3 1  1.0
1 3 2  1.0
1 3 3  0.75
1 3 4  0.5
1 4 1  0.75
1 4 2  0.75
1 4 3  0.5
1 4 4  0.25
2 1 1  4.0
2 1 2  4.0
2 1 3  2.0
2 2 1  3.0
2 2 2  3.0
2 2 3  1.0
2 3 1  2.0
2 3 2  2.0
2 3 3  0.5
3 1 1 12.0
3 1 2  6.0
3 2 1  5.0
3 2 2  4.0
4 1 1  6.0
;

data level_data;
   input cost;
   datalines;
3000
6000
8000
10000
;

%let full_value = 200000;

proc optmodel;
   set BLOCKS;
   num level {BLOCKS};
   num row {BLOCKS};
   num column {BLOCKS};
   num revenue {BLOCKS};
   read data block_data into BLOCKS=[_N_] level row column revenue=percent;
   for {block in BLOCKS} revenue[block] = &full_value * revenue[block] / 100;

   set LEVELS;
   num cost {LEVELS};
   read data level_data into LEVELS=[_N_] cost;

   var Extract {BLOCKS} binary;
   num profit {block in BLOCKS} = revenue[block] - cost[level[block]];
   max TotalProfit = sum {block in BLOCKS} profit[block] * Extract[block];

   con Precedence_con {i in BLOCKS, j in BLOCKS:
      level[j] = level[i] - 1
      and row[j] in {row[i],row[i]+1}
      and column[j] in {column[i],column[i]+1}
      }:
      Extract[i] <= Extract[j];

   solve;
   print Extract profit;

   create data sol_data from
      [block]={block in BLOCKS: Extract[block].sol > 0.5}
      level row column revenue cost[level[block]] profit;
quit;
