-- Custom Mission
-- Author: speed2

local Buff = import('/lua/sim/Buff.lua')
local Cinematics = import('/lua/cinematics.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local M2UEFAI = import('/maps/colony/colony_m2uefai.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local OpStrings = import('/maps/colony/colony_strings.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local TauntManager = import('/lua/TauntManager.lua')

----------
-- Globals
----------

-- Army IDs
ScenarioInfo.Player = 1
ScenarioInfo.UEF = 2
ScenarioInfo.Civilian = 3
ScenarioInfo.Cybran = 4
ScenarioInfo.Coop1 = 5
ScenarioInfo.Coop2 = 6
ScenarioInfo.Coop3 = 7
ScenarioInfo.HumanPlayers = {}

---------
-- Locals
---------
local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local Civilian = ScenarioInfo.Civilian
local Cybran = ScenarioInfo.Cybran
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3

local AssignedObjectives = {}
local Difficulty = ScenarioInfo.Options.Difficulty

--------------
-- Debug only!
--------------
local SkipNIS2 = false

local SpawnM2Attackers = true
local Debug = false

-----------------
-- Taunt Managers
-----------------
-- local UEFACU = TauntManager.CreateTauntManager('UEFACUTM', '/maps/colony/colony_strings.lua')

-----------
-- Prologue
-----------
function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()

    ScenarioInfo.MissionNumber = 1

    -- Sets Army Colors
    ScenarioFramework.SetArmyColor(Player, 144, 20, 39)
	ScenarioFramework.SetUEFPlayerColor(UEF)
    ScenarioFramework.SetNeutralColor(Civilian)
    ScenarioFramework.SetCybranEvilColor(Cybran)

    local colors = {
        ['Coop1'] = {132, 10, 10}, 
        ['Coop2'] = {47, 79, 79}, 
        ['Coop3'] = {46, 139, 87}
    }
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end

    -- Provide vision over Player's base
    ScenarioInfo.M1_Viz_Marker = ScenarioFramework.CreateVisibleAreaLocation( 50, ScenarioUtils.MarkerToPosition( 'M1_Viz_Marker' ), 0, ArmyBrains[Player] )
    
    -- Unit cap
    --SetArmyUnitCap(UEF, 1000)

    -- Spawn Player initial base damaged a bit, and sACU with upgrades
    ScenarioInfo.PlayerBase = ScenarioUtils.CreateArmyGroup('Player', 'M1_Player_Base')
    for k, v in ScenarioInfo.PlayerBase do
        v:AdjustHealth(v, Random(0, v:GetHealth()/3) * -ScenarioInfo.Options.Difficulty)
    end

    ScenarioInfo.Player_sACU = ScenarioUtils.CreateArmyUnit('Player', 'Player_sACU')
    ScenarioInfo.Player_sACU:CreateEnhancement('FocusConvertor')
    ScenarioInfo.Player_sACU:CreateEnhancement('SelfRepairSystem')
    ScenarioInfo.Player_sACU:CreateEnhancement('Switchback')
    ScenarioFramework.CreateUnitDeathTrigger(sACUDead, ScenarioInfo.Player_sACU)
    IssueAggressiveMove({ScenarioInfo.Player_sACU}, ScenarioUtils.MarkerToPosition('M1 Player Units Marker 14'))

    ForkThread(SpawnPlayerBase)
    ----------------
    -- Initial Units
    ----------------
    -- Player
    for i = 1, 2 do
        local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M1_Bots_' .. i, 'GrowthFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M1_Player_Loyalist_Chain_' ..i)

        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M1_Mobile_Flak_' .. i, 'GrowthFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M1_Player_Flak_Chain_' .. i)
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M1_Rhinos', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M1_Player_Rhino_Chain')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M1_Air_Patrol', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Player_Air_Def_Chain')))
    end

    -- Cybran reinforcements
    ForkThread(CybranReinforcements)

    -- UEF

    -- Base that provide intel and energy for shields
    ScenarioInfo.M1_UEF_Intel_Base = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Intel')

    -- Attacks
    ForkThread(UEFAttacks)
    -----------------------
    -- Objective Structures
    -----------------------
    ScenarioInfo.M1_Civilian_Buildings = ScenarioUtils.CreateArmyGroup('Civilian', 'M1_Civ_Buildings')
    for k,v in ScenarioInfo.M1_Civilian_Buildings do
        v:SetCapturable(false)
        v:SetReclaimable(false)
    end
end

