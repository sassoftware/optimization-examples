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
/*    NAME: mpex21                                             */
/*   TITLE: Agricultural Pricing (mpex21)                      */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 21 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

/* missing supply indicates unbounded */
data raw_material_data;
   input raw $10. supply;
   datalines;
Fat       600000
DryMatter 750000
Water     .
;

data product_data;
   input product $ Fat DryMatter Water prev_demand prev_price;
   datalines;
Milk     4  9 87 4820000  297
Butter  80  2 18  320000  720
Cheese1 35 30 35  210000 1050
Cheese2 25 40 35   70000  815
;

data elasticity_data;
   input i $ j $ elasticity;
   datalines;
Milk    Milk    -0.4
Butter  Butter  -2.7
Cheese1 Cheese1 -1.1
Cheese2 Cheese2 -0.4
Cheese1 Cheese2  0.1
Cheese2 Cheese1  0.4
;

proc optmodel;
   set <str> RAWS;
   num supply {RAWS};
   read data raw_material_data into RAWS=[raw] supply;

   set <str> PRODUCTS;
   num prev_demand {PRODUCTS};
   num prev_price {PRODUCTS};
   num percent {PRODUCTS, RAWS};
   read data product_data into PRODUCTS=[product]
      {raw in RAWS} <percent[product,raw]=col(raw)> prev_demand prev_price;

   num elasticity {PRODUCTS, PRODUCTS} init 0;
   read data elasticity_data into [i j] elasticity;

   var Price {PRODUCTS} >= 0;

   var Demand {PRODUCTS} >= 0;

   max TotalRevenue
      = sum {product in PRODUCTS} Price[product] * Demand[product];

   con Demand_con {i in PRODUCTS}:
      (Demand[i] - prev_demand[i]) / prev_demand[i]
    = sum {j in PRODUCTS} elasticity[i,j] * (Price[j] - prev_price[j]) /
      prev_price[j];

   con Supply_con {raw in RAWS: supply[raw] ne .}:
      sum {product in PRODUCTS} (percent[product,raw]/100) * Demand[product]
   <= supply[raw];

   con Price_index_con:
      sum {product in PRODUCTS} prev_demand[product] * Price[product]
   <= sum {product in PRODUCTS} prev_demand[product] * prev_price[product];

   solve;
   print Price Demand;
   print Price_index_con.dual;

   solve with NLP / algorithm=activeset soltype=0 opttol=1e-7;
   print Price Demand;
   print Price_index_con.dual;
quit;

proc optmodel;
   set <str> RAWS;
   num supply {RAWS};
   read data raw_material_data into RAWS=[raw] supply;

   set <str> PRODUCTS;
   num prev_demand {PRODUCTS};
   num prev_price {PRODUCTS};
   num percent {PRODUCTS, RAWS};
   read data product_data into PRODUCTS=[product]
      {raw in RAWS} <percent[product,raw]=col(raw)> prev_demand prev_price;

   num elasticity {PRODUCTS, PRODUCTS} init 0;
   read data elasticity_data into [i j] elasticity;

   var Price {PRODUCTS} >= 0;

   impvar Demand {i in PRODUCTS} =
      prev_demand[i] * (1 +
         sum {j in PRODUCTS}
            elasticity[i,j] * (Price[j] - prev_price[j]) / prev_price[j]);

   max TotalRevenue
      = sum {product in PRODUCTS} Price[product] * Demand[product];

   con Demand_nonnegative {i in PRODUCTS}:
      Demand[i] >= 0;

   con Supply_con {raw in RAWS: supply[raw] ne .}:
      sum {product in PRODUCTS} (percent[product,raw]/100) * Demand[product]
   <= supply[raw];

   con Price_index_con:
      sum {product in PRODUCTS} prev_demand[product] * Price[product]
   <= sum {product in PRODUCTS} prev_demand[product] * prev_price[product];

   solve;
   print Price Demand;
   print Price_index_con.dual;

   solve with NLP / soltype=0 opttol=1e-7;
   print Price Demand;
   print Price_index_con.dual;

   solve with NLP / algorithm=activeset soltype=0 opttol=1e-7;
   print Price Demand;
   print Price_index_con.dual;
quit;
