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
/*    NAME: mpex22                                             */
/*   TITLE: Efficiency Analysis (mpex22)                       */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL, PRINT, SORT                              */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 22 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/


data inputs;
   input input $9.;
   datalines;
staff
showroom
pop1
pop2
alpha_enq
beta_enq
;

data outputs;
   input output $11.;
   datalines;
alpha_sales
beta_sales
profit
;

data garage_data;
   input garage_name $12. staff showroom pop1 pop2 alpha_enq beta_enq
      alpha_sales beta_sales profit;
   datalines;
Winchester  7  8   10  12 8.5 4   2    0.6  1.5
Andover     6  6   20  30 9   4.5 2.3  0.7  1.6
Basingstoke 2  3   40  40 2   1.5 0.8  0.25 0.5
Poole       14 9   20  25 10  6   2.6  0.86 1.9
Woking      10 9   10  10 11  5   2.4  1    2
Newbury     24 15  15  13 25  19  8    2.6  4.5
Portsmouth  6  7   50  40 8.5 3   2.5  0.9  1.6
Alresford   8  7.5 5   8  9   4   2.1  0.85 2
Salisbury   5  5   10  10 5   2.5 2    0.65 0.9
Guildford   8  10  30  35 9.5 4.5 2.05 0.75 1.7
Alton       7  8   7   8  3   2   1.9  0.7  0.5
Weybridge   5  6.5 9   12 8   4.5 1.8  0.63 1.4
Dorchester  6  7.5 10  10 7.5 4   1.5  0.45 1.45
Bridport    11 8   8   10 10  6   2.2  0.65 2.2
Weymouth    4  5   10  10 7.5 3.5 1.8  0.62 1.6
Portland    3  3.5 3   2  2   1.5 0.9  0.35 0.5
Chichester  5  5.5 8   10 7   3.5 1.2  0.45 1.3
Petersfield 21 12  6   8  15  8   6    0.25 2.9
Petworth    6  5.5 2   2  8   5   1.5  0.55 1.55
Midhurst    3  3.6 3   3  2.5 1.5 0.8  0.2  0.45
Reading     30 29  120 80 35  20  7    2.5  8
Southampton 25 16  110 80 27  12  6.5  3.5  5.4
Bournemouth 19 10  90  12 25  13  5.5  3.1  4.5
Henley      7  6   5   7  8.5 4.5 1.2  0.48 2
Maidenhead  12 8   7   10 12  7   4.5  2    2.3
Fareham     4  6   1   1  7.5 3.5 1.1  0.48 1.7
Romsey      2  2.5 1   1  2.5 1   0.4  0.1  0.55
Ringwood    2  3.5 2   2  1.9 1.2 0.3  0.09 0.4
;

proc optmodel;
   set <str> INPUTS;
   read data inputs into INPUTS=[input];

   set <str> OUTPUTS;
   read data outputs into OUTPUTS=[output];

   set <num> GARAGES;
   str garage_name {GARAGES};
   num input  {INPUTS, GARAGES};
   num output {OUTPUTS, GARAGES};
   read data garage_data into GARAGES=[_N_] garage_name
      {i in INPUTS}  <input[i,_N_]=col(i)>
      {i in OUTPUTS} <output[i,_N_]=col(i)>;

   num k;
   num efficiency_number {GARAGES};
   num weight_sol {GARAGES, GARAGES};

   var Weight {GARAGES} >= 0;
   var Inefficiency >= 0;

   max Objective = Inefficiency;

   con Input_con {i in INPUTS}:
      sum {j in GARAGES} input[i,j] * Weight[j] <= input[i,k];

   con Output_con {i in OUTPUTS}:
      sum {j in GARAGES} output[i,j] * Weight[j] >= output[i,k] * Inefficiency;

   do k = GARAGES;
      solve;
      efficiency_number[k] = 1 / Inefficiency.sol;
      for {j in GARAGES}
         weight_sol[k,j] = (if Weight[j].sol > 1e-6 then Weight[j].sol else .);
   end;

   set EFFICIENT_GARAGES = {j in GARAGES: efficiency_number[j] >= 1 - 1e-6};
   set INEFFICIENT_GARAGES = GARAGES diff EFFICIENT_GARAGES;

   print garage_name efficiency_number;
   create data efficiency_data from [garage] garage_name efficiency_number;

   create data weight_data_dense from [inefficient_garage]=INEFFICIENT_GARAGES
      garage_name
      efficiency_number
      {efficient_garage in EFFICIENT_GARAGES} <col('w'||efficient_garage)
         =weight_sol[inefficient_garage,efficient_garage]>;
   create data weight_data_sparse from
      [inefficient_garage efficient_garage]=
   {g1 in INEFFICIENT_GARAGES, g2 in EFFICIENT_GARAGES: weight_sol[g1,g2] ne .}
      weight_sol;
quit;

proc sort data=efficiency_data;
   by descending efficiency_number;
run;

proc print;
run;

proc sort data=weight_data_dense;
   by descending efficiency_number;
run;

proc print;
run;

proc print data=weight_data_sparse;
run;
