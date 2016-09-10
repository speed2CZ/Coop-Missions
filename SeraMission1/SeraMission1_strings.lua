-----------
-- Story --
-----------
-- General overview:
--    	UEF is developing new experimental weapons on this planet, orbital satellites. This research must be stopped.
--    
-- Mission 1
--		Order fleet moved on map and starts building units. Those are given to player to destroy UEF base on the island, so ACU's can gate in.
--		Objective to destroy the first research station.
--		Time limit to complete this mission, UEF satellites are aproaching and the only way to stop them is to gate in ACU and let QAI upload a virus to disable them.
--      Few minutes after the timer is revealed, there's an option to gate in the ACU's immediately.
--
-- Mission 2
--		ACU's will spawn in on the islands. Depending on number of players. Player will play with Order AI or with team mates.
--		Other coop players will have sACU
--		Enemy Bases on other two islands. One UEF, one Cybran.
--      Incoming counter attack from both Cybran and UEF
--      
--      After the intro the satellites are aproaching player's ACU. QAI uploads the virus and disables them.
--
--				TODO: next objective that will lead to Mission 3
--
-- Mission 3
-- 		Destroying the main research facility, TBD
--
--				TODO: this part is not done yet
--
-- Character names / voice actors:
--		Seraphim: TBD / everywhere116
-- 		UEF Commander: TBD / TBD
--		Aeon Commander: TBD / TBD
--		Research: TBD / TBD
--      QAI: QAI / TBD
--
--			Info: Voice actors can suggest names for their characters.



-------------
-- Win / Lose
-------------



