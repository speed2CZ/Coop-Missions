-----------
-- Story --
-----------
-- General overview:
-- 		UEF is attack a Cybran colony and player's task is to defend and evacuate. Mission designed for at least 2 players.
-- 	  
-- Prologue
-- 		Just showing of my scripting skills, jokes ^^ tehehe
--		Cybran settlement under heavy UEF attack. Player controls sACU and task is to defend the civilian structures.
--		Impossible, player dying after few minutes.
--
-- Mission 2
--		Map moves to the east and reinforting commander will spawn in two different locations. Task is to defend remaining cybran settlements
--		against UEF attacks.
--		After few minutes a new objective is revealed:
--		Destroy 2 UEF T3 Artilleries that are shooting on other settlements. Those are in the middle of UEF base.
--
--			TODO: Think about better position for the artilleries? They might not need to be in the middle of the base. So it's easier to kill them.
--				  And UEF base won't be destroyed by finishing this objective.
--				  Then tune everythng around, base design, place some dead units around. Set better attacks from the bases, etc... see Issues.
--
-- Mission 3
--		Evacuating the north settlement that was under arty fire from the first mission.
--		Incoming UEF attacks.
--
--			TODO: New idea is to let player decide what he wants to do, either evacuate civs or kill UEF commander.
--				  Depending on the choice the map will expand more the to west to reveal UEF base.
-- 				  All bases, attacks, everything needs to be made.



-----------
-- Prologue
-----------
M1_DefendCivs = {
	{text = '[Cybran Guy]: Hold on a bit longer. Reinforcements should arrive soon.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M1_Reinforcements = {
	{text = '[Cybran Commander]: My bases on the south west were destroyed. Sending the rest of my units to help you.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M1_sACU_Dead = {
	{text = '[Cybran Guy]: Something like shit, too late, we lost him. GG no re.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}



------------
-- Mission 2
------------



-- Intro
M2_Intro_1 = {
	{text = '[Cybran Guy]: UEF is progressing to on the other settlements. Your task is to defend them.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M2_Intro_2 = {
	{text = '[Cybran Guy]: Gating in first ACU. Act quicly commander. UEF units are not far.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M2_Intro_3 = {
	{text = '[Cybran Guy]: This is one of the lasts bases in the area. Defeat the attacking forces and regroup with commander to your south.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M2_Intro_4 = {
	{text = '[Cybran Guy]: Both commanders are on the planet. Good luck.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}



M2_KillAttackers = {
	{text = '[Cybran Guy]: Your primary objective is to defend the civilians. Defeat enemy focres closing to your location.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M2_Subplot_1 = {
	{text = '[Cybran Guy]: Scans show that the UEF base is already well established.', vid = '', bank = '', cue = '', faction = 'Cybran'},
}

M2_KillArty = {
	{text = '[Cybran Commander]: HQ, the main city is under artillery fire. I don\'t have enough resources to kill those artilleries and defend the city from UEF attacks. I need help.', vid = '', bank = '', cue = '', faction = 'Cybran'},
	{text = '[Cybran Guy]: Commanders, those heavy artillery installations are in your location. Destroy them as fast as you can.', vid = '', bank = '', cue = '', faction = 'Cybran'},
	{text = '[UEF ACU]: You\'ll die here Cybran.', vid = '', bank = '', cue = '', faction = 'UEF'},
}