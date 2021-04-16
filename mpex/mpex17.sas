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
/*    NAME: mpex17                                             */
/*   TITLE: Three-Dimensional Noughts and Crosses (mpex17)     */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 17 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/


data color_data;
   input num_balls;
   datalines;
13
14
;

%let n = 3;

proc optmodel;
   num n = &n;
   set CELLS = 1..n cross 1..n cross 1..n;

   set COLORS;
   num num_balls {COLORS};
   read data color_data into COLORS=[_N_] num_balls;

   var IsColor {CELLS, COLORS} binary;
   con IsColor_con {<i,j,k> in CELLS}:
      sum {color in COLORS} IsColor[i,j,k,color] = 1;
   con Num_balls_con {color in COLORS}:
      sum {<i,j,k> in CELLS} IsColor[i,j,k,color] = num_balls[color];

   num num_lines init 0;
   set LINES = 1..num_lines;
   var IsMonochromatic {LINES} binary;

   min NumMonochromaticLines = sum {line in LINES} IsMonochromatic[line];

   set <num,num,num> CELLS_line {LINES};

   for {i in 1..n, j in 1..n} do;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {k in 1..n} <i,j,k>;
   end;
   for {i in 1..n, k in 1..n} do;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {j in 1..n} <i,j,k>;
   end;
   for {j in 1..n, k in 1..n} do;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {i in 1..n} <i,j,k>;
   end;

   for {i in 1..n} do;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {j in 1..n} <i,j,j>;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {j in 1..n} <i,j,n+1-j>;
   end;
   for {j in 1..n} do;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {i in 1..n} <i,j,i>;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {i in 1..n} <i,j,n+1-i>;
   end;
   for {k in 1..n} do;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {i in 1..n} <i,i,k>;
      num_lines = num_lines + 1;
      CELLS_line[num_lines] = setof {i in 1..n} <i,n+1-i,k>;
   end;

   num_lines = num_lines + 1;
   CELLS_line[num_lines] = setof {t in 1..n} <t,t,t>;
   num_lines = num_lines + 1;
   CELLS_line[num_lines] = setof {t in 1..n} <t,t,n+1-t>;
   num_lines = num_lines + 1;
   CELLS_line[num_lines] = setof {t in 1..n} <t,n+1-t,t>;
   num_lines = num_lines + 1;
   CELLS_line[num_lines] = setof {t in 1..n} <t,n+1-t,n+1-t>;

   put num_lines=;
   put (((n+2)^3 - n^3) / 2)=;

   con Link_con {line in LINES, color in COLORS}:
      sum {<i,j,k> in CELLS_line[line]} IsColor[i,j,k,color]
    - card(CELLS_line[line]) + 1
   <= IsMonochromatic[line];

   solve;
   num assigned_color {CELLS};
   for {<i,j,k> in CELLS} do;
      for {color in COLORS: IsColor[i,j,k,color].sol > 0.5} do;
         assigned_color[i,j,k] = color;
         leave;
      end;
   end;

   for {i in 1..n}
      print {j in 1..n, k in 1..n} assigned_color[i,j,k];
   for {line in LINES: IsMonochromatic[line].sol > 0.5}
      put CELLS_line[line]=;

   file print;
   for {line in LINES: IsMonochromatic[line].sol > 0.5}
      put CELLS_line[line]=;
quit;
