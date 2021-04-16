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
/*    NAME: mpex28                                             */
/*   TITLE: Protein Folding (mpex28)                           */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*    KEYS: OR                                                 */
/*   PROCS: OPTMODEL, SGPLOT                                   */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 28 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/


data hydrophobic_data;
   input position @@;
   datalines;
2 4 5 6 11 12 17 20 21 25 27 28 30 31 33 37 44 46
;

%let num_acids = 50;

proc optmodel;
   num n = &num_acids;
   set POSITIONS = 1..n;
   set HYDROPHOBIC;
   read data hydrophobic_data into HYDROPHOBIC=[position];

   set PAIRS
      = {i in HYDROPHOBIC, j in HYDROPHOBIC: i + 1 < j and mod(j-i-1,2) = 0};

   /* IsFold[i] = 1 if fold occurs between positions i and i + 1; 0 otherwise */
   var IsFold {1..n-1} binary;

   /* IsMatch[i,j] = 1 if hydrophobic pair at positions i and j are matched;
      0 otherwise */
   var IsMatch {PAIRS} binary;

   /* maximize number of matches */
   max NumMatches = sum {<i,j> in PAIRS} IsMatch[i,j];

   /* if IsMatch[i,j] = 1 then IsFold[k] = 0 */
   con DoNotFold {<i,j> in PAIRS, k in i..j-1 diff {(i+j-1)/2}}:
      IsMatch[i,j] + IsFold[k] <= 1;

   /* if IsMatch[i,j] = 1 then IsFold[k] = 1 */
   con FoldHalfwayBetween {<i,j> in PAIRS}:
      IsMatch[i,j] <= IsFold[(i+j-1)/2];

   solve;
   print {i in 1..n-1: IsFold[i].sol > 0.5} IsFold;
   print {<i,j> in PAIRS: IsMatch[i,j].sol > 0.5} IsMatch;

   num x {POSITIONS};
   num y {POSITIONS};
   num xx init 0;
   num yy init 0;
   num dir init 1;
   for {i in POSITIONS} do;
      xx = xx + dir;
      x[i] = xx;
      y[i] = yy;
      if i = n or IsFold[i].sol > 0.5 then do;
         xx = xx + dir;
         dir = -dir;
         yy = yy - 1;
      end;
   end;
   create data plot_data from [i] x y is_hydrophobic=(i in HYDROPHOBIC);
   create data edge_data from [i]=(1..n-1)
      x1=x[i] y1=y[i] x2=x[i+1] y2=y[i+1] linepattern=1;
   create data match_data from [i j]={<i,j> in PAIRS: IsMatch[i,j].sol > 0.5}
      x1=x[i] y1=y[i] x2=x[j] y2=y[j] linepattern=2;
quit;

data sganno(drop=i j);
   retain drawspace "datavalue" linethickness 1;
   set edge_data match_data;
   function = 'line';
run;

proc sgplot data=plot_data sganno=sganno;
   scatter x=x y=y / group=is_hydrophobic datalabel=i;
   xaxis display=none;
   yaxis display=none;
run;
