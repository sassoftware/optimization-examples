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
/*    NAME: mpex08                                             */
/*   TITLE: Farm Planning (mpex08)                             */
/* PRODUCT: OR                                                 */
/*  SYSTEM: ALL                                                */
/*   PROCS: OPTMODEL                                           */
/*    DATA:                                                    */
/*                                                             */
/* SUPPORT:                             UPDATE:                */
/*     REF:                                                    */
/*    MISC: Example 08 from the Mathematical Programming       */
/*          Examples book.                                     */
/*                                                             */
/***************************************************************/

data cow_data;
   do age = 0 to 11;
      init_num_cows = 10;
      if age < 2 then do;
         acres_needed = 2/3;
         annual_loss = 0.05;
         bullock_yield = 0;
         heifer_yield = 0;
         milk_revenue = 0;
         grain_req = 0;
         sugar_beet_req = 0;
         labour_req = 10;
         other_costs = 50;
      end;
      else do;
         acres_needed = 1;
         annual_loss = 0.02;
         bullock_yield = 1.1/2;
         heifer_yield = 1.1/2;
         milk_revenue = 370;
         grain_req = 0.6;
         sugar_beet_req = 0.7;
         labour_req = 42;
         other_costs = 100;
      end;
      output;
   end;
run;

data grain_data;
   input group $ acres yield;
   datalines;
group1 20 1.1
group2 30 0.9
group3 20 0.8
group4 10 0.65
;

%let num_years = 5;
%let num_acres = 200;
%let bullock_revenue = 30;
%let heifer_revenue = 40;
%let dairy_cow_selling_age = 12;
%let dairy_cow_selling_revenue = 120;
%let max_num_cows = 130;
%let sugar_beet_yield = 1.5;
%let grain_cost = 90;
%let grain_revenue = 75;
%let grain_labour_req = 4;
%let grain_other_costs = 15;
%let sugar_beet_cost = 70;
%let sugar_beet_revenue = 58;
%let sugar_beet_labour_req = 14;
%let sugar_beet_other_costs = 10;
%let nominal_labour_cost = 4000;
%let nominal_labour_hours = 5500;
%let excess_labour_cost = 1.2;
%let capital_outlay_unit = 200;
%let num_loan_years = 10;
%let annual_interest_rate = 0.15;
%let max_decrease_ratio = 0.50;
%let max_increase_ratio = 0.75;

