local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local Cinematics = import('/lua/cinematics.lua')
local OpStrings = import('/maps/JJ_Mission2/jj_mission2_strings.lua')
local CustomFunctions = import('/maps/JJ_Mission2/jj_mission2_CustomFunctions.lua')
local M1UEFPowerAI = import('/maps/JJ_Mission2/M1_UEF_Power_AI.lua')
local M2UEFNavyAI = import('/maps/JJ_Mission2/M2_UEF_Navy_AI.lua')
local M3FirebaseAI = import('/maps/JJ_Mission2/M3_UEF_Firebase_AI.lua')

---------
-- Globals
---------
ScenarioInfo.Player = 1
ScenarioInfo.UEF = 2
ScenarioInfo.NeutralUEF = 3
ScenarioInfo.UEFAlly = 4
ScenarioInfo.Coop1 = 5
ScenarioInfo.Coop2 = 6
ScenarioInfo.Coop3 = 7

--------
-- Locals
--------
local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local NeutralUEF = ScenarioInfo.NeutralUEF
local UEFAlly = ScenarioInfo.UEFAlly
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3

local LeaderFaction
local LocalFaction

local Difficulty = ScenarioInfo.Options.Difficulty

local M1P1Done = false
local MaxwellDeath = false
local PrisonCaptured = false

local HumanPlayerCounter
local M2ObjectivesComplete = 0

--------
-- Tables
--------
local HumanPlayers = {}
local AttackTriggerTimer = {600, 450, 300}
local UEFAttackCoolDown = {120, 85, 60}
local AllyVehicleSpawn = {50, 100, 150}
local M3BuildTime = {300, 250, 200}

function OnPopulate()
	ScenarioUtils.InitializeScenarioArmies()

	ScenarioFramework.SetUEFPlayerColor(Player)
	SetArmyColor('UEF', 133, 148, 255)
	SetArmyColor('NeutralUEF', 133, 148, 255)
    SetArmyColor('UEFAlly', 71, 134, 226)

    ScenarioFramework.SetPlayableArea('M1_Play_Area', false)
end
  
function OnStart(self)
	-- Create a Trigger for scripted UEF attacks.
	ScenarioFramework.CreateTimerTrigger(UEFAttackPlan, AttackTriggerTimer[Difficulty])
    ScenarioInfo.CityCaptured = false

    --------------
    -- M1 UEF AI
    --------------
    M1UEFPowerAI.M1UEFPowerAIFunction()

	ForkThread(M1IntroNIS)
end

----------
-- End Game
----------
function PlayerWin()
end

function PlayerLose(deadCommander)
end

function KillGameWin()
end

function M1IntroNIS()
	LeaderFaction, LocalFaction = ScenarioFramework.GetLeaderAndLocalFactions()
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Air_Guards_D' .. Difficulty, 'NoFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Guard_Chain_1')))
    end
    Cinematics.EnterNISMode()
	ScenarioFramework.Dialogue(OpStrings.JJ2_NIS1_Intro, nil, true)
	local VisMarker1_1 = ScenarioFramework.CreateVisibleAreaLocation(90, ScenarioUtils.MarkerToPosition('M1_NIS_Vis_Marker_1'), 0, ArmyBrains[Player])
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M1_NIS_Cam1'), 2)
	WaitSeconds(4)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M1_NIS_Cam2'), 3)
	WaitSeconds(1)
	ForkThread(
		function()
			VisMarker1_1:Destroy()
			ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_NIS_Vis_Marker_1'), 110)
		end
	)
	Cinematics.ExitNISMode()

    ForkThread(function()
        WaitSeconds(1)
        if (LeaderFaction == 'aeon') then
            ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'UEFPlayer')
        elseif (LeaderFaction == 'cybran') then
            ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'UEFPlayer')
        elseif (LeaderFaction == 'uef') then
            ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'UEFPlayer')
        end
        ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
        ScenarioInfo.PlayerCDR:SetCustomName(ArmyBrains[Player].Nickname)
        ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
        ScenarioFramework.CreateUnitDeathTrigger(PlayerLose, ScenarioInfo.PlayerCDR)

        -- spawn coop players too
        ScenarioInfo.CoopCDR = {}
        local tblArmy = ListArmies()
        coop = 1
        for iArmy, strArmy in pairs(tblArmy) do
    	    if iArmy >= ScenarioInfo.Coop1 then
                factionIdx = GetArmyBrain(strArmy):GetFactionIndex()
            if (factionIdx == 1) then
                ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'UEFPlayer')
            elseif (factionIdx == 2) then
                ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'UEFPlayer')
            else
                ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'UEFPlayer')
            end
                ScenarioInfo.CoopCDR[coop]:PlayCommanderWarpInEffect()
                ScenarioInfo.CoopCDR[coop]:SetCustomName(ArmyBrains[iArmy].Nickname)
                coop = coop + 1
                HumanPlayerCounter = coop
                WaitSeconds(0.5)
                SetArmyUnitCap(coop, 1000)
            end
        end

        for index, coopACU in ScenarioInfo.CoopCDR do
            ScenarioFramework.PauseUnitDeath(coopACU)
    	    ScenarioFramework.CreateUnitDeathTrigger(PlayerLose, coopACU)
        end
    end)

    WaitSeconds(1)
    ForkThread(M1)
