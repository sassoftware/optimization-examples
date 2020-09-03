/* Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/
/*

Examples from the book "Business Optimisation: Using Mathematical Programming (2nd Edition)" by Josef Kallrath.

Exercise 6.5, married couples and wine.

*/
proc optmodel;
   /* Declare the sets. */
   set <str> MEN = {"Carl", "Philip", "Ray", "Roland", "Simon"};
   set <str> WOMEN = {"Kathy", "Margaret", "Marie", "Olive", "Vanessa"};
   set <str> WINES = {"Chianti", "Liebfrauenmilch", "Riesling", "Soave", "Spumante"};
   /* We choose the weekdays as numeric set so that we express the constrints in c) directly. */
   set <num> WEEKDAYS = {1..5};
   set <str, str, str, num> TOUPLES = WOMEN cross MEN cross WINES cross WEEKDAYS;

   /* Declare the variables. */
   var Assign{WOMEN, MEN, WINES, WEEKDAYS} binary;

   /* Basic constraints, force unique assignements. */
   con OnePerWoman {woman in WOMEN}:
      sum {<(woman), man, wine, weekday> in TOUPLES} Assign[woman, man, wine, weekday] = 1;
   con OnePerMan {man in MEN}:
      sum {<woman, (man), wine, weekday> in TOUPLES} Assign[woman, man, wine, weekday] = 1;
   con OnePerWine {wine in WINES}:
      sum {<woman, man, (wine), weekday> in TOUPLES} Assign[woman, man, wine, weekday] = 1;
   con OnePerDay {weekday in WEEKDAYS}:
      sum {<woman, man, wine, (weekday)> in TOUPLES} Assign[woman, man, wine, weekday] = 1;

   /* a) */
   /* Philip is married to Marie. */
   con a1:
      sum {wine in WINES, weekday in WEEKDAYS} Assign["Marie", "Philip", wine, weekday] >= 1;

   /* They did not have wine on Wednesday night. */
   con a2:
      sum {wine in WINES} Assign["Marie", "Philip", wine, 3] = 0;

   /* Carl had wine on Wednesday night. */
   con a3:
      sum {woman in WOMEN, wine in WINES} Assign[woman, "Carl", wine, 3] >= 1;



   /* b) */
   /* The Soave was not drunk on Friday night, ...*/
   con b1:
      sum {woman in WOMEN, man in MEN} Assign[woman, man, "Soave", 5] = 0;
   
   /* ... nor was this wine drunk by Simon. */
   con b2:
      sum {woman in WOMEN, weekday in WEEKDAYS} Assign[woman, "Simon", "Soave", weekday] = 0;



   /* c) */
   /* Simon and his wife had a bottle of wine the night after the couple who
      had the Spumante, ... */
   con c15 {weekday in 1..5}:
      sum {woman in WOMEN, man in MEN} Assign[woman, man, "Spumante", weekday] <= 
      (if weekday + 1 in WEEKDAYS then sum {woman in WOMEN, wine in WINES} Assign[woman, "Simon", wine, weekday + 1]);

   /* ... but two nights after Margaret and her husband had wine. */
   con c2 {weekday in 1..5}:
      sum {man in MEN, wine in WINES} Assign["Margaret", man, wine, weekday] <=
      (if weekday + 2 in WEEKDAYS then sum {woman in WOMEN, wine in WINES} Assign[woman, "Simon", wine, weekday + 2]);



   /* d) */
   /* Kathy did not have wine on Tuesday night, ... */
   con d1:
      sum {man in MEN, wine in WINES} Assign["Kathy", man, wine, 2] <= 1;

   /* ... but she was the person who had the Chianti. */
   con d2:
      sum {man in MEN, weekday in WEEKDAYS} Assign["Kathy", man, "Chianti", weekday] >= 1;



   /* e) */
   /* Olive and her husband, who is not Ray, ... */
   con e1:
      sum {wine in WINES, weekday in WEEKDAYS} Assign["Olive", "Ray", wine, weekday] = 0;

   /* ... enjoyed their wine on Friday.*/
   con e2:
      sum {man in MEN, wine in WINES} Assign["Olive", man, wine, 5] >= 1;


   /* Solve the problem. The MILP solver is selected automatically. */
   solve;

   /* Print only the non-zero values. */ 
   print {<woman, man, wine, weekday> in TOUPLES: Assign[woman,man,wine,weekday].sol > 0.5} Assign;

   /* These commands can be used to find all 36 solutions to the problem. */
   /* Solve the problem. Set the MILP solver to finding all solutions then print only the non-zero values of all solutions.
   solve with milp / soltype=best maxpoolsols=100;

   for {k in 1.._NSOL_}
      print {<woman, man, wine, weekday> in TOUPLES: Assign[woman,man,wine,weekday].sol[k] > 0.5} Assign.sol[k];
   */
quit;