function SpawnPlayerBase()
    -- Make factories build some units and support factories assist HQ
    local land = {'xrl0305', 'url0303', 'url0202', 'url0205'}
    local air = {'ura0102', 'ura0203', 'dra0202', 'ura0102'}
    local landPlatoon = {'', '',}
    local airPlatoon = {'', '',}
    for i = 1, 4 do
        table.insert(landPlatoon, {land[i], 5, 5, 'attack', 'AttackFormation'})
        table.insert(airPlatoon, {air[i], 5, 5, 'attack', 'AttackFormation'})
    end
    local AirFactories = ArmyBrains[Player]:GetListOfUnits(categories.urb0202, false)
    local T3landFactories = ArmyBrains[Player]:GetListOfUnits(categories.urb0301, false)
    local T2landFactories = ArmyBrains[Player]:GetListOfUnits(categories.zrb9501, false)
    IssueClearFactoryCommands(T2landFactories)
    IssueClearFactoryCommands(T3landFactories)
    IssueClearFactoryCommands(AirFactories)
    IssueFactoryRallyPoint(AirFactories, ScenarioUtils.MarkerToPosition('M1 Player Air Factory Rally'))
    IssueFactoryRallyPoint(T3landFactories, ScenarioUtils.MarkerToPosition('M1 Player Land Factory Rally'))
    ArmyBrains[Player]:BuildPlatoon(landPlatoon, T3landFactories, 1)
    ArmyBrains[Player]:BuildPlatoon(airPlatoon, AirFactories, 1)
    IssueFactoryAssist({ScenarioInfo.UnitNames[Player]['T2_Land_Fac_1']}, T3landFactories[1])
    IssueFactoryAssist({ScenarioInfo.UnitNames[Player]['T2_Land_Fac_2']}, T3landFactories[1])
    IssueFactoryAssist({ScenarioInfo.UnitNames[Player]['T3_Land_Fac_2']}, T3landFactories[1])
    IssueFactoryAssist({ScenarioInfo.UnitNames[Player]['T3_Land_Fac_3']}, T3landFactories[1])

    -- Engies assisting factories
    IssueGuard({ScenarioInfo.UnitNames[Player]['T3_Engie']}, T3landFactories[1])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T3_Engie_2']}, ScenarioInfo.UnitNames[Player]['T3_Land_Fac_2'])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T3_Engie_3']}, ScenarioInfo.UnitNames[Player]['T3_Land_Fac_3'])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T2_Engie_Land_1']}, T2landFactories[1])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T2_Engie_Land_2']}, T2landFactories[1])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T2_Engie_Land_3']}, T2landFactories[2])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T2_Engie_Land_4']}, T2landFactories[2])
    IssueGuard({ScenarioInfo.UnitNames[Player]['T2_Engie_Air']}, AirFactories[1])
    -- Reclaiming Engies
    local T1_Engies = ArmyBrains[Player]:GetListOfUnits(categories.url0105, false)
    for i = 1, 4 do
        IssueAggressiveMove({T1_Engies[i]}, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(0,3)))
    end
end

function CybranReinforcements()
    WaitSeconds(40)
    local route = 1

    if ScenarioInfo.MissionNumber == 1 then
        ScenarioFramework.Dialogue(OpStrings.M1_Reinforcements, nil, false)
        -- Spawn air units and set them on patrol in front of Player's base
        for i = 1, 2 do
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_Inties_' .. i, 'AttackFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Player_Loyalist_Chain_2')))
            end
            units = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_Gunships_' .. i, 'AttackFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_Player_Loyalist_Chain_1')))
            end
        end
        -- Spawn land units on transports (6 groups), drop them in front of Player's base and set then on attack move
        ScenarioFramework.CreateAreaTrigger(DestroyUnit, ScenarioUtils.AreaToRect('M1_TransportDeath_Area'), categories.ura0104, false, false, ArmyBrains[Cybran])
        while route <= 6 do
            local landPlatoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_Units_' .. route, 'AttackFormation')
            local transport = ScenarioUtils.CreateArmyGroup('Cybran', 'M1_Transports')
            ScenarioFramework.AttachUnitsToTransports(landPlatoon:GetPlatoonUnits(), transport)
            IssueTransportUnload(transport, ScenarioUtils.MarkerToPosition('CybranLand_Marker 0' .. Random(0, 3)))
            IssueMove(transport, ScenarioUtils.MarkerToPosition('TransportDeath'))
            for k, v in landPlatoon:GetPlatoonUnits() do
                IssueAggressiveMove({v}, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(0,3)))
            end
            route = route + 1
            WaitSeconds(Random(1, 2))
        end
    end
end

function UEFAttacks()
    -- Attacks that doesnt respawn
    -- Land
    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Titans_' .. i, 'GrowthFormation')
    end
    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Titans_3')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 00'))
    
    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Titans_4')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 03'))

    ScenarioUtils.CreateArmyGroup('UEF', 'M1_Pillars_1')
    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Pillars_2')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(1,2)))

    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Percies_1')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,1)))

    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Percies_2')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(2,3)))

    -- Air
    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Inties_1')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,3)))

    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Gunships_1')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,3)))

    -- Off map attacks, 3 times, only during prologue
    ForkThread(
        function()
            local UEF_Init_Attack = 1
            while UEF_Init_Attack < 4 do
                WaitSeconds(20)
                if ScenarioInfo.MissionNumber == 1 then
                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Percies_3_1')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(0,1)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,1)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Percies_4_1')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(2,3)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(2,3)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Units_1_1')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(0,1)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,1)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Units_2_1')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(2,3)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(2,3)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Inties_2_1')
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,3)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Gunships_2_1')
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,3)))

                    WaitSeconds(25)

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Percies_3_2')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(0,1)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,1)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Percies_4_2')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(2,3)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(2,3)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Units_1_2')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(0,1)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,1)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Units_2_2')
                    IssueMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Travel Marker 0' .. Random(2,3)))
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(2,3)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Inties_2_2')
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,3)))

                    units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Gunships_2_2')
                    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M1 UEF Attack Marker 0' .. Random(0,3)))

                    WaitSeconds(20)
                    UEF_Init_Attack = UEF_Init_Attack + 1
                end
            end
        end
    )
end

function OnStart(scenario)
    -- Build Restrictions
    for _, Player in ScenarioInfo.HumanPlayers do
         ScenarioFramework.AddRestriction(Player, categories.EXPERIMENTAL - categories.url0402 + categories.GATE + categories.SUBCOMMANDER)
    end
    
    -- Lock off cdr upgrades
    --[[
    for _, Player in ScenarioInfo.HumanPlayers do
    	ScenarioFramework.RestrictEnhancements({'ResourceAllocation',
                                            	'DamageStablization',
                                            	'AdvancedEngineering',
                                            	'T3Engineering',
                                            	'HeavyAntiMatterCannon',
                                            	'LeftPod',
                                            	'RightPod',
                                            	'Shield',
                                            	'ShieldGeneratorField',
                                            	'TacticalMissile',
                                            	'TacticalNukeMissile',
                                            	'Teleporter'})
    end
    ]]--

    ScenarioFramework.SetPlayableArea('M1_Area', false)
    ScenarioFramework.StartOperationJessZoom('sACUZoom', IntroMission1)
    --[[
    -- Only for video preview
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Preview_1'), 0)
    ForkThread(IntroMission1)
    ForkThread(function()
            Cinematics.EnterNISMode()
            Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Preview_1'), 0)
            WaitSeconds(5)
            Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Preview_2'), 22)
            Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Preview_3'), 22)
            Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Preview_4'), 22)
            Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_Preview_5'), 22)
        end
    )
    ]]--