end

function M1()
    ScenarioInfo.M1P1 = Objectives.CategoriesInArea(        
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy UEF Power Generators',  -- title
        'Destroy the UEF Power Generators to the West.',  -- description
        'kill',
        {
            MarkUnits = true,
            Requirements = {
                { Area = 'M1_UEF_Power_Base', Category = categories.ueb1201, CompareOp = '<=', Value = 0, ArmyIndex = UEF},
                { Area = 'M1_UEF_Power_Base', Category = categories.ueb1201, CompareOp = '<=', Value = 0, ArmyIndex = UEF},
                { Area = 'M1_UEF_Power_Base', Category = categories.ueb1301, CompareOp = '<=', Value = 0, ArmyIndex = UEF},
            },
        }
    )

    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.JJ2_M1P1_Complete, nil, true)
                M1P1Done = true
                WaitSeconds(5)
                ForkThread(M2NISIntro)
            end
        end
   )
end

function M2NISIntro()
	ScenarioFramework.SetPlayableArea('M2_Play_Area', true)

	ScenarioInfo.City = ScenarioUtils.CreateArmyGroup('NeutralUEF', 'City')
    ScenarioInfo.CityDefenses = ScenarioUtils.CreateArmyGroup('NeutralUEF', 'Defenses')
    ScenarioInfo.Prison = ScenarioUtils.CreateArmyGroup('UEF', 'Prison')

    local M2_Land_Patrol = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Land_Patrol', 'NoFormation')
    local M2_Sea_Patrol_1 = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Navy_Patrol_1', 'AttackFormation')
    local M2_Sea_Patrol_2 = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Navy_Patrol_2', 'AttackFormation')
    local M2_Sea_Patrol_3 = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Navy_Patrol_3', 'AttackFormation')

    -- Assign Patrol Units to Routes --

    for k, v in M2_Land_Patrol:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Guard_Chain_1')))
    end

    for k, v in M2_Sea_Patrol_1:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Guard_Navy_Chain_1')))
    end

    for k, v in M2_Sea_Patrol_2:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Guard_Navy_Chain_2')))
    end

    for k, v in M2_Sea_Patrol_3:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Guard_Navy_Chain_3')))
    end

	local VisMarker2_1 = ScenarioFramework.CreateVisibleAreaLocation(45, ScenarioUtils.MarkerToPosition('M2_NIS_Vis_Marker_1'), 0, ArmyBrains[Player])
	Cinematics.EnterNISMode()
	WaitSeconds(1)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M2_NIS_Cam1'), 2)
	ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro, nil, true)
	if HumanPlayerCounter == 2 then
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_1, nil, true)
	elseif HumanPlayerCounter == 3 then
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_2, nil, true)
	elseif HumanPlayerCounter == 4 then
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_3, nil, true)
	else
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_0, nil, true)
	end

    if HumanPlayerCounter >= 2 then
        ScenarioInfo.M2S1 = Objectives.Basic(
        'secondary',
        'incomplete', 
        'Move ACU to Complex',
        'CDR Richards has ordered one of you to move your ACU to the Complex to start fortifying that area, move your ACU to the Complex.',
        Objectives.GetActionIcon('move'),
            {
                Area = "M4_Objective_Area",
                MarkArea= true,
            }
        )

        CustomFunctions.CreateAreaTrigger(ACUAtComplex, 'M4_Objective_Area', categories.uel0001, true, false)
    end

	ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_Final, nil, true)
    WaitSeconds(10)
	Cinematics.ExitNISMode()

    VisMarker2_1:Destroy()

	ScenarioInfo.CityNode = ScenarioInfo.UnitNames[NeutralUEF]['CentralStation']
	ScenarioInfo.CityNode:SetCustomName("Complex Central Node")

    if(ScenarioInfo.M1S1.Active) then
        ScenarioInfo.M1S1:ManualResult(true)
        ScenarioFramework.Dialogue(OpStrings.JJ2_M1S1_Complete, nil, true)
    end

    ForkThread(M2)
