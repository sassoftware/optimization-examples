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
/*    NAME: mpex18                                             */
/*   TITLE: Optimizing a Constraint (mpex18)                   */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: CLP, OPTMODEL, TRANSPOSE                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 18 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/


data a_data;
   input a @@;
   datalines;
9 13 -14 17 13 -19 23 21
;

%let b = 37;

/* populate macro variable n as number of decision variables */
%let dsid = %sysfunc(open(a_data));
%let n = %sysfunc(attrn(&dsid, NOBS));
%let rc = %sysfunc(close(&dsid));

proc transpose data=a_data out=trans(drop=_name_) prefix=x;
run;

data condata_feas(drop=j);
   length _type_ $8;
   array x[&n];
   set trans;
   _type_ = 'le';
   _rhs_ = &b;
   output;
   do j = 1 to &n;
      x[j] = 1;
   end;
   _type_ = 'binary';
   _rhs_ = .;
   output;
run;

proc clp data=condata_feas out=out_feas allsolns usecondatavars=1;
run;

data condata_infeas;
   set condata_feas;
   if _N_ = 1 then do;
      _type_ = 'ge';
      _rhs_ = _rhs_ + 1;
   end;
run;

proc clp data=condata_infeas out=out_infeas allsolns usecondatavars=1;
run;

proc optmodel;
   set VARS;
   set VARS0 = VARS union {0};
   num a {VARS0};
   read data a_data into VARS=[_N_] a;
   a[0] = &b;

   set FEAS_POINTS;
   num x_feas {FEAS_POINTS, VARS};
   read data out_feas into FEAS_POINTS=[_N_]
      {j in VARS} <x_feas[_N_,j]=col('x'||j)>;

   set INFEAS_POINTS;
   num x_infeas {INFEAS_POINTS, VARS};
   read data out_infeas into INFEAS_POINTS=[_N_]
      {j in VARS} <x_infeas[_N_,j]=col('x'||j)>;

   var Scale {VARS0} >= 0;
   impvar Alpha {j in VARS0} = a[j] * Scale[j];

   con Feas_con {point in FEAS_POINTS}:
      sum {j in VARS} Alpha[j] * x_feas[point,j] <= Alpha[0];
   con Infeas_con {point in INFEAS_POINTS}:
      sum {j in VARS} Alpha[j] * x_infeas[point,j] >= Alpha[0] + 1;

   min Objective1 = abs(a[0]) * Scale[0];
   solve;
   print a Scale Alpha;

   min Objective2 = sum {j in VARS} abs(a[j]) * Scale[j];
   solve;
   print a Scale Alpha;
quit;

proc optmodel;
   set VARS;
   set VARS0 = VARS union {0};
   num a {VARS0};
   read data a_data into VARS=[_N_] a;
   a[0] = &b;

   var X {VARS} binary;
   con CLP_con:
      sum {j in VARS} a[j] * X[j] <= a[0];

   solve with CLP / findallsolns;
   set FEAS_POINTS;
   FEAS_POINTS = 1.._NSOL_;
   num x_feas {FEAS_POINTS, VARS};
   for {s in FEAS_POINTS, j in VARS} x_feas[s,j]=X[j].sol[s];

   CLP_con.lb = CLP_con.ub + 1;
   CLP_con.ub = constant('BIG');

   solve with CLP / findallsolns;
   set INFEAS_POINTS;
   INFEAS_POINTS = 1.._NSOL_;
   num x_infeas {INFEAS_POINTS, VARS};
   for {s in INFEAS_POINTS, j in VARS} x_infeas[s,j]=X[j].sol[s];

   var Scale {VARS0} >= 0;
   impvar Alpha {j in VARS0} = a[j] * Scale[j];

   con Feas_con {point in FEAS_POINTS}:
      sum {j in VARS} Alpha[j] * x_feas[point,j] <= Alpha[0];
   con Infeas_con {point in INFEAS_POINTS}:
      sum {j in VARS} Alpha[j] * x_infeas[point,j] >= Alpha[0] + 1;

   min Objective1 = abs(a[0]) * Scale[0];

   problem LP_problem include Scale Feas_con Infeas_con Objective1;
   use problem LP_problem;

   solve;
   print a Scale Alpha;

   min Objective2 = sum {j in VARS} abs(a[j]) * Scale[j];
   solve;
   print a Scale Alpha;
quit;
