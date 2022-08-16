/* Copyright © 2022, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
https://github.com/sassoftware/optimization-examples
*/

/*
SAS Global Forum Paper: Paper SAS101-2014

The Traveling Baseball Fan Problem and the OPTMODEL Procedure
Authors: Tonya Chapman, Matt Galati, and Rob Pratt, SAS Institute Inc.

In the traveling salesman problem, a salesman must minimize travel distance while 
visiting each of a given set of cities exactly once.  This paper uses the OPTMODEL 
procedure to formulate and solve the traveling baseball fan problem, which complicates 
the traveling salesman problem by incorporating scheduling constraints: a baseball fan 
must visit each of the 30 Major League ballparks exactly once, and each visit must 
include watching a scheduled Major League game.

The paper discusses several optimization models. The model shown here corresponds to 
the “INITIAL FORMULATION” section of the paper.
*/

/** Library path for data location **/
libname tbfp ".../tbfp/data";


proc optmodel;
	set GAMES;
	num start_date {GAMES};
	num start_time {GAMES};
	str location {GAMES};
	str away_team {GAMES};
	str home_team {GAMES};
	read data tbfp.Game_Data into GAMES=[_N_]
		start_date
		start_time=start_time_et
		location
		away_team
		home_team;

	num dhms {g in GAMES} = dhms(start_date[g],0,0,start_time[g]);
	num min_dhms = min {g in GAMES} dhms[g];
	num seconds_per_day = 60 * 60 * 24;
	num start_datetime {g in GAMES} = (dhms[g] - min_dhms) / seconds_per_day;
	num hours_per_game = 4;
	num duration {GAMES} = hours_per_game / 24;
	set <str> STADIUMS;
	num stadium_id {STADIUMS};
	num latitude {STADIUMS};
	num longitude {STADIUMS};
	str city {STADIUMS};
	str state {STADIUMS};
	read data tbfp.Stadium_Data into STADIUMS=[location]
		stadium_id=_N_ latitude longitude city state=st;
	num miles_per_hour = 60;
	set STADIUM_PAIRS = {s1 in STADIUMS, s2 in STADIUMS: s1 ne s2};
	num miles_between_stadiums {<s1,s2> in STADIUM_PAIRS} =
		geodist(latitude[s1],longitude[s1],latitude[s2],longitude[s2],'M');
	num time_between_stadiums {<s1,s2> in STADIUM_PAIRS} =
		miles_between_stadiums[s1,s2] / (miles_per_hour * 24);


	/* Attend[g] = 1 if attend game g, 0 otherwise */
	var Attend {GAMES} binary;
	/* visit every stadium exactly once */
	con Visit_Once {s in STADIUMS}:
		sum {g in GAMES: location[g] = s} Attend[g] = 1;
	/* do not attend games that conflict */
	set CONFLICTS = {g1 in GAMES, g2 in GAMES:
		location[g1] ne location[g2]
		and start_datetime[g1] <= start_datetime[g2]
			< start_datetime[g1] + duration[g1]
				+ time_between_stadiums[location[g1],location[g2]]};
	con Conflict {<g1,g2> in CONFLICTS}:
		Attend[g1] + Attend[g2] <= 1;
	/* declare start of first game and end of last game */
	var Start
		>= min {g in GAMES} start_datetime[g]
		<= max {g in GAMES} start_datetime[g];
	var End
		>= min {g in GAMES} (start_datetime[g] + duration[g])
		<= max {g in GAMES} (start_datetime[g] + duration[g]);
	/* minimize total time between start of first game and end of last game (in days) */
	min TotalTime = End - Start;
	/* if Attend[g] = 1 then Start <= start_datetime[g] */
	con Start_def {g in GAMES}:
		Start - start_datetime[g]
	<= (Start.ub - start_datetime[g]) * (1 - Attend[g]);
	/* if Attend[g] = 1 then End >= start_datetime[g] + duration[g] */
	con End_def {g in GAMES}:
		-End + start_datetime[g] + duration[g]
	<= (-End.lb + start_datetime[g] + duration[g]) * (1 - Attend[g]);
	problem InitialFormulation include
		Attend Conflict Visit_Once Start End TotalTime Start_def End_def;
	use problem InitialFormulation;

	solve with MILP / logfreq=100000 maxtime=3600;


quit;