end

function M2()
    M2UEFNavyAI.M2NavyBaseFunction()

    ScenarioInfo.M2P1 = Objectives.CategoriesInArea(        
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy UEF Naval Base',  -- title
        'The UEF has the river locked down. You need to destroy the Naval Base before capturing the city.',  -- description
        'kill',
        {
            MarkUnits = true,
            Requirements = {
                { Area = 'M2_Navy_Base', Category = categories.FACTORY + categories.ENGINEER, CompareOp = '<=', Value = 0, ArmyIndex = UEF},
            },
        }
    )

    ScenarioInfo.M2P1:AddResultCallback(
        function(result)
            if(result) then
                M2ObjectivesComplete = M2ObjectivesComplete + 1
                if M2ObjectivesComplete == 2 then
                    ForkThread(M3NISIntro)
                end
            end
        end
   )

    ScenarioInfo.M2P2 = Objectives.Capture(
        'primary',
        'incomplete',
        'Capture Civilian Complex',
        'There is a small Civilian Complex to the West. Capture it so we can house the prisoners.',
        {
            MarkUnits = true,
            Units = {ScenarioInfo.CityNode},
        }
    )

    ScenarioInfo.M2P2:AddResultCallback(
        function(result)
            for k, v in ScenarioInfo.CityDefenses do
                if(v and not v:IsDead()) then
                    ScenarioFramework.GiveUnitToArmy(v, Player)
                    ScenarioInfo.CityCaptured = true
                end
            end
            ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Complete, nil, true)
            M2ObjectivesComplete = M2ObjectivesComplete + 1
            if M2ObjectivesComplete == 2 then
                ForkThread(M3NISIntro)
            end
        end
   )
end

function M3NISIntro()
    WaitSeconds(5)
    ScenarioInfo.Shields = ScenarioUtils.CreateArmyGroup('NeutralUEF', 'PrisonShields')

    local VisMarker3_1 = ScenarioFramework.CreateVisibleAreaLocation(20, ScenarioUtils.MarkerToPosition('M3_NIS_Vis_Marker_1'), 0, ArmyBrains[Player])

    for _, v in ScenarioInfo.Shields do
        v:ToggleScriptBit('RULEUTC_ShieldToggle')
    end

    ScenarioFramework.CreateTimerTrigger(UEFAttackComplex, M3BuildTime[Difficulty])

    ScenarioUtils.CreateArmyGroup('UEF', 'Power')
    ScenarioInfo.PrisonStructure = ScenarioInfo.UnitNames[UEF]['PrisonStructure']
    ScenarioInfo.PrisonStructure:SetCustomName("UEF Prison Structure")
    ScenarioInfo.PrisonStructure:SetReclaimable(false)
    ScenarioInfo.PrisonStructure:SetCapturable(true)
    ScenarioInfo.PrisonStructure:SetCanTakeDamage(false)
    ScenarioInfo.PrisonStructure:SetCanBeKilled(false)
    ScenarioInfo.PrisonStructure:SetIntelRadius('Vision', 0)

    ScenarioInfo.SupCommander = ScenarioUtils.CreateArmyUnit('UEF', 'SupCommander')
    ScenarioInfo.SupCommander:SetCustomName("sCDR Maxwell")
    ScenarioInfo.SupCommander:SetCanBeKilled(true)
    ScenarioInfo.SupCommander:SetCanTakeDamage(true)
    ScenarioInfo.SupCommander:CreateEnhancement('Shield')
    ScenarioInfo.SupCommander:CreateEnhancement('AdvancedCoolingUpgrade')
    ScenarioInfo.SupCommander:CreateEnhancement('HighExplosiveOrdnance')

    ScenarioFramework.SetPlayableArea('M3_Play_Area', true)

    ScenarioUtils.CreateArmyGroup('UEF', 'PrisonExpGuards')

    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'Prison_Guards_' .. Difficulty, 'AttackFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M3_Prison_Guard_Chain_1')))
    end

    ScenarioFramework.CreateArmyIntelTrigger(MarkSupportCommanderOnVisible, ArmyBrains[Player], 'LOSNow', false, true,  categories.SUBCOMMANDER, true, ArmyBrains[UEF] )

    --Introduce our enemy
    Cinematics.EnterNISMode()
    ScenarioFramework.Dialogue(OpStrings.JJ2_Enemy_Intro, nil, true)
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M3_NIS_Cam1'), 3)
    ScenarioFramework.Dialogue(OpStrings.JJ2_NIS3_Intro1, nil, true)

    WaitSeconds(4)

    ForkThread(
        function()
            VisMarker3_1:Destroy()
            ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_NIS_Vis_Marker_1'), 110)
        end
    )

    Cinematics.ExitNISMode()

    ForkThread(M3)
