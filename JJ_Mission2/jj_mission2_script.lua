local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local Cinematics = import('/lua/cinematics.lua')
local OpStrings = import('/maps/JJ_Mission2/jj_mission2_strings.lua')
local M1UEFPowerAI = import('/maps/JJ_Mission2/M1_UEF_Power_AI.lua')
local M2UEFNavyAI = import('/maps/JJ_Mission2/M2_UEF_Navy_AI.lua')
local M3FirebaseAI = import('/maps/JJ_Mission2/M3_UEF_Firebase_AI.lua')

---------
-- Globals
---------
ScenarioInfo.Player = 1
ScenarioInfo.UEF = 2
ScenarioInfo.NeutralUEF = 3
ScenarioInfo.Coop1 = 4
ScenarioInfo.Coop2 = 5
ScenarioInfo.Coop3 = 6

--------
-- Locals
--------
local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local NeutralUEF = ScenarioInfo.NeutralUEF
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

--------
-- Tables
--------
local HumanPlayers = {}
local AttackTriggerTimer = {600, 450, 300}
local UEFAttackCoolDown = {120, 85, 60}

function OnPopulate()
	ScenarioUtils.InitializeScenarioArmies()

	ScenarioFramework.SetUEFPlayerColor(Player)
	SetArmyColor('UEF', 133, 148, 255)
	SetArmyColor('NeutralUEF', 133, 148, 255)
end
  
function OnStart(self)
	-- Create a Trigger for scripted UEF attacks.
	ScenarioFramework.CreateTimerTrigger(UEFAttackPlan, AttackTriggerTimer[Difficulty])

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
	ScenarioFramework.SetPlayableArea('M1_Play_Area', false)
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

	local City = ScenarioUtils.CreateArmyGroup('NeutralUEF', 'City')

	local VisMarker2_1 = ScenarioFramework.CreateVisibleAreaLocation(45, ScenarioUtils.MarkerToPosition('M2_NIS_Vis_Marker_1'), 0, ArmyBrains[Player])
	Cinematics.EnterNISMode()
	WaitSeconds(1)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M2_NIS_Cam1'), 2)
	ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro, nil, true)
	if(HumanPlayerCounter == 2) then
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_1, nil, true)
	elseif(HumanPlayerCounter == 3) then
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_2, nil, true)
	elseif(HumanPlayerCounter == 4) then
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_3, nil, true)
	else
		ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_0, nil, true)
	end

	ScenarioFramework.Dialogue(OpStrings.JJ2_NIS2_Intro_Final, nil, true)
    WaitSeconds(3)
	Cinematics.ExitNISMode()

    VisMarker2_1:Destroy()

	ScenarioInfo.CityNode = ScenarioInfo.UnitNames[NeutralUEF]['CentralStation']
	ScenarioInfo.CityNode:SetCustomName("City Central Node")

    ForkThread(M2)
end

function M2()
    M2UEFNavyAI.M2NavyBaseFunction()

    if(ScenarioInfo.M1S1.Active) then
        ScenarioInfo.M1S1:ManualResult(true)
        ScenarioFramework.Dialogue(OpStrings.JJ2_M1S1_Complete, nil, true)
    end

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
                M3NISIntro()
            end
        end
   )

    ScenarioInfo.M2S1 = Objectives.Capture(
        'secondary',
        'incomplete',
        'Capture Civilian Complex',
        'There is a small Civilian Complex to the West. Capture it so we can house the prisoners.',
        {
            MarkUnits = true,
            Units = {ScenarioInfo.CityNode},
        }
    )

    ScenarioInfo.M2S1:AddResultCallback(
        function(result)
            for k, v in City do
                if(v and not v:IsDead()) then
                    ScenarioFramework.GiveUnitToArmy(v, Player)
                end
            end
        end
   )
end

function M3NISIntro()
    WaitSeconds(5)

    ScenarioInfo.Prison = ScenarioUtils.CreateArmyGroup('UEF', 'Prison')
    ScenarioInfo.Shields = ScenarioUtils.CreateArmyGroup('NeutralUEF', 'PrisonShields')

    local VisMarker3_1 = ScenarioFramework.CreateVisibleAreaLocation(20, ScenarioUtils.MarkerToPosition('M3_NIS_Vis_Marker_1'), 0, ArmyBrains[Player])

    for _, v in ScenarioInfo.Shields do
        v:ToggleScriptBit('RULEUTC_ShieldToggle')
    end

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

    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'Prison_Guards_' .. Difficulty, 'NoFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M3_Prison_Guard_Chain_1')))
    end

    ScenarioFramework.CreateArmyIntelTrigger(MarkSupportCommanderOnVisible, ArmyBrains[Player], 'LOSNow', false, true,  categories.SUBCOMMANDER, true, ArmyBrains[UEF] )

    --Introduce our enemy
    Cinematics.EnterNISMode()
    ScenarioFramework.Dialogue(OpStrings.JJ2_Enemy_Intro, nil, true)
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M3_NIS_Cam1'), 3)

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
        'Commander, you need to free our men by capturing that prison.',  -- description
        {
            MarkUnits = true,
            Units = {ScenarioInfo.PrisonStructure},
        }
    )

    ScenarioInfo.M3P1:AddResultCallback(
        function(result)
            WaitSeconds(4)
            ForkThread(M4)
        end
   )
end

function M4()

end

function M4UEFPrisonReCaptureFunction()

end

function M5()

end

function M6()

end

function M7()

end

function UEFCityAttacks()

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

