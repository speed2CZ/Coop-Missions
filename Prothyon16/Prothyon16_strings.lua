# Grey = --[[To Do]]--


# During third main objective (UEF Air Base) Seraphim will attack, marked 'Mission 4' here, it is not done yet. 
# Player will spot first seraphim units, first attacks. There will be some dialogues with Gyle, investigating whats going on.
# There will be objective to protect civilians.
# ----------------------------
# Now beginning of 'Mission 5'
# Intro: Morax(sACU) is under Seraphim attack asking for help, some dialogue with Gyle, giving player task to help him (Main objective to protect sACU), 
# also during intro Gyle should come up with info that there is Sera ACU, giving player task to kill it (second main objective).
# Soon after intro there will be secondary objective assigned, protect civilians on the island and get ready for evacuation.
# For that player has to kill 3 seraphim bases on the island (secondary objective).
# Sovietpride as civil guy should say something that they cant evacuate until those bases are destroyed
# Info about destroying those bases, that should be obvious = classis info voiceovers, there will be more of thoses, they should be marked clearly.
# After these 3 bases are destroyed, evacuation from island will start, objective to transport civ trucks to Quantum Gate
# Some VOs when trucks are under attack, losing some, arriving to gate etc...

# When Sera ACU is killed/warped away some VO that ge got away + assigning objective to destroy rest of the base.
# Once base is gone, Morax(sACU) is ready to evacuate as well
# Also several VO when sACU is under attack, losing structures, etc

# Final Part:
# During 'Mission 5', after some time, I ll set it on 30 minutes +- Second Sera ACU will gate in on the small east island. Gyle should inform player. Map will expand.
# 5 minutes later Gyle will inform player about huge incoming attack that will arrive in 30 minues. Player has to finish all objectives until that.
# Some warnings like last 10 min, 5 min, 1 min. 

# This is what will +- happen, it might change. There might not be template ready to everything, but Im sure you can do it easily Retard, write down everything you can.
# Everything doesnt need to be said by Gyle, use Morax and Soviet as well, its up to you to make it good.


# --------
# Game End
# --------

--[[
# Player Win / Actor: Gyle / Update / VO TODO
PlayerWin = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Player Dies / Actor: Gyle / Update / VO TODO
PlayerDies = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}
]]--
# Player Lose To AI / Actor: Gyle / Update 22/05/2015 / VO Ready
PlayerLoseToAI = {
  {text = '[Gyle]: Commander, your ACU has been brought to critical health and can no longer participate in combat. You have been defeated!', vid = 'Pro_16_PlayerLose1.sfd', bank = 'G_VO1', cue = '26Playerlose', faction = 'UEF'},
}
--[[
# sACU Die / Actor: Gyle / Update / VO TODO
sACUDie = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}
]]--


# ----------------------------
# Mission 1
# Destroy Outpost + Beach Base
#-----------------------------



# Intro Sequence 1 / Actor: Gyle / Update 30/07/2015 / VO not ready
intro1 = {
  {text = '[Gyle]: Welcome commander – My name is Gyle and I’ll be your intel officer for the forthcoming scenario. In this mission you will be giving a demonstration to our newest recruits by fighting against a training AI. Your first objective will be to destroy this outpost. ', vid = 'Pro_16_intro1.sfd', bank = 'G_VO1', cue = '1intro1', faction = 'UEF'},
}

# Intro Sequence 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
intro2 = {
  {text = '[Gyle]: There are tech centers positioned around the map - capture them to unlock additional units.', vid = 'Pro_16_intro2.sfd', bank = 'G_VO1', cue = '2intro2', faction = 'UEF'},
}

# Intro Sequence 3 / Actor: Gyle / Update 22/05/2015 / VO Ready
intro3 = {
  {text = '[Gyle]: Your next objective will then be to secure the beach by destroying this base.  ', vid = 'Pro_16_intro3.sfd', bank = 'G_VO1', cue = '3intro3', faction = 'UEF'},
}

# Good luck! / Actor: Gyle / Update 22/05/2015 / VO Ready
postintro = {
  {text = '[Gyle]: The training AI has been activated – Good Luck Commander! ', vid = 'Pro_16_postintro.sfd', bank = 'G_VO1', cue = '4postintro', faction = 'UEF'},
}

# First Base Killed / Actor: Gyle / Update 22/05/2015 / VO Ready
base1killed = {
  {text = '[Gyle]: The outpost has been destroyed, secure the area and push forward. HQ, Out', vid = 'Pro_16_base1killed.sfd', bank = 'G_VO1', cue = '5base1killed', faction = 'UEF'},
}