end

function DestroyUnit(unit)
    unit:Destroy()
end

---------------------
-- Win/Lose Functions
---------------------
function PlayerWin()
end

function PlayerDeath()
end

function PlayerLose()
end

------------------------
-- Mission 1 in Prologue
------------------------
function IntroMission1()
    -- Give some resources to player
    ArmyBrains[Player]:GiveResource('MASS', 3000)
    ArmyBrains[Player]:GiveResource('ENERGY', 25000)
    
    ForkThread(StartMission1) -- Assign objective right away
    ScenarioFramework.Dialogue(OpStrings.M1_DefendCivs, nil, true)
end

function StartMission1()
    ------------------------------------------
    -- Primary Objective 1 - Protect Civilians
    ------------------------------------------
    ScenarioInfo.M1P1 = Objectives.Protect(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Defend Colony',                 -- title
        'Defend civilian city.',         -- description
        {                               -- target
            Units = ScenarioInfo.M1_Civilian_Buildings,
            NumRequired = math.ceil(table.getn(ScenarioInfo.M1_Civilian_Buildings)/1.25),
        }
   )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(not result and ScenarioInfo.Player_sACU:IsDead()) then
                IntroMission2()
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M1P1)
    -- CreateMessageBox('Prologue')
    -- Tabs.TabAnnouncement('diplomacy', 'Prologue')
end

function sACUDead()
    if not (ScenarioInfo.M1P1.Active) then
        ScenarioFramework.Dialogue(OpStrings.M1_sACU_Dead, IntroMission2, true)
        IntroMission2()
    else
        ScenarioFramework.Dialogue(OpStrings.M1_sACU_Dead, nil, true)
    end
end

---------------------
-- Mission 2 (2x ACU)
---------------------
function IntroMission2()
    ScenarioInfo.MissionNumber = 2

    ForkThread(
        function()
            -- Spawn Player Base
            ScenarioInfo.M2_PlayerBase = ScenarioUtils.CreateArmyGroup('Player', 'M2_Player_Base_D' .. Difficulty)
            for k, v in ScenarioInfo.M2_PlayerBase do
                v:AdjustHealth(v, Random(0, v:GetHealth()/3) * -ScenarioInfo.Options.Difficulty)
            end
            -- Wreckaged parts of the base
            if Difficulty == 2 then
                ScenarioUtils.CreateArmyGroup('Player', 'M2_Player_Base_Easy', true)
            elseif Difficulty == 3 then
                ScenarioUtils.CreateArmyGroup('Player', 'M2_Player_Base_Easy', true)
                ScenarioUtils.CreateArmyGroup('Player', 'M2_Player_Base_Medium', true)
            end
            ------
            -- UEF
            ------
            M2UEFAI.UEFM2MainBaseAI()
            M2UEFAI.UEFM2FireBaseNorthAI()
            M2UEFAI.UEFM2FireBaseSouthAI()
            ArmyBrains[UEF]:PBMSetCheckInterval(6)

            -- Main Base Defences
            ScenarioUtils.CreateArmyGroup('UEF', 'M2_3x_Fire_Base_D' .. Difficulty)

            -- T3 Arty for objective, make arty shoot offmap
            ScenarioInfo.UEF_T3_Arty = ScenarioUtils.CreateArmyGroup('UEF', 'M2_Arty')
            for i = 1, 2 do
                IssueClearCommands(ScenarioInfo.UEF_T3_Arty[i])
                IssueAttack({ScenarioInfo.UEF_T3_Arty[i]}, ScenarioUtils.MarkerToPosition('M2_Arty_Target'))
            end

            -- Tactical Missile Launchers
            ScenarioFramework.CreateTimerTrigger(ActivateUEFTMLs, 5*60)

            -- Extra Eco for AI
            if Difficulty > 1 then
                ScenarioUtils.CreateArmyGroup('UEF', 'M2_UEF_Extra_Eco')
            end

            -- Walls
            ScenarioUtils.CreateArmyGroup('UEF', 'M2_UEF_Walls')

            -----------------------
            -- Objective Structures
            -----------------------
            ScenarioInfo.M2_Civilian_Buildings = ScenarioUtils.CreateArmyGroup('Civilian', 'M2_Civ_Buildings')
            for k,v in ScenarioInfo.M2_Civilian_Buildings do
                v:SetCapturable(false)
                v:SetReclaimable(false)
            end

            -- Give player and AI some mass into storages
            local mass = {4000, 3000, 2000}
            ArmyBrains[Player]:GiveResource('MASS', mass[Difficulty])
            ArmyBrains[UEF]:GiveResource('MASS', 30000)

            ForkThread(IntroMission2NIS)
        end
    )
end

