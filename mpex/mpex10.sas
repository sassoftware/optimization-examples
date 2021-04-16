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
/*    NAME: mpex10                                             */
/*   TITLE: Decentralization (mpex10)                          */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 10 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data dept_data;
   input dept $ @@;
   datalines;
A B C D E
;

data city_data;
   input city $;
   datalines;
Bristol
Brighton
London
;

data benefit_data;
   input city $ A B C D E;
   datalines;
Bristol  10 15 10 20  5
Brighton 10 20 15 15 15
;

data comm_data;
   input i $ j $ comm;
   datalines;
A B 0.0
A C 1.0
A D 1.5
A E 0.0
B C 1.4
B D 1.2
B E 0.0
C D 0.0
C E 2.0
D E 0.7
;

data cost_data;
   input i $ j $ cost;
   datalines;
Bristol  Bristol   5
Bristol  Brighton 14
Bristol  London   13
Brighton Brighton  5
Brighton London    9
London   London   10
;

%let max_num_depts = 3;

proc optmodel;
   set <str> DEPTS;
   read data dept_data into DEPTS=[dept];

   set <str> CITIES;
   read data city_data into CITIES=[city];

   num benefit {DEPTS, CITIES} init 0;
   read data benefit_data into [city] {dept in DEPTS}
      <benefit[dept,city]=col(dept)>;
   print benefit;

   num comm {DEPTS, DEPTS} init .;
   read data comm_data into [i j] comm;
   for {i in DEPTS, j in DEPTS} do;
      if i = j then comm[i,j] = 0;
      else if comm[i,j] = . then comm[i,j] = comm[j,i];
   end;
   print comm;

   num cost {CITIES, CITIES} init .;
   read data cost_data into [i j] cost;
   for {i in CITIES, j in CITIES: cost[i,j] = .}
      cost[i,j] = cost[j,i];
   print cost;

   var Assign {DEPTS, CITIES} binary;

   set IJKL = {i in DEPTS, j in CITIES, k in DEPTS, l in CITIES: i < k};
   var Product {IJKL} binary;

   impvar TotalBenefit
      = sum {i in DEPTS, j in CITIES} benefit[i,j] * Assign[i,j];
   impvar TotalCost
      = sum {<i,j,k,l> in IJKL} comm[i,k] * cost[j,l] * Product[i,j,k,l];
   max NetBenefit = TotalBenefit - TotalCost;

   con Assign_dept {dept in DEPTS}:
      sum {city in CITIES} Assign[dept,city] = 1;

   con Cardinality {city in CITIES}:
      sum {dept in DEPTS} Assign[dept,city] <= &max_num_depts;

   con Product_def {<i,j,k,l> in IJKL}:
      Assign[i,j] + Assign[k,l] - 1 <= Product[i,j,k,l];

   con Product_def2 {<i,j,k,l> in IJKL}:
      Product[i,j,k,l] <= Assign[i,j];
   con Product_def3 {<i,j,k,l> in IJKL}:
      Product[i,j,k,l] <= Assign[k,l];

   solve;

   print TotalBenefit TotalCost;
   print Assign;

   drop Product_def Product_def2 Product_def3;

   con Product_def4 {i in DEPTS, k in DEPTS, l in CITIES: i < k}:
      sum {<(i),j,(k),(l)> in IJKL} Product[i,j,k,l] = Assign[k,l];
   con Product_def5 {k in DEPTS, i in DEPTS, j in CITIES: i < k}:
      sum {<(i),(j),(k),l> in IJKL} Product[i,j,k,l] = Assign[i,j];

   solve;

   print TotalBenefit TotalCost;
   print Assign;
quit;
