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
/*    NAME: mpex13                                             */
/*   TITLE: Market Sharing (mpex13)                            */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 13 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data retailer_data;
   input region oil delivery spirit growth $;
   datalines;
1  9  11  34 A
1 13  47 411 A
1 14  44  82 A
1 17  25 157 B
1 18  10   5 A
1 19  26 183 A
1 23  26  14 B
1 21  54 215 B
2  9  18 102 B
2 11  51  21 A
2 17  20  54 B
2 18 105   0 B
2 18   7   6 B
2 17  16  96 B
2 22  34 118 A
2 24 100 112 B
2 36  50 535 B
2 43  21   8 B
3  6  11  53 B
3 15  19  28 A
3 15  14  69 B
3 25  10  65 B
3 39  11  27 B
;

data division_data;
   input target;
   datalines;
0.40
0.60
;

%let tolerance = 0.05;

proc optmodel;
   set RETAILERS;
   num region {RETAILERS};
   num oil {RETAILERS};
   num delivery {RETAILERS};
   num spirit {RETAILERS};
   str growth {RETAILERS};
   read data retailer_data into RETAILERS=[_N_]
      region oil delivery spirit growth;

   set REGIONS init {};
   set RETAILERS_region {REGIONS} init {};
   num r;
   set <str> GROUPS init {};
   set RETAILERS_group {GROUPS} init {};
   str g;
   for {retailer in RETAILERS} do;
      r = region[retailer];
      REGIONS = REGIONS union {r};
      RETAILERS_region[r] = RETAILERS_region[r] union {retailer};
      g = growth[retailer];
      GROUPS = GROUPS union {g};
      RETAILERS_group[g] = RETAILERS_group[g] union {retailer};
   end;

   set DIVISIONS;
   num target {DIVISIONS};
   read data division_data into DIVISIONS=[_N_] target;

   num tolerance = &tolerance;

   var Assign {RETAILERS, DIVISIONS} binary;

   con Assign_con {retailer in RETAILERS}:
      sum {division in DIVISIONS} Assign[retailer,division] = 1;

   set CATEGORIES = {'delivery','spirit'}
      union (setof {reg in REGIONS} 'oil'||reg)
      union (setof {group in GROUPS} 'growth'||group);
   var MarketShare {CATEGORIES, DIVISIONS};
   var Surplus     {CATEGORIES, DIVISIONS} >= 0 <= tolerance;
   var Slack       {CATEGORIES, DIVISIONS} >= 0 <= tolerance;

   min Objective1 =
      sum {category in CATEGORIES, division in DIVISIONS}
         (Surplus[category,division] + Slack[category,division]);

   con Delivery_con {division in DIVISIONS}:
      MarketShare['delivery',division]
    = (sum {retailer in RETAILERS} delivery[retailer] *
         Assign[retailer,division])
         / (sum {retailer in RETAILERS} delivery[retailer]);

   con Spirit_con {division in DIVISIONS}:
      MarketShare['spirit',division]
    = (sum {retailer in RETAILERS} spirit[retailer] *
         Assign[retailer,division])
         / (sum {retailer in RETAILERS} spirit[retailer]);

   con Oil_con {reg in REGIONS, division in DIVISIONS}:
      MarketShare['oil'||reg,division]
    = (sum {retailer in RETAILERS_region[reg]}
         oil[retailer] * Assign[retailer,division])
         / (sum {retailer in RETAILERS_region[reg]} oil[retailer]);

   con Growth_con {group in GROUPS, division in DIVISIONS}:
      MarketShare['growth'||group,division]
    = (sum {retailer in RETAILERS_group[group]} Assign[retailer,division])
         / card(RETAILERS_group[group]);

   con Abs_dev_con {category in CATEGORIES, division in DIVISIONS}:
      MarketShare[category,division]
    - Surplus[category,division] + Slack[category,division]
    = target[division];

   num sum_abs_dev =
      sum {category in CATEGORIES, division in DIVISIONS}
         abs(MarketShare[category,division].sol - target[division]);
   num max_abs_dev =
      max {category in CATEGORIES, division in DIVISIONS}
         abs(MarketShare[category,division].sol - target[division]);

   solve obj Objective1;
   print sum_abs_dev max_abs_dev;
   print Assign;
   print MarketShare Surplus Slack;

   var MinMax >= 0 init max_abs_dev;
   min Objective2 = MinMax;
   con MinMax_con {category in CATEGORIES, division in DIVISIONS}:
      MinMax >= Surplus[category,division] + Slack[category,division];

   solve obj Objective2 with MILP / primalin;
   print sum_abs_dev max_abs_dev;
   print Assign;
   print MarketShare Surplus Slack;
quit;