function IntroMission2NIS()
    ScenarioFramework.SetPlayableArea('Cam_Move_Area', false)
    -- No more vision over first base
    ScenarioInfo.M1_Viz_Marker:Destroy()

    if not SkipNIS2 then
        Cinematics.EnterNISMode()
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_1'), 0)
        WaitSeconds(2)
        
        ScenarioFramework.Dialogue(OpStrings.M2_Intro_1, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_2'), 6)
        ForkThread(DestroyM1Units)
        ScenarioFramework.Dialogue(OpStrings.M2_Intro_2, nil, true)

        -- spawn coop players 1 and 3, using ForkThread so camera isnt waiting for them to spawn 
        ForkThread(
            function()
                ScenarioInfo.CoopCDR = {}
                local tblArmy = ListArmies()
                if tblArmy[ScenarioInfo.Coop1] then
                    ScenarioInfo.CoopCDR1 = ScenarioUtils.CreateArmyUnit('Coop1', 'Player_ACU')
                    ScenarioInfo.CoopCDR1:CreateEnhancement('AdvancedEngineering')
                    ScenarioInfo.CoopCDR1:CreateEnhancement('ResourceAllocation')
                    ScenarioInfo.CoopCDR1:SetCustomName(ArmyBrains[Coop1].Nickname)
                    ScenarioInfo.CoopCDR1:PlayCommanderWarpInEffect()
                    WaitSeconds(2.5)
                    ScenarioInfo.CoopCDR1:ShowBone('Back_Upgrade', true)
                    ScenarioInfo.CoopCDR1:ShowBone('Right_Upgrade', true)
                end
                if tblArmy[ScenarioInfo.Coop3] then
                    ScenarioInfo.CoopCDR3 = ScenarioUtils.CreateArmyUnit('Coop3', 'Player_sACU')
                    ScenarioInfo.CoopCDR3:CreateEnhancement('ResourceAllocation')
                    ScenarioInfo.CoopCDR3:CreateEnhancement('Switchback')
                    ScenarioInfo.CoopCDR3:SetCustomName(ArmyBrains[Coop3].Nickname)
                    PlaySACUWarpInEffect(ScenarioInfo.CoopCDR3)
                    ArmyBrains[Coop3]:GiveStorage('MASS', 1000)
                    ArmyBrains[Coop3]:GiveResource('MASS', 1000)
                elseif tblArmy[ScenarioInfo.Coop1] then
                    ScenarioInfo.Coop1_sACU = ScenarioUtils.CreateArmyUnit('Coop1', 'Coop1_sACU')
                    ScenarioInfo.Coop1_sACU:CreateEnhancement('ResourceAllocation')
                    ScenarioInfo.Coop1_sACU:CreateEnhancement('Switchback')
                    PlaySACUWarpInEffect(ScenarioInfo.Coop1_sACU)
                    ArmyBrains[Coop1]:GiveStorage('MASS', 1000)
                    ArmyBrains[Coop1]:GiveResource('MASS', 1000)
                end
            end
        )
        WaitSeconds(5)
        -- Spawning units that fight now.
        if SpawnM2Attackers then
            ForkThread(SpawnM2AttackingUnits)
        end
        
        ScenarioFramework.Dialogue(OpStrings.M2_Intro_3, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_3'), 4)
        WaitSeconds(3)

        -- Spawn player and coop player 2, using ForkThread so camera isnt waiting for them to spawn
        ForkThread(
            function()
                ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'Player_ACU')
                ScenarioInfo.PlayerCDR:CreateEnhancement('CoolingUpgrade')
                ScenarioInfo.PlayerCDR:CreateEnhancement('StealthGenerator')
                ScenarioInfo.PlayerCDR:SetCustomName(ArmyBrains[Player].Nickname)
                ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
                WaitSeconds(2.5)
                ScenarioInfo.PlayerCDR:ShowBone('Back_Upgrade', true)
                ScenarioInfo.PlayerCDR:ShowBone('Right_Upgrade', true)
                ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
                ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.PlayerCDR)

                local tblArmy = ListArmies()
                if tblArmy[ScenarioInfo.Coop2] then
                    ScenarioInfo.CoopCDR2 = ScenarioUtils.CreateArmyUnit('Coop2', 'Player_sACU')
                    ScenarioInfo.CoopCDR2:CreateEnhancement('StealthGenerator')
                    ScenarioInfo.CoopCDR2:CreateEnhancement('FocusConvertor')
                    ScenarioInfo.CoopCDR2:CreateEnhancement('EMPCharge')
                    ScenarioInfo.CoopCDR2:SetCustomName(ArmyBrains[Coop2].Nickname)
                    PlaySACUWarpInEffect(ScenarioInfo.CoopCDR2)
                    ArmyBrains[Coop2]:GiveStorage('MASS', 1000)
                    ArmyBrains[Coop2]:GiveResource('MASS', 1000)  
                else
                    ScenarioInfo.M2_Player_sACU = ScenarioUtils.CreateArmyUnit('Player', 'M2_Player_sACU')
                    ScenarioInfo.M2_Player_sACU:CreateEnhancement('StealthGenerator')
                    ScenarioInfo.M2_Player_sACU:CreateEnhancement('FocusConvertor')
                    ScenarioInfo.M2_Player_sACU:CreateEnhancement('EMPCharge')
                    PlaySACUWarpInEffect(ScenarioInfo.M2_Player_sACU)
                end

                for index, coopACU in ScenarioInfo.CoopCDR do
                    ScenarioFramework.PauseUnitDeath(coopACU)
                    ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, coopACU)
                end
            end
        )
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_4'), 3)
        ScenarioFramework.Dialogue(OpStrings.M2_Intro_4, nil, true)

        Cinematics.ExitNISMode()
    else
        ForkThread(DestroyM1Units)
        -- spawn coop players 1 and 3
        ScenarioInfo.CoopCDR = {}
        local tblArmy = ListArmies()
        if tblArmy[ScenarioInfo.Coop1] then
            ScenarioInfo.CoopCDR1 = ScenarioUtils.CreateArmyUnit('Coop1', 'Player_ACU')
            ScenarioInfo.CoopCDR1:CreateEnhancement('AdvancedEngineering')
            ScenarioInfo.CoopCDR1:CreateEnhancement('ResourceAllocation')
            ScenarioInfo.CoopCDR1:SetCustomName(ArmyBrains[Coop1].Nickname)
            ScenarioInfo.CoopCDR1:PlayCommanderWarpInEffect()
            WaitSeconds(2.5)
            ScenarioInfo.CoopCDR1:ShowBone('Back_Upgrade', true)
            ScenarioInfo.CoopCDR1:ShowBone('Right_Upgrade', true)
        end
        if tblArmy[ScenarioInfo.Coop3] then
            ScenarioInfo.CoopCDR3 = ScenarioUtils.CreateArmyUnit('Coop3', 'Player_sACU')
            ScenarioInfo.CoopCDR3:CreateEnhancement('ResourceAllocation')
            ScenarioInfo.CoopCDR3:CreateEnhancement('Switchback')
            ScenarioInfo.CoopCDR3:SetCustomName(ArmyBrains[Coop3].Nickname)
            PlaySACUWarpInEffect(ScenarioInfo.CoopCDR3)
            ArmyBrains[Coop3]:GiveStorage('MASS', 1000)
            ArmyBrains[Coop3]:GiveResource('MASS', 1000)
        elseif tblArmy[ScenarioInfo.Coop1] then
            ScenarioInfo.Coop1_sACU = ScenarioUtils.CreateArmyUnit('Coop1', 'Coop1_sACU')
            ScenarioInfo.Coop1_sACU:CreateEnhancement('ResourceAllocation')
            ScenarioInfo.Coop1_sACU:CreateEnhancement('Switchback')
            PlaySACUWarpInEffect(ScenarioInfo.Coop1_sACU)
            ArmyBrains[Coop1]:GiveStorage('MASS', 1000)
            ArmyBrains[Coop1]:GiveResource('MASS', 1000)
        end

        if SpawnM2Attackers then
            ForkThread(SpawnM2AttackingUnits)
        end
        -- Spawn player and coop player 2
        ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'Player_ACU')
        ScenarioInfo.PlayerCDR:CreateEnhancement('CoolingUpgrade')
        ScenarioInfo.PlayerCDR:CreateEnhancement('StealthGenerator')
        ScenarioInfo.PlayerCDR:SetCustomName(ArmyBrains[Player].Nickname)
        ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
        WaitSeconds(2.5)
        ScenarioInfo.PlayerCDR:ShowBone('Back_Upgrade', true)
        ScenarioInfo.PlayerCDR:ShowBone('Right_Upgrade', true)
        ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
        ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.PlayerCDR)

        local tblArmy = ListArmies()
        if tblArmy[ScenarioInfo.Coop2] then
            ScenarioInfo.CoopCDR2 = ScenarioUtils.CreateArmyUnit('Coop2', 'Player_sACU')
            ScenarioInfo.CoopCDR2:CreateEnhancement('StealthGenerator')
            ScenarioInfo.CoopCDR2:CreateEnhancement('FocusConvertor')
            ScenarioInfo.CoopCDR2:CreateEnhancement('EMPCharge')
            ScenarioInfo.CoopCDR2:SetCustomName(ArmyBrains[Coop2].Nickname)
            PlaySACUWarpInEffect(ScenarioInfo.CoopCDR2)
            ArmyBrains[Coop2]:GiveStorage('MASS', 1000)
            ArmyBrains[Coop2]:GiveResource('MASS', 1000)  
        else
            ScenarioInfo.M2_Player_sACU = ScenarioUtils.CreateArmyUnit('Player', 'M2_Player_sACU')
            ScenarioInfo.M2_Player_sACU:CreateEnhancement('StealthGenerator')
            ScenarioInfo.M2_Player_sACU:CreateEnhancement('FocusConvertor')
            ScenarioInfo.M2_Player_sACU:CreateEnhancement('EMPCharge')
            PlaySACUWarpInEffect(ScenarioInfo.M2_Player_sACU)
        end

        for index, coopACU in ScenarioInfo.CoopCDR do
            ScenarioFramework.PauseUnitDeath(coopACU)
            ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, coopACU)
        end
    end

    ScenarioFramework.SetPlayableArea('M2_Area', false)

    StartMission2()