# Tech building reminder 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
HQcapremind1 = {
  {text = '[Gyle]: Commander, you need to capture the tech centre to gain access to additional units. HQ, Out', vid = 'Pro_16_HQcapremind1.sfd', bank = 'G_VO1', cue = '6HQcapremind1', faction = 'UEF'},
}

# Tech building reminder 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
HQcapremind2 = {
  {text = '[Gyle]: A tech centre is still in enemy hands - you need to capture it to gain an advantage in battle. HQ, Out', vid = 'Pro_16_HQcapremind2.sfd', bank = 'G_VO1', cue = '7HQcapremind2', faction = 'UEF'},
}

# Tech building reminder 3 / Actor: Gyle / Update 22/05/2015 / VO Ready
HQcapremind3 = {
  {text = '[Gyle]: You can only gain access to additional units if you capture a tech centre. Do so as soon as possible. HQ, Out', vid = 'Pro_16_HQcapremind3.sfd', bank = 'G_VO1', cue = '8HQcapremind3', faction = 'UEF'},
}

# Tech building reminder 4 / Actor: Gyle / Update 30/07/2015 / VO not ready, I think. I corrected this.
HQcapremind4 = {
  {text = '[Gyle]: Commander there is still an uncaptured technology centre - you need it to build advanced units. HQ, Out', vid = 'Pro_16_HQcapremind4.sfd', bank = 'G_VO1', cue = '9HQcapremind4', faction = 'UEF'},
}



# First objective reminder 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
base1remind1 = {
  {text = '[Gyle]: The outpost is obstructing your progress. Destroy it immediately. HQ Out', vid = 'Pro_16_base1remind1.sfd', bank = 'G_VO1', cue = '10base1remind1', faction = 'UEF'},
}

