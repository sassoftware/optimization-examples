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
/*    NAME: mpex11                                             */
/*   TITLE: Curve Fitting (mpex11)                             */
/* PRODUCT: GRAPH, OR                                          */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL, SGPLOT                                   */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 11 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data xy_data;
   input x y;
   datalines;
 0.0 1.0
 0.5 0.9
 1.0 0.7
 1.5 1.5
 1.9 2.0
 2.5 2.4
 3.0 3.2
 3.5 2.0
 4.0 2.7
 4.5 3.5
 5.0 1.0
 5.5 4.0
 6.0 3.6
 6.6 2.7
 7.0 5.7
 7.6 4.6
 8.5 6.0
 9.0 6.8
10.0 7.3
;

proc optmodel;
   set POINTS;
   num x {POINTS};
   num y {POINTS};
   read data xy_data into POINTS=[_N_] x y;

   num order;
   var Beta {0..order};
   impvar Estimate {i in POINTS}
      = Beta[0] + sum {k in 1..order} Beta[k] * x[i]^k;

   var Surplus {POINTS} >= 0;
   var Slack {POINTS} >= 0;
   min Objective1 = sum {i in POINTS} (Surplus[i] + Slack[i]);
   con Abs_dev_con {i in POINTS}:
      Estimate[i] - Surplus[i] + Slack[i] = y[i];

   var MinMax;
   min Objective2 = MinMax;
   con MinMax_con {i in POINTS}:
      MinMax >= Surplus[i] + Slack[i];

   num sum_abs_dev = sum {i in POINTS} abs(Estimate[i].sol - y[i]);
   num max_abs_dev = max {i in POINTS} abs(Estimate[i].sol - y[i]);

   problem L1 include
      Beta Surplus Slack
      Objective1
      Abs_dev_con;

   problem Linf from L1 include
      MinMax
      Objective2
      MinMax_con;

   order = 1;
   use problem L1;
   solve;
   print sum_abs_dev max_abs_dev;
   print Beta;
   print x y Estimate Surplus Slack;
   create data sol_data1 from [POINTS] x y Estimate;

   use problem Linf;
   solve;
   print sum_abs_dev max_abs_dev;
   print Beta;
   print x y Estimate Surplus Slack;
   create data sol_data2 from [POINTS] x y Estimate;

   order = 2;
   use problem L1;
   solve;
   print sum_abs_dev max_abs_dev;
   print Beta;
   print x y Estimate Surplus Slack;
   create data sol_data3 from [POINTS] x y Estimate;

   use problem Linf;
   solve;
   print sum_abs_dev max_abs_dev;
   print Beta;
   print x y Estimate Surplus Slack;
   create data sol_data4 from [POINTS] x y Estimate;
quit;

data plot1;
   merge sol_data1(rename=(Estimate=Line1)) sol_data2(rename=(Estimate=Line2));
run;

proc sgplot data=plot1;
   scatter x=x y=y;
   series x=x y=Line1 / curvelabel;
   series x=x y=Line2 / curvelabel;
run;

data plot2;
   merge sol_data3(rename=(Estimate=Curve1))
      sol_data4(rename=(Estimate=Curve2));
run;

proc sgplot data=plot2;
   scatter x=x y=y;
   series x=x y=Curve1 / curvelabel;
   series x=x y=Curve2 / curvelabel;
run;