end

function PlaySACUWarpInEffect (self)
    self:HideBone(0, true)
    self:SetUnSelectable(true)
    self:SetBusy(true)
    self:SetBlockCommandQueue(true)
    self:ForkThread(SACUWarpInEffectThread(self))
end

function SACUWarpInEffectThread (self)
    self:PlayUnitSound('CommanderArrival')
    self:CreateProjectile( '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
    WaitSeconds(2.1)
    --self:SetMesh('/units/url0001/URL0001_PhaseShield_mesh', true)
    self:ShowBone(0, true)
    self:HideBone('AA_Gun', true)
    --self:HideBone('Power_Pack', true)
    --self:HideBone('Rez_Protocol', true)
    --self:HideBone('Torpedo', true)
    --self:HideBone('Turbine', true)
    self:SetUnSelectable(false)
    self:SetBusy(false)
    self:SetBlockCommandQueue(false)

    local totalBones = self:GetBoneCount() - 1
    local army = self:GetArmy()
    for k, v in EffectTemplate.UnitTeleportSteam01 do
        for bone = 1, totalBones do
            CreateAttachedEmitter(self,bone,army, v)
        end
    end

    --WaitSeconds(6)
    --self:SetMesh(self:GetBlueprint().Display.MeshBlueprint, true)
end

function SpawnM2AttackingUnits()
    -- Player's units
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M2_Air_Patrol', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Player_Air_Def_Chain')))
    end
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M2_Loyalist', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Player_Land_Def_Chain')
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M2_Brick', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Player_Land_Def_Chain')
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M2_Rhino', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Player_Land_Def_Chain')
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'M2_Banger', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_Player_Flak_Def_Chain')

    -- UEF Units
    units = ScenarioUtils.CreateArmyGroup('UEF', 'M2_Initial_Land')
    IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('Hydrocarbon 00'))

    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroup('UEF', 'M2_Initial_Air_' .. i)
        IssueAggressiveMove(units, ScenarioUtils.MarkerToPosition('M2_Air_Target_' .. i))

        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Bombers_1_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)

        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Scouts_1_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Striker_1_1_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_1')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Striker_1_2_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_2')

    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Lobo_1_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Flapjack_1_1_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_1')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Flapjack_1_3_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_3')

    for i = 1, 3 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Pillar_1_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Stinger_1_1_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_1')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Stinger_1_3_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_3')

    for i = 1, 3 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Titan_1_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)
    end
    --[[
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Demolisher_1_1_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_1')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Demolisher_1_3_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_3')

    for i = 1, 3 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Percival_1_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)
    end
    ]]--
    for i = 1, 3 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Pillar_2_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)

        units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_Titan_2_' .. i .. '_D' .. Difficulty, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEF_Initial_Attack_Chain_' ..i)
    end