-- Both mobile factories dead / Actor: TBD / Update 9/9/2016 / VO TODO
M1_Carriers_Died = {
	{text = '[Seraphim]: You let the UEF to destroy your mobile factories!', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Timer Ran Out / Actor: TBD / Update 9/9/2016 / VO TODO
M1_Time_Ran_Out = {
	{text = '[QAI]: I\'m detecting several UEF experimental satellites aproaching the starting position.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

-- Kill Game Dialogue / Actor: TBD / Update 1/8/2016 / VO TODO
Kill_Game_Dialogue = {
	{text = '[Seraphim]: You have failed us.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



--------
-- NIS 1
--------



------------
-- Dialogues
------------
-- Research Station / Actor: TBD / Update 1/8/2016 / VO TODO
Intro_Research_Station = {
	{text = '[Seraphim]: This is one of the UEF\'s research stations for creating experimental weapons on this planet.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- First Base / Actor: TBD / Update 1/8/2016 / VO TODO
Intro_UEF_Base = {
	{text = '[Seraphim]: The station is guarded by a small base that must be destroyed before we can send ACUs.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- UEF Patrols / Actor: TBD / Update 1/8/2016 / VO TODO
Intro_Patrols = {
	{text = '[Seraphim]: The UEF has many units patrolling in this area. Be careful there.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Carriers / Actor: TBD / Update 1/8/2016 / VO TODO
Intro_Carriers = {
	{text = '[Seraphim]: Order forces are coming in from southeast to begin the assault.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
	{text = '[Seraphim]: A Tempest and an aircraft carrier will provide you units to clear the landing area so ACUs can gate in.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



------------
-- Mission 1
------------



-------------
-- Objectives
-------------
-- Primary Objective 1 - Kill Research Station
M1_P1_Title = 'Destroy UEF Research Station'
M1_P1_Description = 'UEF is developing new weapons on this planet. Destroy marked research station to slow down their progress.'

-- Secondary Objective 1 - Clear Landing Areas
M1_S1_Title = 'Destroy the UEF Island Base'
M1_S1_Description = 'It is advised to eliminate all UEF forces on the island before we send in the ACUs.'

-- Primary Objective 2 - Protect Carrier
M1_P2_Title = 'Protect Order Aircraft Carrier and Tempest'
M1_P2_Description = 'Order will provide you units for an attack on the UEF island base. Make sure you don\'t lose mobile factories. At least one must survive.'

-- Primary Objective 3 - Timer
M1_P3_Title = 'Gate in with ACU'
M1_P3_Description = 'ACUs must gate before UEF\'s Defense Sattelites arrives.'



---------
-- Others
---------
-- Title and description of the button
GateIn_Button_Title = 'Gate In ACUs'
GateIn_Button_Description = 'Signal that you are ready to gate in.'

-- Dialogue text after clicking the button
GateIn_Dialogue = 'Are you sure that you want to proceed to the next part of the mission?'



------------
-- Dialogues
------------
-- Objective to kill research station / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Kill_Research_Station_1 = {
	{text = '[Seraphim]: The UEF can\'t be allowed to finish their research. Clear the landing area of any enemy units and destroy the first research station.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Following dialogue / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Kill_Research_Station_2 = {
	{text = '[Research]: This is Director TODO:name. Research Station Gama is detecting incoming Order units from the southeast.', vid = '', bank = '', cue = '', faction = 'UEF'},
	{text = '[UEF Commander]: I\'m taking over control of all military stuctures. Destroying the Order forces won\'t take long...', vid = '', bank = '', cue = '', faction = 'UEF'},
	{text = '[Order Commander]: We shall see.', vid = '', bank = '', cue = '', faction = 'Aeon'},
}

-- Timer reveal / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Reveal_Timer = {
	{text = '[Seraphim]: Warrior, our intel indicates there are several Experimental Defense Satellites approaching the carrier\'s location.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
	{text = '[UEF Commander]: You\'ve come to the wrong planet you freak!', vid = '', bank = '', cue = '', delay = 5, faction = 'UEF'},
	{text = '[QAI]: I will make a virus that will disable the satellites. However uploading it will require an ACU to be on the planet.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

-- Timer revealed / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Timer_Revealed = {
	{text = '[Seraphim]: Clear the landing area as soon as possible.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Protect Carriers Objective / Actor: TBD / Update 9/9/2016 / VO TODO
M1_Protect_Carriers = {
	{text = '[Order Commander]: Warrior, my mobile factories are the only source of units until we can gate in an ACU. We must protect them at any cost.', vid = '', bank = '', cue = '', faction = 'Aeon'},
}

-- Reveal Gate In Button / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Gate_In_Button = {
	{text = '[Seraphim]: Warrior, the ACUs are ready for gating in. If you want to gate in immediately and destroy rest of the units with your ACU, click on the command signal and then anywhere on the map. ', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



-- Research Station Killed / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Research_Station_Killed_1 = {
	{text = '[Seraphim]: Confirming the first research station is destroyed. Proceed with clearing the landing area.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Research Station Killed / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Research_Station_Killed_2 = {
	{text = '[Seraphim]: Confirming the first research station is destroyed.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- Landing Area Cleared / Actor: TBD / Update 1/8/2016 / VO TODO
M1_Landing_Area_Cleared = {
	{text = '[Seraphim]: The landing area secured. Starting gate in procedures.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



------------
-- Reminders
------------
-- 10 min until satellites arrive / Actor: TBD / Update 8/9/2016 / VO TODO
M1_Timer_Obj_Reminder_1 = {
	{text = '[QAI]: The UEF satellites will arrive in 10 minutes.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

-- 5 min until satellites arrive / Actor: TBD / Update 8/9/2016 / VO TODO
M1_Timer_Obj_Reminder_2 = {
	{text = '[QAI]: The UEF satellites will arrive in 5 minutes.', vid = '', bank = '', cue = '', faction = 'Cybran'},
	{text = '[Seraphim]: Destroy the UEF station now! This assault can\'t fail.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}

-- 1 min until satellites arrive / Actor: TBD / Update 8/9/2016 / VO TODO
M1_Timer_Obj_Reminder_3 = {
	{text = '[QAI]: The UEF satellites will arrive in 1 minutes.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}



--------
-- NIS 2
--------



------------
-- Dialogues
------------
-- Gate in ACU / Actor: TBD / Update 8/9/2016 / VO TODO
M2_Intro_1 = {
	{text = '[QAI]: Gating in AUCs... Virus upload started.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

-- Incoming attack / Actor: TBD / Update 8/9/2016 / VO TODO
M2_Intro_2 = {
	{text = '[Seraphim]: Warrior, enemy units are approaching your position, destroy them all and establish a base. The Order commander will support your assault.', vid = '', bank = '', cue = '', faction = 'Seraphim'},
}



-- Virus uploaded / Actor: TBD / Update 8/9/2016 / VO TODO
M2_Post_Intro_1 = {
	{text = '[QAI]: Virus successfully uploaded. Executing.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

-- Satellites dying / Actor: TBD / Update 8/9/2016 / VO TODO
M2_Post_Intro_2 = {
	{text = '[UEF Commander]: What the hell is going on? I\'m losing control of the satellites, they are falling down from the sky!.', vid = '', bank = '', cue = '', faction = 'UEF'},
	{text = '[Seraphim]: Ha-ha-ha!.', vid = '', bank = '', cue = '', delay = 2, faction = 'Seraphim'},
	{text = '[Research]: Seems like our network got infected with some kind of virus. It is disturbing the communication between the control center and the satellite.', vid = '', bank = '', cue = '', faction = 'UEF'},
	{text = '[UEF Commander]: Fix it ASAP!.', vid = '', bank = '', cue = '', faction = 'UEF'},
}



------------
-- Mission 2
------------



-------------
-- Objectives
-------------



------------
-- Dialogues
------------



------------
-- Reminders
------------



------------
-- Mission 3
------------



-------------
-- Objectives
-------------



------------
-- Dialogues
------------



------------
-- Reminders
------------