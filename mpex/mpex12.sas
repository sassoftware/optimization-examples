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
/*    NAME: mpex12                                             */
/*   TITLE: Logical Design (mpex12)                            */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 12 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data arc_data;
   input i j;
   datalines;
4 2
5 2
6 3
7 3
2 1
3 1
;

/* truth table (for XOR) */
data truth_data;
   input A B output;
   datalines;
0 0 0
0 1 1
1 0 1
1 1 0
;

proc optmodel;
   set <num,num> ARCS;
   read data arc_data into ARCS=[i j];

   set GATES = union {<i,j> in ARCS} {i,j};

   var UseGate {GATES} binary;
   min NumGatesUsed = sum {gate in GATES} UseGate[gate];

   var AssignAGate {GATES} binary;
   var AssignBGate {GATES} binary;

   con AssignAGate_def {gate in GATES}:
      AssignAGate[gate] <= UseGate[gate];
   con AssignBGate_def {gate in GATES}:
      AssignBGate[gate] <= UseGate[gate];

   con At_most_two_inputs {gate in GATES}:
      sum {<pred,(gate)> in ARCS} UseGate[pred]
    + AssignAGate[gate] + AssignBGate[gate]
   <= 2;

   set ROWS;
   num inputA {ROWS};
   num inputB {ROWS};
   num target_output {ROWS};
   read data truth_data into ROWS=[_N_] inputA=A inputB=B target_output=output;

   var Output {GATES, ROWS} binary;
   for {row in ROWS} fix Output[1,row] = target_output[row];

   con Output_link {gate in GATES, row in ROWS}:
      Output[gate,row] <= UseGate[gate];

   /* if inputA[row] = 1 and AssignAGate[gate] = 1, then
      Output[gate,row] = 0 */
   con NOR_def1 {gate in GATES, row in ROWS}:
      inputA[row] * AssignAGate[gate] <= 1 - Output[gate,row];

   /* if inputB[row] = 1 and AssignBGate[gate] = 1, then
      Output[gate,row] = 0 */
   con NOR_def2 {gate in GATES, row in ROWS}:
      inputB[row] * AssignBGate[gate] <= 1 - Output[gate,row];

   /* if Output[pred,row] = 1, then Output[gate,row] = 0 */
   con NOR_def3 {<pred,gate> in ARCS, row in ROWS}:
      Output[pred,row] <= 1 - Output[gate,row];

   /* if UseGate[gate] = 1 and Output[gate,row] = 0, then
      (inputA[row] = 1 and AssignAGate[gate] = 1)
      or (inputB[row] = 1 and AssignBGate[gate] = 1)
      or sum {<pred,(gate)> in ARCS} Output[pred,row] >= 1 */
   con NOR_def4 {gate in GATES, row in ROWS}:
      inputA[row] * AssignAGate[gate]
    + inputB[row] * AssignBGate[gate]
    + sum {<pred,(gate)> in ARCS} Output[pred,row]
   >= UseGate[gate] - Output[gate,row];

   solve;
   print UseGate AssignAGate AssignBGate;
   print Output;
   create data sol_data1 from [gate] UseGate AssignAGate AssignBGate;
   create data sol_data2 from [gate row] Output;
quit;