end

function DestroyM1Units()
    local units = GetUnitsInRect(ScenarioUtils.AreaToRect('M1_Area'))
    --[[
    local id = unit:GetUnitId()
        if not string.find( id, "urc19" ) and not string.find( id, "uec19" ) then
            unit:Kill()
        end
    ]]--
    for k, v in units do
        v:Kill()
    end
end

function ActivateUEFTMLs()
    for k,unit in ArmyBrains[UEF]:GetListOfUnits(categories.ueb2108, false) do
        local plat = ArmyBrains[UEF]:MakePlatoon('', '')
        ArmyBrains[UEF]:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'NoFormation')
        plat:ForkAIThread(plat.TacticalAI)
    end
end

function StartMission2()
    ScenarioFramework.Dialogue(OpStrings.M2_KillAttackers, nil, true)
    ------------------------------------------------
    -- Primary Objective 2 - Defeat Attacking Forces
    ------------------------------------------------
    ScenarioInfo.M2P1 = Objectives.Basic(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Defeat UEF attacking forces',  -- title
        'Something',  -- description
        Objectives.GetActionIcon('kill'),   -- action
        {                               -- target
            ShowFaction = UEF,
        }
    )
    ScenarioInfo.M2P1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.M2_KillArty, KillArtyObjective, true)
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P1)

    ScenarioFramework.CreateTimerTrigger(M2_Subplot, 2*60)
    ScenarioFramework.CreateTimerTrigger(ObjectiveDone, 5*60)

    ------------------------------------------
    -- Primary Objective 3 - Protect Civilians
    ------------------------------------------
    ScenarioInfo.M2P2 = Objectives.Protect(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Defend Colony',                 -- title
        '80 % of civilian cities must survive.',         -- description
        {                               -- target
            Units = ScenarioInfo.M2_Civilian_Buildings,
            NumRequired = math.ceil(table.getn(ScenarioInfo.M2_Civilian_Buildings)/1.25),
            PercentProgress = true,
        }
   )
    ScenarioInfo.M2P2:AddResultCallback(
        function(result)
            if(not result) then
                PlayerLose()
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M2P2)
    -- Triggers for UEF to build Fatboys if players have Monkey Lords
    CreateAreaTrigger(M2UEFAI.UEFM2MainBaseExperimentalAttacks1, ScenarioUtils.AreaToRect('M2_Area'), categories.url0402, true, false, 1, false)
    CreateAreaTrigger(M2UEFAI.UEFM2MainBaseExperimentalAttacks2, ScenarioUtils.AreaToRect('M2_Area'), categories.url0402, true, false, 3, false)

    --local test = ScenarioFramework.GetCatUnitsInArea(categories.urb1101, 'M2_Area', ArmyBrains[Player])
    --LOG("GetCatUnitsInArea " .. test)
    --local test2 = ArmyBrains[Player]:GetListOfUnits(categories.urb1101, false)
    --LOG("GetListOfUnits false " .. test2)
    --local test3 = ArmyBrains[Player]:GetListOfUnits(categories.urb1101, true)
    --LOG("GetListOfUnits true " .. test3)

    --logTable(ArmyBrains[Player]:GetListOfUnits(categories.urb1106, false) or {} , "")
    --for i, v in ArmyBrains[Player]:GetListOfUnits(categories.urb1101, true) or {} do 
        --v:SetName("this unit is number "..i) 
    --end
end

function M2_Subplot()
    ScenarioFramework.Dialogue(M2_Subplot_1, nil, true)
end

function ObjectiveDone()
    ScenarioInfo.M2P1:ManualResult(true)
end

function KillArtyObjective()
    ----------------------------------
    -- Primary Objective 4 - Kill Arty
    ----------------------------------
    ScenarioInfo.M2P3 = Objectives.KillOrCapture(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Kill UEF Heavy Artillery Installations',  -- title
        'UEF is using heavy artilleries to bombard our colony. Kill the artilleries as fast as you can.',  -- description
        {                               -- target
            FlashVisible = true,
            MarkUnits = true,
            Units = ScenarioInfo.UEF_T3_Arty,
        }
    )
    ScenarioInfo.M2P3:AddResultCallback(
        function(result)
            if(result) then
                ScenarioInfo.M2P4:ManualResult(false)
                IntroMission3()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P3)

    -----------------------------------
    -- Primary Objective 1 - Arty Timer
    -----------------------------------
    ScenarioInfo.M2P4 = Objectives.Timer(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Kill UEF Heavy Artillery Installations',  -- title
        'Kill the artilleries before the whole city is destroyed.',  -- description
        {                               -- target
            Timer = 45*60,
            ExpireResult = 'failed',
        }
   )
    ScenarioInfo.M2P4:AddResultCallback(
        function(result)
            if(result) then
                PlayerLose()
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M2P4)

    -- Trigger to target player's T3 arty if he builds one, because we are evil. (Better than restricting it)
    CreateAreaTrigger(ArtyTargetPlayer, ScenarioUtils.AreaToRect('M2_Area'), categories.urb2302, true, false, 1, false)
end