proc optmodel;
   set AGES;
   num init_num_cows {AGES};
   num acres_needed {AGES};
   num annual_loss {AGES};
   num bullock_yield {AGES};
   num heifer_yield {AGES};
   num milk_revenue {AGES};
   num grain_req {AGES};
   num sugar_beet_req {AGES};
   num cow_labour_req {AGES};
   num cow_other_costs {AGES};
   read data cow_data into AGES=[age]
      init_num_cows acres_needed annual_loss bullock_yield heifer_yield
      milk_revenue grain_req sugar_beet_req cow_labour_req=labour_req
      cow_other_costs=other_costs;

   num num_years = &num_years;
   set YEARS = 1..num_years;
   set YEARS0 = {0} union YEARS;

   var NumCows {AGES union {&dairy_cow_selling_age}, YEARS0} >= 0;
   for {age in AGES} fix NumCows[age,0] = init_num_cows[age];
   fix NumCows[&dairy_cow_selling_age,0] = 0;

   var NumBullocksSold {YEARS} >= 0;
   var NumHeifersSold {YEARS} >= 0;

   set <str> GROUPS;
   num acres {GROUPS};
   num grain_yield {GROUPS};
   var GrainAcres {GROUPS, YEARS} >= 0;

   read data grain_data into GROUPS=[group]
      {year in YEARS} <GrainAcres[group,year].ub=acres>
      grain_yield=yield;
   var GrainBought {YEARS} >= 0;
   var GrainSold {YEARS} >= 0;

   var SugarBeetAcres {YEARS} >= 0;
   var SugarBeetBought {YEARS} >= 0;
   var SugarBeetSold {YEARS} >= 0;

   var NumExcessLabourHours {YEARS} >= 0;
   var CapitalOutlay {YEARS} >= 0;

   num yearly_loan_payment =
      -finance('pmt', &annual_interest_rate, &num_loan_years,
         &capital_outlay_unit);
   print yearly_loan_payment;

   impvar Revenue {year in YEARS} =
      &bullock_revenue * NumBullocksSold[year]
    + &heifer_revenue * NumHeifersSold[year]
    + &dairy_cow_selling_revenue * NumCows[&dairy_cow_selling_age,year]
    + sum {age in AGES} milk_revenue[age] * NumCows[age,year]
    + &grain_revenue * GrainSold[year]
    + &sugar_beet_revenue * SugarBeetSold[year]
   ;
   impvar Cost {year in YEARS} =
      &grain_cost * GrainBought[year]
    + &sugar_beet_cost * SugarBeetBought[year]
    + &nominal_labour_cost
    + &excess_labour_cost * NumExcessLabourHours[year]
    + sum {age in AGES} cow_other_costs[age] * NumCows[age,year]
    + sum {group in GROUPS} &grain_other_costs * GrainAcres[group,year]
    + &sugar_beet_other_costs * SugarBeetAcres[year]
    + sum {y in YEARS: y <= year} yearly_loan_payment * CapitalOutlay[y]
   ;
   impvar Profit {year in YEARS} = Revenue[year] - Cost[year];

   max TotalProfit =
      sum {year in YEARS} (Profit[year]
         - yearly_loan_payment * (num_years - 1 + year) * CapitalOutlay[year]);

   con Num_acres_con {year in YEARS}:
      sum {age in AGES} acres_needed[age] * NumCows[age,year]
    + sum {group in GROUPS} GrainAcres[group,year]
    + SugarBeetAcres[year]
   <= &num_acres;

   con Aging {age in AGES diff {&dairy_cow_selling_age},
              year in YEARS0 diff {num_years}}:
      NumCows[age+1,year+1] = (1 - annual_loss[age]) * NumCows[age,year];

   con NumBullocksSold_def {year in YEARS}:
      NumBullocksSold[year]
    = sum {age in AGES} bullock_yield[age] * NumCows[age,year];

   con NumHeifersSold_def {year in YEARS}:
      NumCows[0,year]
    = sum {age in AGES} heifer_yield[age] * NumCows[age,year]
    - NumHeifersSold[year];

   con Max_num_cows_def {year in YEARS}:
      sum {age in AGES} NumCows[age,year]
   <= &max_num_cows + sum {y in YEARS: y <= year} CapitalOutlay[y];

   impvar GrainGrown {group in GROUPS, year in YEARS} =
      grain_yield[group] * GrainAcres[group,year];
   con Grain_req_def {year in YEARS}:
      sum {age in AGES} grain_req[age] * NumCows[age,year]
   <= sum {group in GROUPS} GrainGrown[group,year]
    + GrainBought[year] - GrainSold[year];

   impvar SugarBeetGrown {year in YEARS} =
      &sugar_beet_yield * SugarBeetAcres[year];
   con Sugar_beet_req_def {year in YEARS}:
      sum {age in AGES} sugar_beet_req[age] * NumCows[age,year]
   <= SugarBeetGrown[year] + SugarBeetBought[year] - SugarBeetSold[year];

   con Labour_req_def {year in YEARS}:
      sum {age in AGES} cow_labour_req[age] * NumCows[age,year]
    + sum {group in GROUPS} &grain_labour_req * GrainAcres[group,year]
    + &sugar_beet_labour_req * SugarBeetAcres[year]
   <= &nominal_labour_hours + NumExcessLabourHours[year];

   con Cash_flow {year in YEARS}:
      Profit[year] >= 0;

   con Final_dairy_cows_range:
      1 - &max_decrease_ratio
   <= (sum {age in AGES: age >= 2} NumCows[age,num_years])
    / (sum {age in AGES: age >= 2} init_num_cows[age])
   <= 1 + &max_increase_ratio;

   solve;

   print NumCows NumBullocksSold NumHeifersSold CapitalOutlay
      NumExcessLabourHours Revenue Cost Profit;
   print GrainAcres;
   print GrainGrown;
   print GrainBought GrainSold SugarBeetAcres SugarBeetGrown SugarBeetBought
      SugarBeetSold;
   print Num_acres_con.body Max_num_cows_def.body Final_dairy_cows_range.body;

   create data sol_data1 from [age]=AGES
      {year in YEARS} <col('NumCows_year'||year)=NumCows[age,year].sol>;

   create data sol_data2 from [group year] GrainAcres GrainGrown;
   create data sol_data3 from [year]
      NumBullocksSold NumHeifersSold CapitalOutlay NumExcessLabourHours
      Revenue Cost Profit GrainBought GrainSold
      SugarBeetAcres SugarBeetGrown SugarBeetBought SugarBeetSold;
quit;