# First objective reminder 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
base1remind2 = {
  {text = '[Gyle]: The clock's ticking commander, destroy that base. HQ Out', vid = 'Pro_16_base1remind2.sfd', bank = 'G_VO1', cue = '11base1remind2', faction = 'UEF'},
}

# Second objective reminder 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
base2remind1 = {
  {text = '[Gyle]: The base is still operational - you need to destroy it to secure the beach. HQ Out', vid = 'Pro_16_base1remind2.sfd', bank = 'G_VO1', cue = '12base2remind1', faction = 'UEF'},
}



# ------------------
# Mission 2
# Destroy South Base
# ------------------



# Units moving notification / Actor: Gyle / Update 22/05/2015 / VO Ready
unitmove = {
  {text = '[Gyle]: There will be units moving through your area participating in other training exercises, please ignore them. HQ Out', vid = 'Pro_16_unitmove.sfd', bank = 'G_VO1', cue = '13unitmove', faction = 'UEF'},
}

# Third Objective intro 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
southbase1 = {
  {text = '[Gyle]: Your next task is to neutralise the base in the south, the training AI has been authorised to use tech 2 land and air units, so expect heavy resistance.  ', vid = 'Pro_16_southbase1.sfd', bank = 'G_VO1', cue = '14southbase1', faction = 'UEF'},
}

# Third Objective intro 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
southbase2 = {
  {text = '[Gyle]: Attack immediately and secure the whole island in preparation for phase 3 of the exercise. HQ, Out', vid = 'Pro_16_southbase2.sfd', bank = 'G_VO1', cue = '15southbase2', faction = 'UEF'},
}



# Third objective reminder 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
southbaseremind1 = {
  {text = '[Gyle]: The complex in the south is still operational - send a force to deal with it. HQ, Out', vid = 'Pro_16_southbaseremind1.sfd', bank = 'G_VO1', cue = '16southbaseremind1', faction = 'UEF'},
}

# Third objective reminder 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
southbaseremind2 = {
  {text = '[Gyle]: The island is still not secure - you need to ensure there are no enemy structures remaining. HQ, Out', vid = 'Pro_16_southbaseremind2.sfd', bank = 'G_VO1', cue = '17southbaseremind2', faction = 'UEF'},
}



# Air tech objective / Actor: Gyle / Update 22/05/2015 / VO Ready
airhqtechcentre = {
  {text = '[Gyle]: Another tech centre is located behind the south base. Capture it to gain access to tech 2 air units. HQ Out', vid = 'Pro_16_airhqtechcentre.sfd', bank = 'G_VO1', cue = '18airhqtechcentre', faction = 'UEF'},
}

# Titan patroll objective / Actor: Gyle / Update 22/05/2015 / VO Ready
titankill = {
  {text = '[Gyle]: There are a number of titan units defending this area - engage them at you discretion. HQ Out', vid = 'Pro_16_titankill.sfd', bank = 'G_VO1', cue = '19titankill', faction = 'UEF'},
}

# Titan patroll objective complete / Actor: Gyle / Update 22/05/2015 / VO Ready
titankilled = {
  {text = '[Gyle]: The titan squad has been eliminated - well done commander. ', vid = 'Pro_16_titankilled.sfd', bank = 'G_VO1', cue = '20titankilled', faction = 'UEF'},
}



# ----------------
# Mission 3
# Destroy Air Base
# ----------------



# Third objective intro 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
airbase1 = {
  {text = '[Gyle]: The island is now secure.', vid = 'Pro_16_airbase1.sfd', bank = 'G_VO1', cue = '21airbase1', faction = 'UEF'},
}

# Third objective intro 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
airbase2 = {
  {text = '[Gyle]: Your next objective is to land on the neighbouring island and eliminate this base. The AI has been instructed to use land, air and naval units so watch your step. ', vid = 'Pro_16_airbase2.sfd', bank = 'G_VO1', cue = '22airbase2', faction = 'UEF'},
}

# Third objective intro 3 / Actor: Gyle / Update 22/05/2015 / VO Ready
postintro3 = {
  {text = '[Gyle]: Repel the attacking forces and launch a counter-offensive. HQ, out', vid = 'Pro_16_postintro3.sfd', bank = 'G_VO1', cue = '23postintro', faction = 'UEF'},
}



# Third objective reminder 1 / Actor: Gyle / Update 22/05/2015 / VO Ready
airbaseremind1 = {
  {text = '[Gyle]: The second island is still in the hands of the enemy. Send units to attack it. HQ, Out', vid = 'Pro_16_airbaseremind1.sfd', bank = 'G_VO1', cue = '24airbaseremind1', faction = 'UEF'},
}

# Third objective reminder 2 / Actor: Gyle / Update 22/05/2015 / VO Ready
airbaseremind2 = {
  {text = '[Gyle]: The Air base is still operational, get it done commander. HQ Out', vid = 'Pro_16_airbaseremind2.sfd', bank = 'G_VO1', cue = '25airbaseremind2', faction = 'UEF'},
}



# Most important part / Actor: Gyle / Update 22/05/2015 / VO Ready
epicEprop = {
  {text = '[Gyle]: Thank you for playing this scenario. This experience has been brought to you courtesy of empire clan. Mission made by speed2, some other useless things were made by Exotic_Retard, and I was responsible for your lovely voiceovers. This is Gyle, Signing out.', vid = 'Pro_16_epicEprop.sfd', bank = 'G_VO1', cue = '27epicEprop', faction = 'UEF'},
}
# Gortonthinksthisshouldhappen  Actor: Gyle / Update 30/07/2015 / VO not ready

{text = '[Gyle]: Excellent work Commander. Clean up the rest of the base, and then - 
} 
(end transmission, it should cut out) (reopen trans)
{text = '[Gyle]: Commander, halt all attack on the AI. Regroup your forces and prepare for an attack. Our radar are picking up unidenti- Scratch that. You have hostiles inbound, Seraphim signatures.
}



# ---------
# Mission 4
# 
# ---------



# ------------------------------------------
# Mission 5
# Protect sACU and Defeat Seraphim Commander
# ------------------------------------------


--[[
# Objective 5 Intro 1 / Actor: sACU, Gyle / Update / VO TOD
obj5intro = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}
]]--
# Objective 5 Post Intro / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
obj5postintro = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04346.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04346', faction = 'Seraphim'},
}


--[[
# Main Obj Reminder 1 / Actor: Gyle / Update / VO TODO
M5MainReminder1 = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Main Obj Reminder 2 / Actor: Gyle / Update / VO TODO
M5MainReminder2 = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}



# Sera ACU Defeated / Actor: Gyle / Update / VO TODO
M5SereDefeated = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Sera ACU Defeated Base remains / Actor: Gyle / Update / VO TODO
M5SereBaseRemains = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}



# Protect sACU / Actor: Gyle / Update / VO TODO
ProtectsACU = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Defeat Seraphim ACU / Actor: Gyle / Update / VO TODO
M5KillSeraACU = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU on Losing Defences / Actor: / Update / VO TODO
sACULoseDef = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU on Losing Factory / Actor: / Update / VO TODO
sACULoseFac = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU on Taking Damage / Actor: / Update / VO TODO
sACUTakesDmg = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU Damaged 25% / Actor: / Update / VO TODO
sACUDamaged25 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU Damaged 50% / Actor: / Update / VO TODO
sACUDamaged50 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU Damaged 75% / Actor: / Update / VO TODO
sACUDamaged75 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# sACU Damaged 90% / Actor: / Update / VO TODO
sACUDamaged90 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}