function ArtyTargetPlayer()
    LOG("UEF T3 Arties are targeting player arty")
    local num = 1
    local Player_Arty = ArmyBrains[Player]:GetListOfUnits(categories.urb2302, false)

    if ScenarioInfo.M2P3.Active then
        for i = 1, 2 do
            IssueClearCommands(ScenarioInfo.UEF_T3_Arty[i])
            IssueAttack({ScenarioInfo.UEF_T3_Arty[i]}, Player_Arty[num])
        end

        ScenarioFramework.CreateUnitDeathTrigger(TargetCiviliansAgain, Player_Arty[num])
        num = num + 1
    end
end

function TargetCiviliansAgain()
    LOG("UEF T3 Arties are shooting back on civilians")
    ForkThread(
        function()
            if ScenarioInfo.M2P3.Active then
                for i = 1, 2 do
                    IssueClearCommands(ScenarioInfo.UEF_T3_Arty[i])
                    IssueAttack({ScenarioInfo.UEF_T3_Arty[i]}, ScenarioUtils.MarkerToPosition('M2_Arty_Target'))
                end

                WaitSeconds(10)
                CreateAreaTrigger(ArtyTargetPlayer, ScenarioUtils.AreaToRect('M2_Area'), categories.urb2302, true, false, 1, false)
            end
        end
    )
end

------------
-- Mission 3
------------
function IntroMission3()
end

-------------------
-- Custom functions
-------------------
function EngineerBuildUnit( army, unit, ... )
    local engUnit = unit
    local aiBrain = engUnit:GetAIBrain()
    for k,v in arg do
        if k != 'n' then
            local unitData = ScenarioUtils.FindUnit(v, Scenario.Armies[army].Units)
            if not unitData then
                WARN('*WARNING: Invalid unit name ' .. v)
            end
            if unitData and aiBrain:CanBuildStructureAt( unitData.type, unitData.Position ) then
                aiBrain:BuildStructure( engUnit, unitData.type, { unitData.Position[1], unitData.Position[3], 0}, false)
            end
        end
    end
end

-- EngineerBuildUnit('Player', ScenarioInfo.Player_sACU, 'PD_to_built') -- name of the units in save.lua

function CreateAreaTrigger(callbackFunction, rectangle, category, onceOnly, invert, number, requireBuilt)
    return ForkThread(AreaTriggerThread, callbackFunction, {rectangle}, category, onceOnly, invert, number, requireBuilt)
end

function AreaTriggerThread(callbackFunction, rectangleTable, category, onceOnly, invert, number, requireBuilt, name)
    local recTable = {}
    for k,v in rectangleTable do
        if type(v) == 'string' then
            table.insert(recTable,ScenarioUtils.AreaToRect(v))
        else
            table.insert(recTable, v)
        end
    end
    while true do
        local amount = 0
        local totalEntities = {}
        for k, v in recTable do
            local entities = GetUnitsInRect( v )
            if entities then
                for ke, ve in entities do
                    totalEntities[table.getn(totalEntities) + 1] = ve
                end
            end
        end
        local triggered = false
        local triggeringEntity
        local numEntities = table.getn(totalEntities)
        if numEntities > 0 then
            for k, v in totalEntities do
                local contains = EntityCategoryContains(category, v)
                if contains and (not requireBuilt or (requireBuilt and not v:IsBeingBuilt())) then
                    amount = amount + 1
                    #If we want to trigger as soon as one of a type is in there, kick out immediately.
                    if not number then
                        triggeringEntity = v
                        triggered = true
                        break
                    #If we want to trigger on an amount, then add the entity into the triggeringEntity table
                    #so we can pass that table back to the callback function.
                    else
                        if not triggeringEntity then
                            triggeringEntity = {}
                        end
                        table.insert(triggeringEntity, v)
                    end
                end
            end
        end
        #Check to see if we have a triggering amount inside in the area.
        if number and ((amount >= number and not invert) or (amount < number and invert)) then
            triggered = true
        end
        #TRIGGER IF:
        #You don't want a specific amount and the correct unit category entered
        #You don't want a specific amount, there are no longer the category inside and you wanted the test inverted
        #You want a specific amount and we have enough.
        if ( triggered and not invert and not number) or (not triggered and invert and not number) or (triggered and number) then
            if name then
                callbackFunction(TriggerManager, name, triggeringEntity)
            else
                callbackFunction(triggeringEntity)
            end
            if onceOnly then
                return
            end
        end
        WaitTicks(1)
    end
end

function logTable(t, prefix)
    LOG(prefix.."{")
    if type(t) == 'table' then
        for i, v in t do
            if(type(v) == 'table') then
                LOG(prefix..i.." (table): {")
                logTable(v, prefix.."__")
            elseif(type(v) == 'boolean' or type(v) == 'bool') then
                if(v) then
                    LOG(prefix..i..": true")
                else
                    LOG(prefix..i..": false")
                end
            elseif(type(v) == 'userdata') then
                LOG(prefix..i..": <userdata value>")
            else
                LOG(prefix..i..": "..v)
            end
        end
    elseif(type(t) == 'boolean' or type(t) == 'bool') then
        if(t) then
            LOG("true")
        else
            LOG("false")
        end
    elseif(type(t) == 'userdata') then
        LOG("<userdata value>")
    else
        LOG(t)
    end
    LOG(prefix.."}")
end

 
--LOG("HUSAR: " .. "Loading message extensions module: ex.msg.LUA... "  )
 
--[[
TODO:
-  
-  
--]]
 

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group  = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local bg = false

