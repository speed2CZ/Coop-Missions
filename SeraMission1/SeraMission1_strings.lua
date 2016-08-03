-----------
-- Story --
-----------
-- General overview:
--    
--    
-- Mission 1
--		Order fleet moved on map and starts building units. Those are given to player to destroy UEF base on the island.
--
-- Mission 2
--		ACU's will spawn in on the islands. Depending on number of players. Player will play with Order AI or with team mates.
--		Other coop players will have sACU
--		Enemy Bases on other two islands.
--		
--			TODO: Come up with a story for this. Why are we attacking this planet?
--				  One island will have UEF base on it, second might be Cybran/Aeon?
--
-- Mission 3 ??


-------------
-- Win / Lose
-------------
-- Timer Ran Out / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Time_Ran_Out = {
	{text = '[Seraphim]: You didn\'t manage to complete the objectives in time.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Kill Game Dialogue / Actor: TBD / Update 1/08/2016 / VO TODO
Kill_Game_Dialogue = {
	{text = '[Seraphim]: You have failed us.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



--------
-- NIS 1
--------



-- Research Station / Actor: TBD / Update 1/08/2016 / VO TODO
Intro_Research_Station = {
	{text = '[Seraphim]: This is one of the UEF\'s research stations for creating experimental weapons on this planet.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- First Base / Actor: TBD / Update 1/08/2016 / VO TODO
Intro_UEF_Base = {
	{text = '[Seraphim]: The station is guarded by a small base that must be destroyed before we can send ACUs.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- UEF Patrols / Actor: TBD / Update 1/08/2016 / VO TODO
Intro_Patrols = {
	{text = '[Seraphim]: The UEF has many units patrolling in this area. Be careful there.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Carriers / Actor: TBD / Update 1/08/2016 / VO TODO
Intro_Carriers = {
	{text = '[Seraphim]: Order forces are coming in from southeast to begin the assault.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
	{text = '[Seraphim]: A Tempest and an aircraft carrier will provide you units to clear the landing area so ACUs can gate in.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



------------
-- Mission 1
------------



-- Objective to kill research station / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Kill_Research_Station_1 = {
	{text = '[Seraphim]: The UEF can\'t be allowed to finish their research. Clear the landing area of any enemy units and destroy the first research station.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Following dialogue / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Kill_Research_Station_2 = {
	{text = '[Research]: This is Director TODO:name from Research Station TODO:name. We\'re detecting incoming Order units from the southeast.', vid = '', bank = '', cue = '', faction = 'UEF'},
	{text = '[UEF Commander]: I\'m taking over control of all military stuctures. Destroying the Order forces won\'t take long...', vid = '', bank = '', cue = '', faction = 'UEF'},
	{text = '[Order Commander]: We shall see.', vid = '', bank = '', cue = '', faction = 'Aeon'},
}

-- Timer reveal / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Reveal_Timer = {
	{text = '[Seraphim]: Warrior, our intel indicates there are several Experimental Defense Satellites approaching the carrier\'s location.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
	{text = '[UEF Commander]: You\'ve came to the wrong planet you freak!', vid = '', bank = '', cue = '', delay = 5, faction = 'UEF'},
	{text = '[QAI]: I will make a virus that will disable the satellites. However uploading it will require an ACU to be on the planet.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

-- Timer revealed / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Timer_Revealed = {
	{text = '[Seraphim]: Clear the landing area as soon as possible.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Protect Carriers Objective / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Protect_Carriers = {
	{text = '[Seraphim]: The Order mobile factories are your only source of units until we can gate in an ACU. Protect them at any cost.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Reveal Gate In Button / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Gate_In_Button = {
	{text = '[Seraphim]: Warrior, the ACUs are ready for gating in. If you want to gate in immediately and destroy rest of the units with your ACU, click on the command signal and then anywhere on the map. ', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



-- Research Station Killed / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Research_Station_Killed_1 = {
	{text = '[Seraphim]: Confirming the first research station is destroyed. Proceed with clearing the landing area.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Research Station Killed / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Research_Station_Killed_2 = {
	{text = '[Seraphim]: Confirming the first research station is destroyed.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Landing Area Cleared / Actor: TBD / Update 1/08/2016 / VO TODO
M1_Landing_Area_Cleared = {
	{text = '[Seraphim]: The landing area is clear.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}





M1_Carriers_Died = {
	{text = '[Seraphim]: Cruiser lost.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}




------------
-- Mission 2
------------



------------
-- Mission 3
------------
