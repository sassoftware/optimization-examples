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

The paper discusses several optimization models. The model shown here uses a side-constrained 
network flow formulation and corresponds to the “A SECONDARY OBJECTIVE” section of the paper. 
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

	num source = 0;
	num sink = 1 + max {g in GAMES} g;
	set NODES = GAMES union {source,sink};

	/* for each game and stadium, include only the shortest feasible arc */
	num infinity = constant('BIG');
	set <num,num> ARCS init {};
	num min {STADIUMS};
	num argmin {STADIUMS};
	str loc_g1, loc_g2;
	for {g1 in GAMES} do;
		loc_g1 = location[g1];
		for {s in STADIUMS} do;
			min[s] = infinity;
			argmin[s] = -1;
		end;
		for {g2 in GAMES} do;
			loc_g2 = location[g2];
			if loc_g1 ne loc_g2
				and start_datetime[g1] + duration[g1]
					+ time_between_stadiums[loc_g1,loc_g2]
					<= start_datetime[g2]
					and min[loc_g2] > start_datetime[g2] then do;
					min[loc_g2] = start_datetime[g2];
					argmin[loc_g2] = g2;
			end;
		end;
		ARCS = ARCS union (setof {s in STADIUMS: argmin[s] ne -1} <g1,argmin[s]>);
	end;
	/* include source and sink */
	ARCS = ARCS union ({source} cross GAMES) union (GAMES cross {sink});
	/* cost = start2 - end1 + duration2 */
	num cost {<g1,g2> in ARCS} =
		(if g1 ne source and g2 ne sink then start_datetime[g2]
		- (start_datetime[g1] + duration[g1]))
		+
		(if g2 ne sink then duration[g2]);

	/* UseArc[g1,g2] = 1 if attend games g1 and g2 and no game in between, 0 otherwise */
	var UseArc {ARCS} binary;
	/* minimize total time between start of first game and end of last game */
	min TotalTime_Network = sum {<g1,g2> in ARCS} cost[g1,g2] * UseArc[g1,g2];
	/* flow balance at every node */
	con Balance {g in NODES}:
	sum {<(g),g2> in ARCS} UseArc[g,g2] - sum {<g1,(g)> in ARCS} UseArc[g1,g]
	= (if g = source then 1 else if g = sink then -1 else 0);
	/* visit every stadium exactly once */
	con Visit_Once_Network {s in STADIUMS}:
	sum {<g1,g2> in ARCS: g2 ne sink and location[g2] = s} UseArc[g1,g2] = 1;
	problem NetworkFormulation include
	UseArc TotalTime_Network Balance Visit_Once_Network;
	use problem NetworkFormulation;


	solve with MILP / logfreq=100000;

	num minTotalTime;
	minTotalTime = TotalTime_Network.sol;
	con TotalTime_con:
		TotalTime_Network <= minTotalTime;
	num distance {<g1,g2> in ARCS} =
		(if g1 = source or g2 = sink then 0
		  else miles_between_stadiums[location[g1],location[g2]]);
	min TotalDistance = sum {<g1,g2> in ARCS} distance[g1,g2] * UseArc[g1,g2];

	solve with MILP / logfreq=100000 parallel=1 primalin;

	set PATH = {<g1,g2> in ARCS: UseArc[g1,g2].sol > 0.5};
	set SOLUTION = {<g1,g2> in PATH: g2 ne sink};

	create data Schedule2(drop=g1) from [g1 g]=SOLUTION
	location[g] away_team[g] home_team[g] city[location[g]] state[location[g]]
	start_datetime=dhms[g]/format=datetime14.
	latitude[location[g]] longitude[location[g]];

quit;