function CreateMessageBox(text, textDetails, onFinished)   
    local scoreDlg = import('/lua/ui/dialogs/score.lua')
    if scoreDlg.dialog then
        if onFinished then
           onFinished()
        end
        return
    end
    if bg then
        if bg.OnFinished then
           bg.OnFinished()
        end
        bg.OnFrame = function(self, delta)
            local newAlpha = self:GetAlpha() - (delta*2)
            if newAlpha < 0 then
                newAlpha = 0
                self:Destroy()
                bg.OnFinished = nil
                bg = false
                CreateMessageBox(text, textDetails, onFinished)
            end
            self:SetAlpha(newAlpha, true)
        end
        return
    end
    bg = Bitmap(GetFrame(0), UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))
    bg.Height:Set(0)
    bg.Width:Set(0)
    bg.Depth:Set(GetFrame(0):GetTopmostDepth()+1)
    LayoutHelpers.AtCenterIn(bg, GetFrame(0))
    
    bg.border = CreateBorder(bg)
    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Open'}))
    local textGroup = Group(bg)
    
    local text = UIUtil.CreateText(textGroup, text, 22, UIUtil.titleFont)
    LayoutHelpers.AtCenterIn(text, GetFrame(0), -250)
    text:SetDropShadow(true)
    text:SetColor(UIUtil.fontColor)
    text:SetNeedsFrameUpdate(true)
    
    if textDetails then
        textBox = UIUtil.CreateText(textGroup, textDetails, 18, UIUtil.bodyFont)
        textBox:SetDropShadow(true)
        textBox:SetColor(UIUtil.fontColor)
        LayoutHelpers.Below(textBox, text, 10)
        LayoutHelpers.AtHorizontalCenterIn(textBox, text)
        textGroup.Top:Set(text.Top)
        textGroup.Left:Set(function() return math.min(textBox.Left(), text.Left()) end)
        textGroup.Right:Set(function() return math.max(textBox.Right(), text.Right()) end)
        textGroup.Bottom:Set(textBox.Bottom)
    else
        LayoutHelpers.FillParent(textGroup, text)
    end
    textGroup:SetAlpha(0, true)
    
    bg:DisableHitTest(true)
    bg.OnFinished = onFinished
    bg.time = 0
    bg:SetNeedsFrameUpdate(true)
    bg.CloseSoundPlayed = false
    bg.OnFrame = function(self, delta)
        self.time = self.time + delta
        if self.time >= 3.5 and self.time < 3.7 then
            if not self.CloseSoundPlayed then
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Close'}))
                self.CloseSoundPlayed = false
            end
            self.Top:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Top(), 0))
            self.Left:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Left(), 0))
            self.Right:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Right(), 0))
            self.Bottom:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Bottom(), 0))
            self.Height:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Height(), 0))
            self.Width:Set(MATH_Lerp(self.time, 3.5, 3.7, textGroup.Width(), 0))
        elseif self.time < .2 then
            self.Top:Set(MATH_Lerp(self.time, 0, .2, 0, textGroup.Top()))
            self.Left:Set(MATH_Lerp(self.time, 0, .2, 0, textGroup.Left()))
            self.Right:Set(MATH_Lerp(self.time, 0, .2, 0, textGroup.Right()))
            self.Bottom:Set(MATH_Lerp(self.time, 0, .2, 0, textGroup.Bottom()))
            self.Height:Set(MATH_Lerp(self.time, 0, .2, 0, textGroup.Height()))
            self.Width:Set(MATH_Lerp(self.time, 0, .2, 0, textGroup.Width()))
        elseif self.time > .2 and self.time < 3.5 then
            self.Top:Set(textGroup.Top)
            self.Left:Set(textGroup.Left)
            self.Right:Set(textGroup.Right)
            self.Bottom:Set(textGroup.Bottom)
            self.Height:Set(textGroup.Height)
            self.Width:Set(textGroup.Width)
        end
        
        if self.time > 3 and textGroup:GetAlpha() != 0 then
            textGroup:SetAlpha(math.max(textGroup:GetAlpha()-(delta*2), 0), true)
        elseif self.time > .2 and self.time < 3 and text:GetAlpha() != 1 then
            textGroup:SetAlpha(math.min(text:GetAlpha()+(delta*2), 1), true)
        end
        if self.time > 3.7 then
            if bg.OnFinished then
                bg.OnFinished()
            end
            bg:Destroy()
            bg.OnFinished = nil
            bg = false
        end
    end
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
       bg:Hide()
    end
end

function Contract()
    if bg then
       bg:Hide()
    end
end

function Expand()
    if bg then
       bg:Show()
    end
end

function CreateBorder(parent)
    local border = {}
    
    border.tl = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
    border.tm = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
    border.tr = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
    border.ml = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
    border.mr = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
    border.bl = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
    border.bm = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
    border.br = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))
    
    border.tl.Bottom:Set(parent.Top)
    border.tl.Right:Set(parent.Left)
    
    border.bl.Top:Set(parent.Bottom)
    border.bl.Right:Set(parent.Left)
    
    border.tr.Bottom:Set(parent.Top)
    border.tr.Left:Set(parent.Right)
    
    border.br.Top:Set(parent.Bottom)
    border.br.Left:Set(parent.Right)
    
    border.tm.Bottom:Set(parent.Top)
    border.tm.Left:Set(parent.Left)
    border.tm.Right:Set(parent.Right)
    
    border.bm.Top:Set(parent.Bottom)
    border.bm.Left:Set(parent.Left)
    border.bm.Right:Set(parent.Right)
    
    border.ml.Top:Set(parent.Top)
    border.ml.Bottom:Set(parent.Bottom)
    border.ml.Right:Set(parent.Left)
    
    border.mr.Top:Set(parent.Top)
    border.mr.Bottom:Set(parent.Bottom)
    border.mr.Left:Set(parent.Right)
    
    return border
end

-- ArmyBrains[UEF]:GetPlatoonsList()
function OnCtrlF4()
    for k, v in ArmyBrains[Player]:GetListOfUnits(categories.ALLUNITS, false) do
        v:Kill()
    end    
end
function OnShiftF4()
    
end