end

function M3()
    M3FirebaseAI.M3PrisonFireBaseFunction()

    ScenarioInfo.M3P1 = Objectives.KillOrCapture(        
        'primary',                      -- type
        'incomplete',                   -- complete
        'Capture UEF Prison',  -- title
        'Commander, you need to free our men by capturing that prison. Do NOT destroy the structure!',  -- description
        {
            MarkUnits = true,
            Units = {ScenarioInfo.PrisonStructure},
        }
    )

    ScenarioInfo.M3P1:AddResultCallback(
        function(result)
            ForkThread(M4Intro)
        end
   )
end

function M4Intro()
    ScenarioFramework.Dialogue(OpStrings.JJ_Mission4_Intro, nil, true)
    ScenarioInfo.PrisonStructure:SetCanTakeDamage(true)
    ScenarioInfo.PrisonStructure:SetCanBeKilled(true)

    WaitSeconds(AllyVehicleSpawn[Difficulty])

    ScenarioInfo.Truck1 = ScenarioUtils.CreateArmyUnit('Player', 'truck_1')
    ScenarioInfo.Truck2 = ScenarioUtils.CreateArmyUnit('Player', 'truck_2')

    ScenarioInfo.TrucksDestroyed = 0

    ScenarioFramework.CreateUnitDeathTrigger(Truck, ScenarioInfo.Truck1)
    ScenarioFramework.CreateUnitDeathTrigger(Truck, ScenarioInfo.Truck2)
    ForkThread(M4)
end

function M4()
    ScenarioFramework.Dialogue(OpStrings.JJ_Mission4_Objective1, nil, true)

    -- Create an objective
    ScenarioInfo.M4P1 = Objectives.CategoriesInArea(
    'primary',
    'incomplete', 
    'Escort Ally Trucks',
    'Escord the trucks to the City. Ensure their safety. We CANNOT lose those Trucks Colonel.',
    'Move',
    {
        MarkUnits = true,
        MarkArea= true,
        ShowFaction = 'UEF',
        Requirements = {
            {Area = "M4_Objective_Area", Category = categories.uec0001, CompareOp = '>=', Value = 1, ArmyIndex = Player},
            {Area = "M4_Objective_Area", Category = categories.uec0001, CompareOp = '>=', Value = 1, ArmyIndex = Player},
        },
    }
    )

    ScenarioInfo.M4P2 = Objectives.Protect(
    'prmary',
    'incomplete',
    'Protect Ally Trucks',
    'If we lose those our allies then we cannot complete our main objective. You must ensure the protection of the Rebel Commanders.',
    Objectives.GetActionIcon('protect'),
        {
            MarkUnits = false,
        }
    )

    ScenarioInfo.M4P1:AddResultCallback(
        function(result)
            ScenarioInfo.M4P2:ManualResult(true)
            ScenarioFramework.Dialogue(OpStrings.JJ_M4Complete, nil, true)
        end
    )
end

function UEFAttackPlan()
    if (M1P1Done == false) then
    	ScenarioFramework.Dialogue(OpStrings.JJ2_M1_Secondary_Intro, nil, true)

        # Secondary Objective 1
        ScenarioInfo.M1S1 = Objectives.Basic(
            'secondary',                          # type
            'incomplete',                       # complete
            'Survive UEF Attack Waves',         # title
            'The UEF are sending attack waves at you. Survive by any means necessary.',          # description
            Objectives.GetActionIcon('kill'),   # action
            {
                ShowFaction = 'UEF',
            }                                  # target
        )
        ScenarioFramework.CreateTimerTrigger(StartUEFTransportAttacks, UEFAttackCoolDown[Difficulty])
    end