# Secondary Obj Destroy Seraphim Island Bases / Actor: Gyle / Update / VO TODO
IslandBasesKill = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Secondary Obj First Island Base Destroyed / Actor: Gyle / Update / VO TODO
IslandBase1Killed = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Secondary Obj Second Island Base Destroyed / Actor: Gyle / Update / VO TODO
IslandBase2Killed = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Secondary Obj All Island Base Destroyed / Actor: Gyle, sACU / Update / VO TODO
IslandBaseAllKilled = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Secondary Obj All Island Base Destroyed, no Civs left / Actor: Gyle / Update / VO TODO
IslandBaseAllKilledNoCiv = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}



# Secondary Obj Protect Civs / Actor:  / Update / VO TODO
M5ProtectCivs = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Secondary Obj Protect Civs Failed / Actor:  / Update / VO TODO
M5CivsDied = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 4 buildings above min / Actor:  / Update / VO TODO
LosingCivs1 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 1 buildings above min / Actor:  / Update / VO TODO
LosingCivs2 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}



# Secondary obj 3 Evacuate Civs / Actor:  / Update / VO TODO
M5TrucksReady = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Trucks taking damage 1 / Actor:  / Update / VO TODO
M5TruckDamaged1 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# Trucks taking damage 2 / Actor:  / Update / VO TODO
M5TruckDamaged2 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 1 truck destroyed / Actor:  / Update / VO TODO
M5TruckDestroyed1 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 2 trucks destroyed / Actor:  / Update / VO TODO
M5TruckDestroyed2 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 3 trucks destroyed / Actor:  / Update / VO TODO
M5TruckDestroyed3 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# All trucks destroyed, objective failed / Actor:  / Update / VO TODO
M5AllTrucksDestroyed = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# objective complete / Actor:  / Update / VO TODO
M5AllTruckRescued = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 1 truck rescued / Actor:  / Update / VO TODO
M5TruckRescued1 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}

# 2 trucks rescued / Actor:  / Update / VO TODO
M5TruckRescued2 = {
  {text = '[]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}



# Second Sera ACU gates in / Actor:  / Update / VO TODO
M6SecondSeraACU = {
  {text = '[Gyle]:', vid = '', bank = '', cue = '', faction = 'UEF'},
}
]]--


# ------------
# Enemy Taunts
# ------------



# Taunt01 On losing a large attack force / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT1 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04320.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04320', faction = 'Seraphim'},
}

# Taunt02 On losing a large attack force / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT2 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04322.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04322', faction = 'Seraphim'},
}

# Taunt01 On losing defensive structures / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT3 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04324.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04324', faction = 'Seraphim'},
}

# Taunt02 On losing defensive structures / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT4 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04325.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04325', faction = 'Seraphim'},
}

# Taunt01 On losing resource structures / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT5 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04328.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04328', faction = 'Seraphim'},
}

# Taunt02 On losing resource structures / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT12 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04330.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04330', faction = 'Seraphim'},
}

# Taunt01 On attacking / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT14 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04332.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04332', faction = 'Seraphim'},
}

# Taunt01 On destroying defensive structure / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT16 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04334.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04334', faction = 'Seraphim'},
}

# Taunt01 On destroying resource structure / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT18 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04336.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04336', faction = 'Seraphim'},
}

# Taunt01 On building an experimental / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT20 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04338.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04338', faction = 'Seraphim'},
}

# Taunt01 On damaging player ACU 50% / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT23 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04340.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04340', faction = 'Seraphim'},
}

# Taunt02 On damaging player ACU 50% / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT24 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04342.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04342', faction = 'Seraphim'},
}

# Taunt01 UEF / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT26 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04344.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04344', faction = 'Seraphim'},
}

# Taunt01 Cybran / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT28 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04346.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04346', faction = 'Seraphim'},
}

# Taunt01 Aeon / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT30 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04348.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04348', faction = 'Seraphim'},
}

# Taunt01 At 50% health / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT32 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04350.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04350', faction = 'Seraphim'},
}

# Taunt01 On death / Actor: Thel-Uuthow / Update: 06/28/2007 / VO Ready
TAUNT34 = {
  {text = '[Zottoo-Zithutin]: [Language Not Recognized]', vid = 'X03_Thel-Uuthow_T01_04352.sfd', bank = 'X03_VO', cue = 'X03_Thel-Uuthow_T01_04352', faction = 'Seraphim'},
}