end

function StartUEFTransportAttacks()
    if (M1P1Done == false) then
        local allUnits = {}

        for i = 1, 3 do
            local transport = ScenarioUtils.CreateArmyUnit('UEF', 'M1_Transport')
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Transport_Units_D' .. Difficulty, 'AttackFormation')

            for _, v in units do
                table.insert(allUnits, v)
            end

            ScenarioFramework.AttachUnitsToTransports(units:GetPlatoonUnits(), {transport})
            WaitSeconds(0.5)
            IssueTransportUnload({transport}, ScenarioUtils.MarkerToPosition('M1_Transport_Unload_' .. i))

            IssueMove({transport}, ScenarioUtils.MarkerToPosition('M1_UEF_Transport_Remove'))
            ScenarioFramework.CreateUnitToMarkerDistanceTrigger(DestroyUnit, transport, 'M1_UEF_Transport_Remove', 20)

            units.PlatoonData = {}
            units.PlatoonData.PatrolChain = ('M1_Attack_Chain_' .. i)
            ScenarioPlatoonAI.PatrolThread(units)
        end

        ScenarioFramework.CreateTimerTrigger(UEFAmphibiousTankAttack, 75)
    end
end

function UEFAmphibiousTankAttack()
	if (M1P1Done == false) then
		local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Amphibious_Attack_Group_D' .. Difficulty, 'NoFormation')
		units.PlatoonData = {}
        units.PlatoonData.PatrolChain = 'M1_Attack_Chain_2'
        ScenarioPlatoonAI.PatrolThread(units)
		ScenarioFramework.CreateTimerTrigger(StartUEFTransportAttacks, 90)
	end
end

function MarkSupportCommanderOnVisible()
    ScenarioInfo.M3S1 = Objectives.KillOrCapture(        
    'secondary',                      -- type
    'incomplete',                   -- complete
    'Kill sCDR Maxwell',  -- title
    'Goodwyn has a Junior Commander guarding the prison, eliminate him.',  -- description
        {                               -- target
            Units = {ScenarioInfo.SupCommander}
        }
    )
    ScenarioInfo.M3S1:AddResultCallback(
        function(result)
            ScenarioFramework.Dialogue(OpStrings.JJ2_Maxwell_Death, nil, true)
        end
    )
end

function DestroyUnit(unit)
    unit:Destroy()
end

function Truck(truck)
    ScenarioInfo.TrucksDestroyed = ScenarioInfo.TrucksDestroyed + 1

    if ScenarioInfo.TrucksDestroyed >= 2 and ScenarioInfo.M4P2.Active then
        ScenarioFramework.PlayerLose(OpStrings.JJ_Mission4_Failed)
    end
end

function UEFAttackComplex()
    if HumanPlayerCounter >= 2 then
        ScenarioFramework.Dialogue(OpStrings.JJ_Mission3_Attack, nil, true)
    end
end

function ACUAtComplex()
    ScenarioFramework.Dialogue(OpStrings.JJ2_Fortify_Dialogue, nil, true)
    ScenarioInfo.M2S1:ManualResult(true)

    ScenarioInfo.M2S2 = Objectives.Protect(
    'secondary',
    'incomplete',
    'Fortify Complex',
    'Fortify the Complex so you are able to defend it in the event of any UEF attacks. Focus on AA Defenses and Point Defenses. You only have a limited amount of time.',
    Objectives.GetActionIcon('protect'),
        {
            Units = {ScenarioInfo.CityNode},
            MarkUnits = true,
        }
    )
end

function M1ReminderFirst()

end

function M1ReminderSecond()

end

function M1ReminderThird()
end

function M2ReminderFirst()

end

function M2ReminderSecond()

end

function M2ReminderThird()

end

function M3ReminderFirst()

end

function M3ReminderSecond()

end

function M3ReminderThird()

end

function M4ReminderFirst()
end

function M4ReminderSecond()

end

function M4ReminderThird()

end

function M5ReminderFirst()

end

function M5ReminderSecond()

end

function M5ReminderThird()

end

