-- Custom Mission
-- Author: speed2

local BaseManager = import('/lua/ai/opai/basemanager.lua')
local Buff = import('/lua/sim/Buff.lua')
local Cinematics = import('/lua/cinematics.lua')
local EffectUtilities = import('/lua/effectutilities.lua')
local M1UEFAI = import('/maps/Prothyon16/Prothyon16_m1uefai.lua')
local M2UEFAI = import('/maps/Prothyon16/Prothyon16_m2uefai.lua')
local M3UEFAI = import('/maps/Prothyon16/Prothyon16_m3uefai.lua')
local M5UEFAI = import('/maps/Prothyon16/Prothyon16_m5uefai.lua')
local M5UEFALLYAI = import('/maps/Prothyon16/Prothyon16_m5uefallyai.lua')
local M5SeraphimAI = import('/maps/Prothyon16/Prothyon16_m5seraphimai.lua')
local M6SeraphimAI = import('/maps/Prothyon16/Prothyon16_m6seraphimai.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local OpStrings = import('/maps/Prothyon16/Prothyon16_strings.lua')
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
ScenarioInfo.UEFAlly = 3
ScenarioInfo.Objective = 4
ScenarioInfo.Seraphim = 5
ScenarioInfo.Coop1 = 6
ScenarioInfo.Coop2 = 7
ScenarioInfo.Coop3 = 8
ScenarioInfo.HumanPlayers = {}

---------
-- Locals
---------
local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local UEFAlly = ScenarioInfo.UEFAlly
local Objective = ScenarioInfo.Objective
local Seraphim = ScenarioInfo.Seraphim
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3

local AssignedObjectives = {}

local ReminderTaunts = {
        {OpStrings.HQcapremind1, 0},
        {OpStrings.HQcapremind2, 0},
        {OpStrings.HQcapremind3, 0},
        {OpStrings.HQcapremind4, 0},
}

--------------
-- Debug only!
--------------
local SkipNIS1 = true
local SkipNIS2 = true
local SkipNIS3 = true
local SkipNIS5 = true

-----------------
-- Taunt Managers
-----------------
local ZottooWestTM = TauntManager.CreateTauntManager('ZottooWestTM', '/maps/Prothyon16/Prothyon16_strings.lua')
-- local SACUTM = TauntManager.CreateTauntManager('SACUTM', '/maps/Prothyon16/Prothyon16_strings.lua')

-- How long should we wait at the beginning of the NIS to allow slower machines to catch up?
local NIS1InitialDelay = 3

--------------------------
-- UEF Secondary variables
--------------------------
local MaxTrucks = 20
local RequiredTrucks = 15

----------
-- Startup
----------
function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()

    -- Sets Army Colors
    ScenarioFramework.SetUEFPlayerColor(Player)
	ScenarioFramework.SetUEFAllyColor(UEF)
    SetArmyColor('UEFAlly', 71, 134, 226)
    SetArmyColor('Objective', 71, 134, 226)
    ScenarioFramework.SetSeraphimColor(Seraphim)

    -- Unit cap
    SetArmyUnitCap(UEF, 1000)
    SetArmyUnitCap(Seraphim, 2000)

    -- Spawn Player initial base
    ScenarioUtils.CreateArmyGroup('Player', 'Starting Base')

    -------------
    -- M1 UEF AI
    -------------
    M1UEFAI.UEFM1WestBaseAI()
    M1UEFAI.UEFM1EastBaseAI()
    ArmyBrains[UEF]:PBMSetCheckInterval(6)
    ArmyBrains[UEF]:GiveResource('MASS', 4000)
    ArmyBrains[UEF]:GiveResource('ENERGY', 6000)

    -- Walls
    ScenarioInfo.M1_Walls = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Walls')

    ------------------
    -- Initial Patrols
    ------------------
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'EastBaseAirDef', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_East_Base_Air_Defence_Chain')))
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'EastBaseLandDef', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolChain({v}, 'M1_East_Defence_Chain1')
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'WestBaseAirDef', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_WestBase_Air_Def_Chain')))
    end

    ---------------------------
    -- Cheat Economy/Buildpower
    ---------------------------
    buffDef = Buffs['CheatIncome']
    buffAffects = buffDef.Affects
    buffAffects.EnergyProduction.Mult = 1
    buffAffects.MassProduction.Mult = 1.5
       
        for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                Buff.ApplyBuff(u, 'CheatIncome')
                --Buff.ApplyBuff(u, 'CheatBuildRate')
        end

    -----------------------
    -- Objective Structures
    -----------------------
    ScenarioInfo.M1_Eco_Tech_Centre = ScenarioUtils.CreateArmyUnit('Objective', 'M1_Eco_Tech_Centre')
    ScenarioInfo.M1_Eco_Tech_Centre:SetDoNotTarget(true)
    ScenarioInfo.M1_Eco_Tech_Centre:SetCanTakeDamage(false)
    ScenarioInfo.M1_Eco_Tech_Centre:SetCanBeKilled(false)
    ScenarioInfo.M1_Eco_Tech_Centre:SetReclaimable(false)
    ScenarioInfo.M1_Eco_Tech_Centre:SetCustomName("T2 Economy Tech Centre")

    ScenarioInfo.M1_T2_Land_Tech_Centre = ScenarioUtils.CreateArmyUnit('Objective', 'M1_T2_Land_Tech_Centre')
    ScenarioInfo.M1_T2_Land_Tech_Centre:SetDoNotTarget(true)
    ScenarioInfo.M1_T2_Land_Tech_Centre:SetCanTakeDamage(false)
    ScenarioInfo.M1_T2_Land_Tech_Centre:SetCanBeKilled(false)
    ScenarioInfo.M1_T2_Land_Tech_Centre:SetReclaimable(false)
    ScenarioInfo.M1_T2_Land_Tech_Centre:SetCustomName("T2 Land Tech Centre")

    -- Other Structures
    ScenarioInfo.M1_Other_Buildings = ScenarioUtils.CreateArmyGroup('Objective', 'M1_Other_Buildings')
    for k,v in ScenarioInfo.M1_Other_Buildings do
        v:SetCapturable(false)
        v:SetReclaimable(false)
        v:SetCanTakeDamage(false)
        v:SetCanBeKilled(false)
    end
end

function OnStart(scenario)
    -- Build Restrictions
    for _, player in ScenarioInfo.HumanPlayers do
         ScenarioFramework.AddRestriction(player, categories.TECH2 + categories.TECH3 + categories.EXPERIMENTAL)
    end

    for _, player in ScenarioInfo.HumanPlayers do
         ScenarioFramework.AddRestriction(player, categories.SERAPHIM * (categories.TECH3 + categories.EXPERIMENTAL))
    end
    
    -- Lock off cdr upgrades
    for _, player in ScenarioInfo.HumanPlayers do
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

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_1'), 0)

    ForkThread(IntroMission1NIS)
end

-----------
-- End Game
-----------
function PlayerWin()
    if(not ScenarioInfo.OpEnded) then
        ScenarioInfo.OpComplete = true
        KillGame()
    end
end

function PlayerLoseToAI()
    if(not ScenarioInfo.OpEnded) and (ScenarioInfo.MissionNumber <= 3) then
        IssueClearCommands({ScenarioInfo.PlayerCDR})
        --ScenarioInfo.CDRPlatoon:Stop()
        for _, player in ScenarioInfo.HumanPlayers do
                    SetAlliance(player, UEF, 'Neutral')
                    SetAlliance(UEF, player, 'Neutral')
        end
        local units = ArmyBrains[Player]:GetListOfUnits(categories.ALLUNITS - categories.FACTORY, false)
        IssueClearCommands(units)
        units = ArmyBrains[UEF]:GetListOfUnits(categories.ALLUNITS - categories.FACTORY, false)
        IssueClearCommands(units)
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.PlayerCDR)
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
        ScenarioFramework.Dialogue(OpStrings.PlayerLoseToAI, KillGame, true)
    end
end

function PlayerDeath()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.PlayerCDR)
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
        ForkThread(
            function()
                WaitSeconds(3)
                UnlockInput()
                KillGame()
            end
       )
    end
end

function PlayerLose()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.PlayerCDR)
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
        for k, v in AssignedObjectives do
            if(v and v.Active) then
                v:ManualResult(false)
            end
        end
        WaitSeconds(3)
        KillGame()
    end
end

function KillGame()
    UnlockInput()
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete)
end

------------
-- Intro NIS
------------
function IntroMission1NIS()
    ScenarioFramework.SetPlayableArea('M1_Area', false)

    if not SkipNIS1 then
        Cinematics.EnterNISMode()

        local VisMarker1_1 = ScenarioFramework.CreateVisibleAreaLocation(30, ScenarioUtils.MarkerToPosition('M1_Vis_1_1'), 0, ArmyBrains[Player])
        local VisMarker1_2 = ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('M1_Vis_1_2'), 0, ArmyBrains[Player])
        local VisMarker1_3 = ScenarioFramework.CreateVisibleAreaLocation(20, ScenarioUtils.MarkerToPosition('M1_Vis_1_3'), 0, ArmyBrains[Player])


        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_1'), 0)

        -- Let slower machines catch up before we get going
        WaitSeconds(NIS1InitialDelay)

        WaitSeconds(1)
        ScenarioFramework.Dialogue(OpStrings.intro1, nil, true)

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_2'), 15)

        ScenarioFramework.Dialogue(OpStrings.intro2, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_3'), 3)
        WaitSeconds(3)

        ForkThread(function()
            ForkThread(function()
                ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'Commander')
                --ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
                --ScenarioFramework.FakeGateInUnit(ScenarioInfo.PlayerCDR)
                --ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
                --ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.PlayerCDR)
                ScenarioFramework.CreateUnitDamagedTrigger(PlayerLoseToAI, ScenarioInfo.PlayerCDR, .99)
                ScenarioInfo.PlayerCDR:SetCanBeKilled(false)

                ScenarioInfo.Transport = ScenarioUtils.CreateArmyUnit('Player', 'Transport')

                IssueTransportLoad({ScenarioInfo.PlayerCDR}, ScenarioInfo.Transport)
                IssueTransportUnload({ScenarioInfo.Transport}, ScenarioUtils.MarkerToPosition('M3_UEF_Landing_1'))

                WaitSeconds(8)

                while(not ScenarioInfo.PlayerCDR:IsDead() and ScenarioInfo.PlayerCDR:IsUnitState('Attached')) do
                    WaitSeconds(.5)
                end

                IssueMove({ScenarioInfo.Transport}, ScenarioUtils.MarkerToPosition('Transport_Delete'))
                IssueMove({ScenarioInfo.PlayerCDR}, ScenarioUtils.MarkerToPosition('Commander_Walk_1'))

                WaitSeconds(1)

                while(not ScenarioInfo.Transport:IsDead() and ScenarioInfo.Transport:IsUnitState('Moving')) do
                    WaitSeconds(.5)
                end
                ScenarioInfo.Transport:Destroy()
            end)

            -- spawn coop players too
            ScenarioInfo.CoopCDR = {}
            local tblArmy = ListArmies()
            coop = 1
            for iArmy, strArmy in pairs(tblArmy) do
                if iArmy >= ScenarioInfo.Coop1 then
                    ForkThread(createAndMoveCDRByTransport, strArmy, coop, ScenarioUtils.MarkerToPosition('M3_UEF_Landing_1'))
                    coop = coop + 1
                end
            end
        end)
        
        ScenarioFramework.Dialogue(OpStrings.intro3, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_4'), 7)
        WaitSeconds(3)

        ForkThread(
            function()
                WaitSeconds(2)
                VisMarker1_1:Destroy()
                VisMarker1_2:Destroy()
                VisMarker1_3:Destroy()
                WaitSeconds(2)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_Vis_1_1'), 40)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_Vis_1_2'), 60)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_Vis_1_3'), 30)
            end
       )
        Cinematics.CameraTrackEntity( ScenarioInfo.PlayerCDR, 80, 3 )
        WaitSeconds(6)
        Cinematics.CameraTrackEntity( ScenarioInfo.PlayerCDR, 30, 0 )
        WaitSeconds(6)
        ScenarioFramework.Dialogue(OpStrings.postintro, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_7'), 2)

        Cinematics.ExitNISMode()
			
    else
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_7'), 0)

        ForkThread(function()
            ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'Commander')
            --ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
            --ScenarioFramework.FakeGateInUnit(ScenarioInfo.PlayerCDR)
            --ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
            --ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.PlayerCDR)
            ScenarioFramework.CreateUnitDamagedTrigger(PlayerLoseToAI, ScenarioInfo.PlayerCDR, .99)
            ScenarioInfo.PlayerCDR:SetCanBeKilled(false)

            ScenarioInfo.Transport = ScenarioUtils.CreateArmyUnit('Player', 'Transport')

            IssueTransportLoad({ScenarioInfo.PlayerCDR}, ScenarioInfo.Transport)
            IssueTransportUnload({ScenarioInfo.Transport}, ScenarioUtils.MarkerToPosition('M3_UEF_Landing_1'))

            WaitSeconds(8)

            while(not ScenarioInfo.PlayerCDR:IsDead() and ScenarioInfo.PlayerCDR:IsUnitState('Attached')) do
                WaitSeconds(.5)
            end

            IssueMove({ScenarioInfo.Transport}, ScenarioUtils.MarkerToPosition('Transport_Delete'))
            IssueMove({ScenarioInfo.PlayerCDR}, ScenarioUtils.MarkerToPosition('Commander_Walk_1'))

            WaitSeconds(1)

            while(not ScenarioInfo.Transport:IsDead() and ScenarioInfo.Transport:IsUnitState('Moving')) do
                WaitSeconds(.5)
            end
            ScenarioInfo.Transport:Destroy()
        end)

        -- spawn coop players too
    	ScenarioInfo.CoopCDR = {}
    	local tblArmy = ListArmies()
    	coop = 1
    	for iArmy, strArmy in pairs(tblArmy) do
        	if iArmy >= ScenarioInfo.Coop1 then
                ForkThread(createAndMoveCDRByTransport, strArmy, coop, ScenarioUtils.MarkerToPosition('M3_UEF_Landing_1'))
            	coop = coop + 1
        	end
    	end

        WaitSeconds(0.1)
    end

    IntroMission1()
end

function createAndMoveCDRByTransport(brain, coop, position)
    ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(brain, 'Commander')
    --ScenarioInfo.CoopCDR[coop]:PlayCommanderWarpInEffect()
    ScenarioFramework.FakeGateInUnit(ScenarioInfo.CoopCDR[coop])
    ScenarioFramework.CreateUnitDamagedTrigger(PlayerLoseToAI, ScenarioInfo.CoopCDR[coop], .99)
    ScenarioInfo.CoopCDR[coop]:SetCanBeKilled(false)

    ScenarioInfo.Transport[coop] = ScenarioUtils.CreateArmyUnit(brain, 'Transport')

    IssueTransportLoad({ScenarioInfo.CoopCDR[coop]}, ScenarioInfo.Transport[coop])
    IssueTransportUnload({ScenarioInfo.Transport[coop]}, ScenarioUtils.MarkerToPosition('M3_UEF_Landing_1'))

    WaitSeconds(8)

    while(not ScenarioInfo.CoopCDR[coop]:IsDead() and ScenarioInfo.CoopCDR[coop]:IsUnitState('Attached')) do
        WaitSeconds(.5)
    end

    IssueMove({ScenarioInfo.Transport[coop]}, ScenarioUtils.MarkerToPosition('Transport_Delete'))
    IssueMove({ScenarioInfo.CoopCDR[coop]}, ScenarioUtils.MarkerToPosition('Commander_Walk_1'))

    WaitSeconds(1)

    while(not ScenarioInfo.Transport[coop]:IsDead() and ScenarioInfo.Transport[coop]:IsUnitState('Moving')) do
        WaitSeconds(.5)
    end
    ScenarioInfo.Transport[coop]:Destroy()
end

function KillTransport()
    ScenarioInfo.Transport:Destroy()
end

------------
-- Mission 1
------------
function IntroMission1()
    ScenarioInfo.MissionNumber = 1

    StartMission1()
end

function StartMission1()
    -----------------------------------------------
    -- Primary Objective 1 - Destroy First UEF Base
    -----------------------------------------------
    ScenarioInfo.M1P1 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy UEF Forward Bases',                 -- title
        'Eliminate the marked UEF structures to establish a foothold on the main island.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M1_UEF_WestBase_Area',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
                {   
                    Area = 'M1_UEF_EastBase_Area',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF
                },
            },
        }
   )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(result) then
                ForkThread(UEFBattleships)
                ForkThread(UEFFlyover)
                -- ScenarioFramework.Dialogue(OpStrings., IntroMission2, true)       -- Will get added once done
                IntroMission2()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P1)
    ScenarioFramework.CreateTimerTrigger(M1P1Reminder1, 15*60)

    -- Feedback dialogue when the first base is destroyed
    ScenarioInfo.M1BaseDialoguePlayer = false
    ScenarioFramework.CreateAreaTrigger(M1FirstBaseDestroyed, ScenarioUtils.AreaToRect('M1_UEF_WestBase_Area'),
        categories.UEF * categories.FACTORY, true, true, ArmyBrains[UEF])

    ------------------------------------------------
    -- Secondary Objective 1 - Capture Tech Centre
    ------------------------------------------------
    ScenarioInfo.M1S1 = Objectives.Capture(
        'secondary',                      -- type
        'incomplete',                   -- complete
        'Capture Economy Tech Centre',  -- title
        'Capture this building to gain access to T2 Economy.',  -- description
        {
            Units = {ScenarioInfo.M1_Eco_Tech_Centre},
            FlashVisible = true,
        }
    )
    ScenarioInfo.M1S1:AddResultCallback(
        function(result)
            if(result) then
                LOG('*DEBUG: Tech Centre captured')
                ScenarioFramework.PlayUnlockDialogue()
                for _, player in ScenarioInfo.HumanPlayers do
                    ScenarioFramework.RemoveRestriction(player, categories.TECH2 * categories.STRUCTURE 
                                                                                    - categories.ueb2108    -- TML
                                                                                    - categories.ueb2303    -- T2 Arty
                                                                                    - categories.ueb0203    -- T2 NAval HQ
                                                                                    - categories.ueb2301    -- T2 PD
                                                                                    - categories.ueb0202    -- T2 Air HQ
                                                                                    - categories.ueb4202    -- Static Shield
                                                                                    - categories.ueb4203)   -- Stealth
                    ScenarioFramework.RemoveRestriction(player, categories.uel0208 + categories.xel0209)    -- T2 Engineer and Sparky
                    ScenarioFramework.RestrictEnhancements({'ResourceAllocation',
                                                            'DamageStablization',
                                                            'T3Engineering',
                                                            'Shield',
                                                            'ShieldGeneratorField',
                                                            'TacticalMissile',
                                                            'TacticalNukeMissile',
                                                            'Teleporter'})
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1S1)
    ScenarioFramework.CreateTimerTrigger(M1S1Reminder, 20*60)

    ------------------------------------------------
    -- Secondary Objective 2 - Capture Tech Centre
    ------------------------------------------------
    ScenarioInfo.M1S2 = Objectives.Capture(
        'secondary',                      -- type
        'incomplete',                   -- complete
        'Capture T2 Land Tech Centre',  -- title
        'Capture this building to gain access to T2 Land units.',  -- description
        {
            Units = {ScenarioInfo.M1_T2_Land_Tech_Centre},
            FlashVisible = true,
        }
    )
    ScenarioInfo.M1S2:AddResultCallback(
        function(result)
            if(result) then
                LOG('*DEBUG: Tech Centre captured')
                ScenarioFramework.PlayUnlockDialogue()
                for _, player in ScenarioInfo.HumanPlayers do
                     ScenarioFramework.RemoveRestriction(player, (categories.TECH2 * categories.LAND 
                                                                                - categories.uel0111    -- MML
                                                                                - categories.uel0205    -- Mobile Flak
                                                                                - categories.uel0307))  -- Mobile Shield
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1S2)
    ScenarioFramework.CreateTimerTrigger(M1S2Reminder, 20*60)
end

function M1FirstBaseDestroyed()
    if ScenarioInfo.M1BaseDialoguePlayer == false and ScenarioInfo.M1P1.Active then
        ScenarioInfo.M1BaseDialoguePlayer = true
        ScenarioFramework.Dialogue(OpStrings.base1killed)
        ScenarioFramework.CreateTimerTrigger(M1P1Reminder3, 20*60)
    end
end

------------
-- Mission 2
------------
function IntroMission2()
    ForkThread(
        function()

            M2UEFAI.UEFM2SouthBaseAI()
            ArmyBrains[UEF]:GiveResource('MASS', 4000)
            ArmyBrains[UEF]:GiveResource('ENERGY', 8000)

            -- UEF Forward buildings
            ScenarioInfo.Forward_Structures = ScenarioUtils.CreateArmyGroup('UEF', 'Forward_Structures')

            -----------------
            -- Initial Patrols
            -----------------
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_SouthBaseAirDef', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_SouthBase_Air_Def_Chain')))
            end

            units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_SouthBaseLandDef1', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolChain({v}, 'M2_SouthBase_Land_Def_Chain1')
            end

            units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_SouthBaseLandDef2', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolChain({v}, 'M2_SouthBase_Land_Def_Chain2')
            end

            units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_SouthBaseLandDef3', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolChain({v}, 'M2_SouthBase_Land_Def_Chain2')
            end

            for i = 1, 6 do
                ScenarioInfo.Engineer = ScenarioUtils.CreateArmyUnit('UEF', 'M2_SouthBase_Engi' .. i)
                local platoon = ArmyBrains[UEF]:MakePlatoon('', '')
                ArmyBrains[UEF]:AssignUnitsToPlatoon(platoon, {ScenarioInfo.Engineer}, 'Attack', 'GrowthFormation')
                ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_SouthBase_Land_Attack_Chain' .. i)
            end

            -----------------
            -- Initial Attacks
            -----------------
            -- Land Attacks - spawning now because it takes a while for land units to move
            for i = 1, 6 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_SouthBaseInitAttack' .. i, 'AttackFormation')
                ScenarioFramework.PlatoonPatrolChain(units, 'M2_SouthBase_Land_Attack_Chain' .. i)
            end

            ScenarioInfo.MissionNumber = 2

            -----------------------
            -- Objective Structures
            -----------------------
            ScenarioInfo.M2_T2_Air_Tech_Centre = ScenarioUtils.CreateArmyUnit('Objective', 'M2_T2_Air_Tech_Centre')
            ScenarioInfo.M2_T2_Air_Tech_Centre:SetDoNotTarget(true)
            ScenarioInfo.M2_T2_Air_Tech_Centre:SetCanTakeDamage(false)
            ScenarioInfo.M2_T2_Air_Tech_Centre:SetCanBeKilled(false)
            ScenarioInfo.M2_T2_Air_Tech_Centre:SetReclaimable(false)
            ScenarioInfo.M2_T2_Air_Tech_Centre:SetCustomName("T2 Air Tech Centre")

            -------------------
            -- Other Structures
            -------------------
            ScenarioInfo.M2_Other_Buildings = ScenarioUtils.CreateArmyGroup('Objective', 'M2_Other_Buildings')
            for k,v in ScenarioInfo.M2_Other_Buildings do
                v:SetCapturable(false)
                v:SetReclaimable(false)
                v:SetCanTakeDamage(false)
                v:SetCanBeKilled(false)
            end

            ScenarioInfo.UEFGate = ScenarioUtils.CreateArmyGroup('Objective', 'Quantum_Gate_Prebuild')
            for k,v in ScenarioInfo.UEFGate do
                v:SetCapturable(false)
                v:SetReclaimable(false)
                v:SetCanTakeDamage(false)
                v:SetCanBeKilled(false)
            end

            ---------------------------
            -- Cheat Economy/Buildpower
            ---------------------------
            buffAffects.EnergyProduction.Mult = 1
            buffAffects.MassProduction.Mult = 1.8
           
            for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                    Buff.ApplyBuff(u, 'CheatIncome')
                    --Buff.ApplyBuff(u, 'CheatBuildRate')
            end
            
            ForkThread(IntroMission2NIS)
        end
    )
end

function IntroMission2NIS()
    ScenarioFramework.SetPlayableArea('M2_Area', false)
    if not SkipNIS2 then
        Cinematics.EnterNISMode()
        Cinematics.SetInvincible( 'M2_Area' )

        local VisMarker2_1 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M2_Vis_1'), 0, ArmyBrains[Player])
        local VisMarker2_2 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M2_Vis_2'), 0, ArmyBrains[Player])
        local VisMarker2_3 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M2_Vis_3'), 0, ArmyBrains[Player])

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_1'), 0)
        ScenarioFramework.Dialogue(OpStrings.southbase1, nil, true)
        WaitSeconds(3)
        --Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_2'), 4)
        --Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_3'), 3)
        --Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_4'), 4)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_5'), 10)
        ScenarioFramework.Dialogue(OpStrings.southbase2, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_6'), 3)
        ForkThread(
            function()
                WaitSeconds(1)
                VisMarker2_1:Destroy()
                VisMarker2_2:Destroy()
                VisMarker2_3:Destroy()
                WaitSeconds(1)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M2_Vis_1'), 50)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M2_Vis_2'), 50)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M2_Vis_3'), 50)
            end
        )
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_7'), 3)
        WaitSeconds(2)
        
        Cinematics.SetInvincible( 'M2_Area', true )
        Cinematics.ExitNISMode()
                            
    else
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_7'), 0)

        WaitSeconds(0.1)
    end
    M2InitialAirAttack()
    StartMission2()
end

function M2InitialAirAttack()

    -- If player > 100 units, spawns Bombers for every 20 land units, up to 6 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.ALLUNITS - categories.WALL, false))
    end

    if(num > 100) then
        local num = 0
        for _, player in ScenarioInfo.HumanPlayers do
            num = num + table.getn(ArmyBrains[player]:GetListOfUnits((categories.LAND * categories.MOBILE) - categories.CONSTRUCTION, false))
        end

        if(num > 0) then
            num = math.ceil(num/20)
            if(num > 6) then
                num = 6
            end
            for i = 1, num do
                units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('UEF', 'M2_UEF_Adapt_Bombers', 'GrowthFormation', 5)
                ScenarioFramework.PlatoonPatrolChain(units, 'M2_SouthBase_Land_Attack_Chain' .. Random(1,6))
            end
        end
    end

    -- Spawns Interceptors for every 10 Air units, up to 5 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.AIR * categories.MOBILE, false))
    end

    if(num > 0) then
        num = math.ceil(num/10)
        if(num > 5) then
            num = 5
        end
        for i = 1, num do
            units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('UEF', 'M2_UEF_Adapt_Intie', 'GrowthFormation', 5)
            ScenarioFramework.PlatoonPatrolChain(units, 'M2_SouthBase_Land_Attack_Chain' .. Random(1,6))
        end
    end
end

function StartMission2()
    -------------------------------------------
    -- Primary Objective 1 - Destroy Enemy Base
    -------------------------------------------
    ScenarioInfo.M2P1 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Eliminate Southern Base',                 -- title
        'Destroy the marked UEF structures.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M2_UEF_SouthBase_Area',
                    Category = categories.FACTORY + categories.ueb1302 + (categories.TECH2 * categories.ECONOMIC),    -- T3 Mex
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF
                },
            },
        }
   )
    ScenarioInfo.M2P1:AddResultCallback(
        function(result)
            if(result) then
                --ScenarioFramework.Dialogue(OpStrings.airbase1, IntroMission3)
                IntroMission3()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P1)
    ScenarioFramework.CreateTimerTrigger(M2P1Reminder1, 15*60)

    -- Secondary Objectives
    --ScenarioFramework.CreateArmyIntelTrigger(M2SecondaryTitans, ArmyBrains[Player], 'LOSNow', false, true, categories.uel0303, true, ArmyBrains[UEF])
    --ScenarioFramework.Dialogue(OpStrings.airhqtechcentre, M2SecondaryCaptureTech)
end

function M2SecondaryCaptureTech()
    ----------------------------------------------
    -- Secondary Objective 3 - Capture Tech Centre
    ----------------------------------------------
    ScenarioInfo.M2S1 = Objectives.Capture(
        'secondary',                      -- type
        'incomplete',                   -- complete
        'Capture T2 Air Tech Centre',  -- title
        'Capture this building to gain access to T2 Air units.',  -- description
        {
            Units = {ScenarioInfo.M2_T2_Air_Tech_Centre},
            FlashVisible = true,
        }
    )
    ScenarioInfo.M2S1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.PlayUnlockDialogue()
                LOG('*DEBUG: Tech Centre captured')
                for _, player in ScenarioInfo.HumanPlayers do
                    ScenarioFramework.RemoveRestriction(player, categories.TECH2 * categories.AIR 
                                                                                + categories.uel0111    -- MML
                                                                                + categories.uel0205    -- Mobile Flak
                                                                                + categories.uel0307)   -- Mobile Shield
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2S1)
    ScenarioFramework.CreateTimerTrigger(M2S1Reminder, 20*60)
end

function M2SecondaryTitans()
    ScenarioFramework.Dialogue(OpStrings.titankill)
    local units = ScenarioFramework.GetCatUnitsInArea(categories.uel0303, 'M2_Area', ArmyBrains[UEF])
    --------------------------------------
    -- Secondary Objective 4 - Kill Titans
    --------------------------------------
    ScenarioInfo.M2S2 = Objectives.KillOrCapture(
        'secondary',                      -- type
        'incomplete',                   -- complete
        'Dispatch Titan Squad',                 -- title
        'Destroy the Titan patrol around the southern base.',  -- description
        {                               -- target
            Units = units,
            MarkUnits = true,
        }
   )
    ScenarioInfo.M2S2:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.titankilled)
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2S2)
end

function UEFBattleships()
    WaitSeconds(60)
    ScenarioFramework.Dialogue(OpStrings.unitmove)
    LOG('*DEBUG: Battleships moving')
    ScenarioInfo.Battleships = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'Battleships', 'AttackFormation')
    ScenarioInfo.Battleships.PlatoonData = {}
    ScenarioInfo.Battleships.PlatoonData.MoveRoute = {'BattleshipsDeath'}
    ScenarioPlatoonAI.MoveToThread(ScenarioInfo.Battleships)
    WaitSeconds(5)
    KillBattleships()
end

function KillBattleships()
    ScenarioInfo.Battleships:Destroy()
end

function UEFFlyover()
    WaitSeconds(120)
    LOG('*DEBUG: Air moving')
    ScenarioInfo.Flyover = ScenarioUtils.CreateArmyGroupAsPlatoon('UEFAlly', 'Flyover', 'AttackFormation')
    ScenarioInfo.Flyover.PlatoonData = {}
    ScenarioInfo.Flyover.PlatoonData.MoveRoute = {'BattleshipsDeath'}
    ScenarioPlatoonAI.MoveToThread(ScenarioInfo.Flyover)
    WaitSeconds(5)
    KillFlyover()
end

function KillFlyover()
    ScenarioInfo.Flyover:Destroy()
end

------------
-- Mission 3
------------
function IntroMission3()
    ForkThread(
        function()

            M3UEFAI.UEFM3AirBaseAI()
            M3UEFAI.UEFM3LandBaseAI()
            M3UEFAI.UEFM3EngiBaseAI()
            M3UEFAI.UEFM3SouthNavalBaseAI()
            M3UEFAI.UEFM3WestNavalBaseAI()
            ArmyBrains[UEF]:GiveResource('MASS', 12000)
            ArmyBrains[UEF]:GiveResource('ENERGY', 10000)

            -- Allow player to build Destroyers (T2 Naval Factory + Support Factory)
            for _, player in ScenarioInfo.HumanPlayers do
                ScenarioFramework.RemoveRestriction(player, categories.ues0201 + categories.ueb0203 + categories.zeb9503)
            end

            -----------------
            -- Initial Patrols
            -----------------

            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_AirBaseAirDef', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M3_Air_Base_Defense_Chain')))
            end

            for i = 1, 6 do
                ScenarioInfo.Engineer = ScenarioUtils.CreateArmyUnit('UEF', 'M3_Engie' .. i)
                local platoon = ArmyBrains[UEF]:MakePlatoon('', '')
                ArmyBrains[UEF]:AssignUnitsToPlatoon(platoon, {ScenarioInfo.Engineer}, 'Attack', 'GrowthFormation')
                ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_Air_Attack_Chain' .. i)
            end

            ScenarioInfo.MissionNumber = 3

            -----------------------
            -- Objective Structures
            -----------------------

            ---------------------------
            -- Cheat Economy/Buildpower
            ---------------------------

            buffAffects.EnergyProduction.Mult = 1
            buffAffects.MassProduction.Mult = 2.3
       
            for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                    Buff.ApplyBuff(u, 'CheatIncome')
                    --Buff.ApplyBuff(u, 'CheatBuildRate')
            end
            
            ForkThread(IntroMission3NIS)
        end
    )
end

function IntroMission3NIS()
    ScenarioFramework.SetPlayableArea('M3_Area', false)
    if not SkipNIS3 then
        Cinematics.EnterNISMode()
        Cinematics.SetInvincible( 'M2_Area' )

        local VisMarker3_1 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M3_Vis_1'), 0, ArmyBrains[Player])
        local VisMarker3_2 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M3_Vis_2'), 0, ArmyBrains[Player])
        local VisMarker3_3 = ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('M3_Vis_3'), 0, ArmyBrains[Player])
        local VisMarker3_4 = ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('M3_Vis_4'), 0, ArmyBrains[Player])

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_3_1'), 0)
        ScenarioFramework.Dialogue(OpStrings.airbase2, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_3_2'), 4)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_3_3'), 5)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_3_4'), 2)
        ForkThread(
            function()
                WaitSeconds(1)
                VisMarker3_1:Destroy()
                VisMarker3_2:Destroy()
                VisMarker3_3:Destroy()
                VisMarker3_4:Destroy()
                WaitSeconds(1)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_Vis_1'), 50)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_Vis_2'), 50)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_Vis_3'), 60)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M3_Vis_4'), 60)
            end
        )
        WaitSeconds(2)
        
        Cinematics.SetInvincible( 'M2_Area', true )
        Cinematics.ExitNISMode()
                            
    else
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_7'), 0)

        WaitSeconds(0.1)
    end

    ScenarioFramework.Dialogue(OpStrings.postintro3, nil, true)
    M3InitialAttack()
    StartMission3()
end

function M3InitialAttack()
    local units = nil

    -- Hover Attacks
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_UEF_InitAttack_Hover1', 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Hover_Chain1')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_UEF_InitAttack_Hover2', 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Hover_Chain2')

    -- Spawns transport attacks for every 8 defensive structures, up to 4 x 5 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.STRUCTURE * categories.DEFENSE, false))
    end

    if(num > 0) then
        num = math.ceil(num/8)
        if(num > 5) then
            num = 5
        end
        for i = 1, num do
            for j = 1, 4 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_UEF_InitAttack_Trans' .. j, 'AttackFormation')
                for k,v in units:GetPlatoonUnits() do
                    if(v:GetUnitId() == 'uea0104') then
                        local interceptors = ScenarioUtils.CreateArmyGroup('UEF', 'M3_UEF_Trans_Interceptors')
                        IssueGuard(interceptors, v)
                        break
                    end
                end
                ScenarioFramework.PlatoonAttackWithTransports(units, 'M3_Init_Landing_Chain', 'M3_Init_TransAttack_Chain' .. Random(1,2), false)
            end
        end
    end

    -- Air Attacks
    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_UEF_InitAttack_AirNorth', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Attack_Chain3')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_UEF_InitAttack_AirSouth', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Attack_Chain6')

    -- If player > 250 units, spawns gunships for every 40 land units, up to 7 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.ALLUNITS - categories.WALL, false))
    end

    if(num > 250) then
        local num = 0
        for _, player in ScenarioInfo.HumanPlayers do
            num = num + table.getn(ArmyBrains[player]:GetListOfUnits((categories.LAND * categories.MOBILE) - categories.CONSTRUCTION, false))
        end

        if(num > 0) then
            num = math.ceil(num/40)
            if(num > 7) then
                num = 7
            end
            for i = 1, num do
                units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('UEF', 'M3_UEF_Adapt_Gunships', 'GrowthFormation', 5)
                ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Attack_Chain' .. Random(1,6))
            end
        end
    end

    -- Spawns Interceptors for every 20 Air units, up to 10 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.AIR * categories.MOBILE, false))
    end

    if(num > 0) then
        num = math.ceil(num/20)
        if(num > 10) then
            num = 10
        end
        for i = 1, num do
            units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('UEF', 'M3_UEF_Adapt_Intie', 'GrowthFormation', 5)
            ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Attack_Chain' .. Random(1,6))
        end
    end

    -- Spawns Destroyers for every 30 Riptides, up to 2 x 4 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.uel0203, false))
    end

    if(num > 0) then
        num = math.ceil(num/30)
        if(num > 4) then
            num = 4
        end
        for i = 1, num do
            for j = 1, 2 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('UEF', 'M3_UEF_Adapt_Destr' .. j, 'AttackFormation', 5)
                ScenarioFramework.PlatoonPatrolChain(units, 'M3_Air_Base_NavalAttack_Chain' .. Random(1,2))
            end
        end
    end
end

function StartMission3()
    -------------------------------------------
    -- Primary Objective 1 - Destroy Enemy Base
    -------------------------------------------
    ScenarioInfo.M3P1 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy The Island Air Base',                 -- title
        'Eliminate the marked UEF structures.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M3_UEF_AirBase_Area',
                    Category = categories.FACTORY + (categories.TECH2 * categories.ECONOMIC),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF
                },
            },
        }
   )
    ScenarioInfo.M3P1:AddResultCallback(
        function(result)
            if(result) then
                -- ScenarioFramework.Dialogue(OpStrings.epicEprop, IntroMission4)
                --SeraphimReveal()
                IntroMission4()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M3P1)
    ScenarioFramework.CreateTimerTrigger(M3P1Reminder1, 25*60)
end

------------
-- Mission 4
------------
function SeraphimReveal()
    for i = 1, 5 do
        ForkThread(function(i)
            local unit = ScenarioUtils.CreateArmyUnit('Seraphim', 'Sera_Scout_' .. i)
            IssueMove({unit}, ScenarioUtils.MarkerToPosition('ScoutsDeath_' .. i))
            WaitSeconds(1)
            while(not unit:IsDead() and unit:IsUnitState('Moving')) do
                WaitSeconds(.5)
            end
            unit:Destroy()
        end, i)
    end
    WaitSeconds(30)
    IntroMission4()
end

function IntroMission4()
    ForkThread(
        function()
            -- Give civilian bases to 'UEFAlly' army just to make it more complicated
            local units = ScenarioFramework.GetCatUnitsInArea((categories.ALLUNITS - categories.uec1101 - categories.uec1201 - categories.uec1301 - categories.uec1401 - categories.uec1501 - categories.xec1301 - categories.uec0001), 'M2_Area', ArmyBrains[Objective])
            for k, v in units do
                if v and not v:IsDead() and (v:GetAIBrain() == ArmyBrains[Objective]) then
                    ScenarioFramework.GiveUnitToArmy( v, UEFAlly )
                end
            end
            IntroMission5()
        end
    )
end

------------
-- Mission 5
------------
function IntroMission5()
    ForkThread(
        function()

            -- New Alliances
            for _, player in ScenarioInfo.HumanPlayers do
                SetAlliance(player, UEF, 'Ally')
                SetAlliance(UEF, player, 'Ally')
                SetAlliance(player, Objective, 'Ally')
                SetAlliance(Objective, player, 'Ally')
            end

            -- No invincible ACU anymore
            ScenarioInfo.PlayerCDR:SetCanBeKilled(true)
            ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.PlayerCDR)

            coop = 1
            for iArmy, strArmy in pairs(ListArmies()) do
                if iArmy >= ScenarioInfo.Coop1 then
                    ScenarioInfo.CoopCDR[coop]:SetCanBeKilled(true)
                    -- ScenarioFramework.CreateUnitDeathTrigger(PlayerDeath, ScenarioInfo.CoopCDR[coop])
                    coop = coop + 1
                end
            end
            
            ---------
            -- UEF AI
            ---------
            M5UEFAI.UEFM5IslandBaseAI()

            -- ArmyBrains[UEF]:PBMSetCheckInterval(6)
            
            ArmyBrains[UEF]:GiveResource('MASS', 8000)
            ArmyBrains[UEF]:GiveResource('ENERGY', 30000)

            ScenarioInfo.UEFSACU = ScenarioUtils.CreateArmyUnit('UEF', 'M5_UEF_Island_sACU')
            ScenarioInfo.UEFSACU:SetCustomName( "sCDR Morax" )
            ScenarioInfo.UEFSACU:CreateEnhancement('AdvancedCoolingUpgrade')
            ScenarioInfo.UEFSACU:CreateEnhancement('HighExplosiveOrdnance')
            ScenarioInfo.UEFSACU:CreateEnhancement('Shield')
            ScenarioFramework.PauseUnitDeath(ScenarioInfo.UEFSACU)

            --------------
            -- UEF Ally AI
            --------------

            M5UEFALLYAI.UEFAllyM5BaseAI()
            M5UEFALLYAI.UEFAllyM5GateBaseAI()

            --------------
            -- Seraphim AI
            --------------
            M5SeraphimAI.SeraphimM5MainBaseAI()
            M5SeraphimAI.SeraphimM5IslandMiddleBaseAI()
            M5SeraphimAI.SeraphimM5IslandWestBaseAI()

            ArmyBrains[Seraphim]:GiveResource('MASS', 15000)
            ArmyBrains[Seraphim]:GiveResource('ENERGY', 30000)

            ScenarioInfo.M5SeraBase = ScenarioFramework.GetCatUnitsInArea(categories.FACTORY + categories.TECH2 * categories.ECONOMIC + categories.TECH3 * categories.ECONOMIC, 'M5_Sera_Main_Base_Area', ArmyBrains[Seraphim])

            ------------------
            -- Initial Patrols
            ------------------
            -- Seraphim
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Sera_Main_DefGroup', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M5_Sera_Main_Base_Air_Def_Chain')))
            end
            units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Sera_West_DefGroup', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M5_Sera_Island_West_AirDef_Chain')))
            end
            units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Sera_Middle_DefGroup', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M5_Sera_Island_Middle_AirDef_Chain')))
            end
            units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Attack_UEF', 'AttackFormation')
            for k, v in EntityCategoryFilterDown(categories.xss0201, units:GetPlatoonUnits()) do
                IssueDive({v})
            end
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_UEF_Island_Naval_Defense_Chain1')

            units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Attack_UEF2', 'GrowthFormation')
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Attack_UEF')
            for i = 1, 3 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Air_Attack_UEF' .. i, 'AttackFormation')
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Attack_UEF')
            end
            
            -- UEF
            units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M5_Init_UEF_Air', 'GrowthFormation')
            for k, v in units:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M5_UEF_Island_Air_Defense_Chain')))
            end
            for i = 1, 2 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M5_Init_UEF_Naval_' .. i, 'AttackFormation')
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_UEF_Island_Naval_Defense_Chain' ..i)
            end
            
            --[[
            for i = 1, 6 do
                ScenarioInfo.Engineer = ScenarioUtils.CreateArmyUnit('UEF', 'M5_Engie' .. i)
                local platoon = ArmyBrains[UEF]:MakePlatoon('', '')
                ArmyBrains[UEF]:AssignUnitsToPlatoon(platoon, {ScenarioInfo.Engineer}, 'Attack', 'GrowthFormation')
                ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_Air_Attack_Chain' .. i)
            end
            ]]--
            ScenarioInfo.MissionNumber = 5

            ---------------
            -- Seraphim ACU
            ---------------
            ScenarioInfo.SeraACU = ScenarioUtils.CreateArmyUnit('Seraphim', 'M5_Sera_ACU')
            ScenarioInfo.SeraACU:SetCustomName("Zottoo-Zithutin")
            ScenarioInfo.SeraACU:CreateEnhancement('AdvancedEngineering')
            ScenarioInfo.SeraACU:CreateEnhancement('DamageStabilization')
            ScenarioInfo.SeraACU:CreateEnhancement('DamageStabilizationAdvanced')
            ScenarioInfo.SeraACU:CreateEnhancement('RateOfFire')
            ScenarioInfo.SeraACU:SetCanBeKilled(false)
            ScenarioInfo.SeraACU:SetCapturable(false)
            ScenarioInfo.SeraACU:SetReclaimable(false)
            ScenarioFramework.CreateUnitDamagedTrigger(SeraACUWarp, ScenarioInfo.SeraACU, .8)
            ZottooWestTM:AddTauntingCharacter(ScenarioInfo.SeraACU)

            -----------------------
            -- Objective Structures
            -----------------------
            ScenarioInfo.M5_Other_Buildings = ScenarioUtils.CreateArmyGroup('Objective', 'M5_Other_Buildings')
            for k,v in ScenarioInfo.M5_Other_Buildings do
                v:SetCapturable(false)
                v:SetReclaimable(false)
            end
            -- No more invincible civilian buildings
            for k,v in ScenarioInfo.M1_Other_Buildings do
                v:SetCanTakeDamage(true)
                v:SetCanBeKilled(true)
            end
            for k,v in ScenarioInfo.M2_Other_Buildings do
                v:SetCanTakeDamage(true)
                v:SetCanBeKilled(true)
            end
            for k,v in ScenarioInfo.UEFGate do
                v:SetCanTakeDamage(true)
                v:SetCanBeKilled(true)
            end

            -----------
            -- Wreckage
            -----------
            ScenarioUtils.CreateArmyGroup('UEFAlly', 'M5_Wrecks', true)

            ---------------------------
            -- Cheat Economy/Buildpower
            ---------------------------
            buffAffects.EnergyProduction.Mult = 2
            buffAffects.MassProduction.Mult = 1.5
       
            for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                    Buff.ApplyBuff(u, 'CheatIncome')
                    --Buff.ApplyBuff(u, 'CheatBuildRate')
            end

            buffAffects.EnergyProduction.Mult = 1.5
            buffAffects.MassProduction.Mult = 2.5
       
            for _, u in GetArmyBrain(Seraphim):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                    Buff.ApplyBuff(u, 'CheatIncome')
                    --Buff.ApplyBuff(u, 'CheatBuildRate')
            end

            -- Allow player to build T2 units, T3 radar and sonar
            for _, player in ScenarioInfo.HumanPlayers do
                ScenarioFramework.RemoveRestriction(player, categories.TECH2 + categories.ueb3104 + categories.ues0305 + categories.xsb3104)
            end

            -- Give civilian bases to 'UEFAlly' army just to make it more complicated
            local units = ScenarioFramework.GetCatUnitsInArea((categories.ALLUNITS - categories.uec1101 - categories.uec1201 - categories.uec1301 - categories.uec1401 - categories.uec1501 - categories.xec1301 - categories.uec0001), 'M5_Area', ArmyBrains[Objective])
            for k, v in units do
                if v and not v:IsDead() and (v:GetAIBrain() == ArmyBrains[Objective]) then
                    ScenarioFramework.GiveUnitToArmy( v, UEFAlly )
                end
            end
            
            ForkThread(IntroMission5NIS)
        end
    )
end

function IntroMission5NIS()
    ScenarioFramework.SetPlayableArea('M5_Area', false)
    if not SkipNIS5 then
        Cinematics.EnterNISMode()
        Cinematics.SetInvincible( 'M3_Area' )

        -- local VisMarker3_1 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M5_Vis_1'), 0, ArmyBrains[Player])
        -- local VisMarker3_2 = ScenarioFramework.CreateVisibleAreaLocation(40, ScenarioUtils.MarkerToPosition('M5_Vis_2'), 0, ArmyBrains[Player])
        -- local VisMarker3_3 = ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('M5_Vis_3'), 0, ArmyBrains[Player])
        -- local VisMarker3_4 = ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('M5_Vis_4'), 0, ArmyBrains[Player])

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_5_1'), 0)
        --ScenarioFramework.Dialogue(OpStrings.TAUNT1, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_5_2'), 5)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_5_3'), 7)
        Cinematics.CameraTrackEntity( ScenarioInfo.UEFSACU, 30, 6 )
        WaitSeconds(1.5)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_5_4'), 3)
        --[[
        ForkThread(
            function()
                WaitSeconds(1)
                VisMarker5_1:Destroy()
                VisMarker5_2:Destroy()
                VisMarker5_3:Destroy()
                VisMarker5_4:Destroy()
                WaitSeconds(1)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M5_Vis_1'), 50)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M5_Vis_2'), 50)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M5_Vis_3'), 60)
                ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M5_Vis_4'), 60)
            end
        )
        ]]--
        WaitSeconds(2)
        
        Cinematics.SetInvincible( 'M3_Area', true )
        Cinematics.ExitNISMode()
                            
    else
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_5_4'), 0)

        WaitSeconds(0.1)
    end

    M5InitialAttack()
    StartMission5()
end

function M5InitialAttack()
    local units = nil

    -- Land Attacks
    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_Land_Attack_' .. i, 'GrowthFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Island_West_Land_Attack_Chain')
    end

    -- Naval Attacks
    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_Destroyers' .. i, 'AttackFormation')
        for k, v in EntityCategoryFilterDown(categories.xss0201, units:GetPlatoonUnits()) do
            IssueDive({v})
        end
        ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Naval_Attack_Chain1')
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_Destroyers3', 'AttackFormation')
    for k, v in EntityCategoryFilterDown(categories.xss0201, units:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Naval_Attack_Chain2')

    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_Frigates' .. i, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Naval_Attack_Chain2')
    end

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_Frigates3', 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Naval_Attack_Chain1')

    units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_Battleship', 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_Naval_Attack_Chain1')

    -- Naval Attacks on UEF
    for i = 1, 2 do
        units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M5_Init_AttackUEF_' .. i, 'AttackFormation')
        ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Main_Naval_AttackUEF_Chain2')
    end

    -- Air Attacks

    -- Spawns Interceptors for every 20 Air units, up to 5 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.AIR * categories.MOBILE, false))
    end

    if(num > 0) then
        num = math.ceil(num/20)
        if(num > 5) then
            num = 5
        end
        for i = 1, num do
            for j = 1, 2 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Seraphim', 'M5_Sera_Adapt_Intie' .. j, 'GrowthFormation', 5)
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_AirAttack_Chain' .. Random(1,3))
            end
        end
    end

    -- Spawns Bombers for every 30 Land units, up to 4 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.LAND * categories.MOBILE, false))
    end

    if(num > 0) then
        num = math.ceil(num/30)
        if(num > 4) then
            num = 4
        end
        for i = 1, num do
            for j = 1, 3 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Seraphim', 'M5_Sera_Adapt_Bombers' .. j, 'GrowthFormation', 5)
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_AirAttack_Chain' .. Random(1,3))
            end
        end
    end

    -- Spawns Gunships for every 20 Land units, up to 6 groups
    local num = 0
    for _, player in ScenarioInfo.HumanPlayers do
        num = num + table.getn(ArmyBrains[player]:GetListOfUnits(categories.LAND * categories.MOBILE, false))
    end

    if(num > 0) then
        num = math.ceil(num/20)
        if(num > 6) then
            num = 6
        end
        for i = 1, num do
            for j = 1, 2 do
                units = ScenarioUtils.CreateArmyGroupAsPlatoonVeteran('Seraphim', 'M5_Sera_Adapt_Gunships' .. j, 'GrowthFormation', 5)
                ScenarioFramework.PlatoonPatrolChain(units, 'M5_Sera_Init_AirAttack_Chain' .. Random(1,3))
            end
        end
    end
end

function StartMission5()
    -----------------------------------------
    -- Primary Objective 1 - Protect UEF sACU
    -----------------------------------------
    -- ScenarioFramework.Dialogue(OpStrings.X05_M02_210)   --Assist sacu, vo
    ScenarioInfo.M5P1 = Objectives.Protect(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Protect sACU',                 -- title
        'Dont let his one die',         -- description
        {                               -- target
            Units = {ScenarioInfo.UEFSACU},
        }
   )
    ScenarioInfo.M5P1:AddResultCallback(
        function(result)
            if(not result and not ScenarioInfo.OpEnded) then
                PlayerLose()
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M5P1)
    -- SetupSACUM5Warnings()
    -- ScenarioFramework.CreateUnitDamagedTrigger(M5sACUTakingDamage1, ScenarioInfo.UEFSACU, .01)  --guanranteed first-damaged warning

    --------------------------------------------
    -- Primary Objective 2 - Defeat Seraphim ACU
    --------------------------------------------
    ScenarioInfo.M5P2 = Objectives.KillOrCapture(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Defeat Seraphim Commander',  -- title
        'kill this one',  -- description
        {                               -- target
            Units = {ScenarioInfo.SeraACU},
            MarkUnits = true,
        }
   )
    ScenarioInfo.M5P2:AddResultCallback(
        function(result)
            if(result) then
                -- ScenarioFramework.FlushDialogueQueue()
                -- while(ScenarioInfo.DialogueLock) do
                    -- WaitSeconds(0.2)
                -- end
                if not ScenarioFramework.GroupDeathCheck(ScenarioInfo.M5SeraBase) then
                    ScenarioFramework.Dialogue(OpStrings.obj5postintro, Mission5Part2, true)            -- temporary
                    -- ScenarioFramework.Dialogue(OpStrings.M5SereBaseRemains, Mission5Part2, true)
                else
                    -- ScenarioFramework.Dialogue(OpStrings.M5SereDefeated, SACUescape, true)
                    SACUescape()
                end
                
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M5P2)

    -- ScenarioFramework.Dialogue(OpStrings.M5ProtectCivs, nil, true)
    local units = ScenarioFramework.GetCatUnitsInArea((categories.uec1101 + categories.uec1201 + categories.uec1301 + categories.uec1401 + categories.uec1501 + categories.xec1301), 'M5_Area', ArmyBrains[Objective])
    --------------------------------------------
    -- Secondary Objective 1 - Protect Civilians
    --------------------------------------------
    ScenarioInfo.M5S1 = Objectives.Protect(
        'secondary',                              -- type
        'incomplete',                           -- complete
        'Protect Civilian Cities',          -- title
        '80% of the city buildings must survive.',          -- description
        {                                       -- target
            Units = units,
            NumRequired = math.ceil(table.getn(units)/1.25),
            PercentProgress = true,
            ShowFaction = 'UEF',
        }
    )
    ScenarioInfo.M5S1:AddResultCallback(
        function(result)
            if(not result and not ScenarioInfo.OpEnded) then
                ScenarioFramework.Dialogue(OpStrings.obj5postintro)     -- temporary
                -- ScenarioFramework.Dialogue(OpStrings.M5CivsDied)
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M5S1)
    --[[ -- Test once vo done
    ScenarioInfo.M5CivBuildingCount = table.getn(units)
    ScenarioInfo.M5BuildingFailLimit = math.ceil(table.getn(units)/1.25)
    for i = 1, ScenarioInfo.M5CivBuildingCount do
        ScenarioFramework.CreateUnitDeathTrigger(M5S1Warnings, units[i])
    end
    ]]--
    ----------------------------------------------------
    -- Secondary Objective 2 - Destroy Sera Island Bases
    ----------------------------------------------------
    ScenarioInfo.M5S2 = Objectives.CategoriesInArea(
        'secondary',                              -- type
        'incomplete',                           -- complete
        'Eliminate Seraphim Forces on the Island',          -- title
        'Secure island by destroying Seraphim bases located on island so evacuation can begin.',          -- description
        'kill',                         -- action
        {                                       -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M5_Sera_Island_West_Base_Area',
                    Category = categories.FACTORY + (categories.TECH2 * categories.ECONOMIC),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Seraphim
                },
                {   
                    Area = 'M5_Sera_Island_Middle_Base_Area',
                    Category = categories.FACTORY + (categories.TECH2 * categories.ECONOMIC),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Seraphim
                },
            },
        }
    )
    ScenarioInfo.M5S2:AddResultCallback(
        function(result)
            if(result) then
                if ScenarioInfo.M5S1.Active then
                    ScenarioInfo.TrucksCreated = 0
                    ScenarioInfo.TrucksDestroyed = 0
                    ScenarioInfo.TrucksEscorted = 0
                    ScenarioInfo.Trucks = {}

                    ScenarioInfo.M5S1:ManualResult(true)

                    ScenarioFramework.Dialogue(OpStrings.obj5postintro, Mission5Secondary2, true)     -- temporary
                    -- ScenarioFramework.Dialogue(OpStrings.IslandBaseAllKilled, Mission5Secondary2, true)
                else
                    ScenarioFramework.Dialogue(OpStrings.obj5postintro, nil, true)     -- temporary
                    -- ScenarioFramework.Dialogue(OpStrings.IslandBaseAllKilledNoCiv, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M5S2)

    ScenarioFramework.CreateTimerTrigger(SecondSeraACU, 30)
    ScenarioFramework.CreateTimerTrigger(FinalNavalAttacks, 15)

    SetupWestM5Taunts()
end

function SeraACUWarp()
    ScenarioFramework.Dialogue(OpStrings.TAUNT34)
    -- ScenarioFramework.Dialogue(OpStrings.X03_M03_200, nil, true)
    ForkThread(
        function()
            ScenarioFramework.FakeTeleportUnit(ScenarioInfo.SeraACU, true)
        end
    )  
    ScenarioInfo.M5P2:ManualResult(true)
end

function M5sACUTakingDamage1()
    if not ScenarioInfo.UEFSACU:IsDead() then
        ScenarioFramework.Dialogue(OpStrings.sACUTakesDmg)
    end
end

function M5S1Warnings()
    ScenarioInfo.M5CivBuildingCount = ScenarioInfo.M5CivBuildingCount - 1

    -- if we have only 3 buildings more than the min, play a warning
    if ScenarioInfo.M5CivBuildingCount == (ScenarioInfo.M5BuildingFailLimit + 4) and ScenarioInfo.M5S1.Active then
        ScenarioFramework.Dialogue(OpStrings.LosingCivs1)
    end

    -- if we have only 1 building more than the min, play another
    if ScenarioInfo.M5CivBuildingCount == (ScenarioInfo.M5BuildingFailLimit + 1) and ScenarioInfo.M5S1.Active then
        ScenarioFramework.Dialogue(OpStrings.LosingCivs2)
    end
end

function Mission5Part2()
    -------------------------------------------
    -- Primary Objective 3 - Destroy Enemy Base
    -------------------------------------------
    ScenarioInfo.M5P3 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy Seraphim Base',                 -- title
        'Eliminate the marked Seraphim structures.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M5_Sera_Main_Base_Area',
                    Category = categories.FACTORY + (categories.TECH2 * categories.ECONOMIC) + (categories.TECH3 * categories.ECONOMIC),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Seraphim
                },
            },
        }
   )
    ScenarioInfo.M5P3:AddResultCallback(
        function(result)
            if(result) then
                -- ScenarioFramework.Dialogue(OpStrings.BaseDestroyed, SACUescape)
                SACUescape()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M5P3)
end

function Mission5Secondary2()
    local watchCommands = {}
    -- ScenarioFramework.Dialogue(OpStrings.M5TrucksReady)
    ScenarioInfo.AllowTruckWarning = true
    ScenarioInfo.M5TruckWarningDialogue = 0
    for i = 1, MaxTrucks do
        ScenarioInfo.TrucksCreated = i
        local unit = ScenarioUtils.CreateArmyUnit('Player', 'M5_Truck_'..ScenarioInfo.TrucksCreated)
        -- ScenarioFramework.CreateUnitDamagedTrigger(M5TruckDamageWarning, unit, .01)
        -- ScenarioFramework.CreateUnitDestroyedTrigger(TruckDestroyed, unit)
        ScenarioFramework.CreateUnitToMarkerDistanceTrigger(TruckRescued, unit, ScenarioUtils.MarkerToPosition('UEF_Secondary_Escort_Marker'), 20)
        ScenarioFramework.CreateUnitToMarkerDistanceTrigger(TruckInBuilding, unit, ScenarioUtils.MarkerToPosition('UEF_Secondary_Escort_Marker'), 10)
        table.insert(ScenarioInfo.Trucks, unit)

        IssueMove({unit}, ScenarioUtils.MarkerToPosition('M5_Truck_ParkSpot_' .. i))
    end

    ------------------------------------------------------
    -- Mission 5 Secondary 3 - Evacuate Civilians - Part 1
    ------------------------------------------------------
    ScenarioInfo.M5S3 = Objectives.Basic(
        'secondary',                                        -- type
        'incomplete',                                       -- complete
        'Evacuate Cicilians',                      -- title
        'Transport all civilian trucks to Quantum Gateway',                      -- description
        Objectives.GetActionIcon('move'),
        {                                                   -- target
            Area = 'UEF_Evac_Area',
            MarkArea = true,
        }
    )
    table.insert(AssignedObjectives, ScenarioInfo.M5S3)
    -- ScenarioFramework.CreateTimerTrigger(M5S5Reminder1, 10*60)
end

function M5TruckDamageWarning()
    if ScenarioInfo.AllowTruckWarning then
        ScenarioInfo.M5TruckWarningDialogue = ScenarioInfo.M2TruckWarningDialogue + 1
        if ScenarioInfo.M5TruckWarningDialogue == 1 then
            ScenarioFramework.Dialogue(OpStrings.M5TruckDamaged1)
            ScenarioInfo.AllowTruckWarning = false
            ScenarioFramework.CreateTimerTrigger(M5TruckWarningUnlock, 30)
        end
        if ScenarioInfo.M5TruckWarningDialogue == 2 then
            ScenarioFramework.Dialogue(OpStrings.M5TruckDamaged2)
            ScenarioInfo.AllowTruckWarning = false
            ScenarioFramework.CreateTimerTrigger(M5TruckWarningUnlock, 30)
        end
    end
end

function M5TruckWarningUnlock()
    ScenarioInfo.AllowTruckWarning = true
end

function TruckDestroyed()
    ScenarioInfo.TrucksDestroyed = ScenarioInfo.TrucksDestroyed + 1
    if(ScenarioInfo.TrucksDestroyed == 1) then
        ScenarioFramework.Dialogue(OpStrings.M5TruckDestroyed1)
    elseif(ScenarioInfo.TrucksDestroyed == 2) then
        ScenarioFramework.Dialogue(OpStrings.M5TruckDestroyed2)
    elseif(ScenarioInfo.TrucksDestroyed == 3) then
        ScenarioFramework.Dialogue(OpStrings.M5TruckDestroyed3)
    end
    if((MaxTrucks - ScenarioInfo.TrucksDestroyed) < RequiredTrucks and ScenarioInfo.M5S3) then
        ScenarioInfo.M5S3:ManualResult(false)
        -- ScenarioFramework.Dialogue(OpStrings.M5AllTrucksDestroyed)
    end
end

function TruckRescued(unit)
    for k,v in ScenarioInfo.Trucks do
        if(v == unit) then
            table.remove(ScenarioInfo.Trucks, k)
        end
    end
    unit:SetCanBeKilled(false)
    IssueStop({unit})
    IssueMove({unit}, ScenarioUtils.MarkerToPosition('UEF_Secondary_Escort_Marker'))
    ScenarioInfo.TrucksEscorted = ScenarioInfo.TrucksEscorted + 1

    if(ScenarioInfo.TrucksEscorted == RequiredTrucks) then
        ScenarioInfo.M5S3:ManualResult(true)
        -- ScenarioFramework.Dialogue(OpStrings.M5AllTruckRescued)
    --[[
    elseif(not ScenarioInfo.TruckArriveLock) then
        if(ScenarioInfo.TrucksEscorted == 1) then
            ScenarioInfo.TruckArriveLock = true
            -- ScenarioFramework.Dialogue(OpStrings.M5TruckRescued1)
            ScenarioFramework.CreateTimerTrigger(M5UnlockTruckArriveDialogue, 15)
        elseif(ScenarioInfo.TrucksEscorted == 2) then
            ScenarioInfo.TruckArriveLock = true
            -- ScenarioFramework.Dialogue(OpStrings.M5TruckRescued2)
            ScenarioFramework.CreateTimerTrigger(M5UnlockTruckArriveDialogue, 15)
        end
    ]]--
    end
end

function M5UnlockTruckArriveDialogue()
    ScenarioInfo.TruckArriveLock = false
end

function TruckInBuilding(unit)
    ScenarioFramework.FakeTeleportUnit(unit, true)
end

function sACUstartevac()
    -- Build Transport
    M5UEFAI.EscapeTransportBuilder()
    LOG('*DEBUG: Transport for sACU under construction')

    --ScenarioFramework.CreateArmyStatTrigger(SACUescape, ArmyBrains[UEF], 'SACUescape',
        --{{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.uea0104}})
end

function SACUescape()
    if ScenarioInfo.M5P1.Active then
        ForkThread(function()
            -- Idealy existing sACU would jump onto a transport and left, but that doesn't work.
            --[[
            --ArmyBrains[UEF]:PBMSetCheckInterval(50000)
            M5UEFAI.DisableBase()
            LOG('*DEBUG: sACU Evac started')
            --WaitSeconds(1)
            -- ScenarioInfo.sACUTransport = ScenarioFramework.GetCatUnitsInArea((categories.uea0104), 'M5_UEF_Island_Base_Area', ArmyBrains[UEF])
            ScenarioInfo.sACUTransport = ScenarioUtils.CreateArmyUnit('UEF', 'Transport')
            -- ScenarioFramework.AttachUnitsToTransports(ScenarioInfo.UEFSACU, {transport})
            -- IssueClearCommands({ScenarioInfo.sACUTransport})
            IssueClearCommands({ScenarioInfo.UEFSACU})
            IssueTransportLoad({ScenarioInfo.UEFSACU}, ScenarioInfo.sACUTransport)
            IssueTransportUnload({ScenarioInfo.sACUTransport}, ScenarioUtils.MarkerToPosition('M5_Transport_Drop'))
            ]]--

            M5UEFAI.DisableBase()

            -- Replace existing sACU with new one, since Base manager doesnt want to let it go :(
            local healthValue = ScenarioInfo.UEFSACU:GetHealth()
            ScenarioInfo.UEFSACU:Destroy()

            ScenarioInfo.UEFSACU2 = ScenarioUtils.CreateArmyUnit('UEF', 'Escape_sACU')
            ScenarioInfo.UEFSACU2:SetCustomName( "sCDR Morax" )
            ScenarioInfo.UEFSACU2:CreateEnhancement('AdvancedCoolingUpgrade')
            ScenarioInfo.UEFSACU2:CreateEnhancement('HighExplosiveOrdnance')
            ScenarioInfo.UEFSACU2:CreateEnhancement('Shield')
            ScenarioInfo.UEFSACU2:AdjustHealth(ScenarioInfo.UEFSACU2, healthValue)
            --ScenarioInfo.UEFSACU2:SetCanBeKilled(false)
            --ScenarioInfo.UEFSACU2:SetDoNotTarget(true)
            --ScenarioInfo.UEFSACU2:SetCanTakeDamage(false)

            ScenarioInfo.sACUTransport = ScenarioUtils.CreateArmyUnit('UEF', 'Transport')
            IssueTransportLoad({ScenarioInfo.UEFSACU2}, ScenarioInfo.sACUTransport)
            IssueMove({ScenarioInfo.sACUTransport}, ScenarioUtils.MarkerToPosition('M5_Transport_Marker1'))
            IssueTransportUnload({ScenarioInfo.sACUTransport}, ScenarioUtils.MarkerToPosition('M5_Transport_Drop'))

            local AirUnits = ScenarioFramework.GetCatUnitsInArea(categories.AIR * categories.MOBILE, 'M5_UEF_Island_Base_Area', ArmyBrains[UEF])
            for k, unit in AirUnits do
                if (unit and not unit:IsDead()) then
                    IssueClearCommands({ unit })
                    IssueGuard({ unit }, ScenarioInfo.sACUTransport)
                end
            end

            ScenarioFramework.CreateUnitToMarkerDistanceTrigger(SACUInBuilding, ScenarioInfo.UEFSACU2, ScenarioUtils.MarkerToPosition('UEF_Secondary_Escort_Marker'), 5)

            WaitSeconds(5)

            while(not ScenarioInfo.UEFSACU2:IsDead() and ScenarioInfo.UEFSACU2:IsUnitState('Attached')) do
                WaitSeconds(.5)
            end

            IssueMove({ScenarioInfo.UEFSACU2}, ScenarioUtils.MarkerToPosition('UEF_Secondary_Escort_Marker'))

            for k, unit in AirUnits do
                if (unit and not unit:IsDead()) then
                    IssueClearCommands({ unit })
                    IssueGuard({ unit }, ScenarioInfo.UEFSACU2)
                end
            end
        end)
    end
end

function SACUInBuilding()
    ScenarioFramework.FakeTeleportUnit(ScenarioInfo.UEFSACU2, true)
    -- ScenarioFramework.Dialogue(OpStrings.sACUEscaped, FinalObjective, true)
    ScenarioInfo.M5P1:ManualResult(true)
    FinalObjective()
end

-------------
-- Final Part
-------------
function SecondSeraACU()
    ScenarioFramework.SetPlayableArea('M6_Area', true)
    -- ScenarioUtils.CreateArmyGroup('Seraphim', 'M6_Island_Base')
    ScenarioUtils.CreateArmyGroup('Seraphim', 'M6_Sera_MEX1')
    ScenarioUtils.CreateArmyGroup('Seraphim', 'M6_Sera_FACT1')
    ScenarioUtils.CreateArmyGroup('Seraphim', 'M6_Sera_FACT2')
    ScenarioUtils.CreateArmyGroup('Seraphim', 'M6_Sera_FACN')
    ScenarioUtils.CreateArmyGroup('Seraphim', 'M6_Sera_MEX2')
    LOG('*DEBUG: Second ACU Spawned')

    -------------
    -- Second ACU
    -------------
    ScenarioInfo.EastSeraCDR = ScenarioUtils.CreateArmyUnit('Seraphim', 'M6_SeraACU')
    -- ScenarioInfo.EastSeraCDR:PlayCommanderWarpInEffect()
    ScenarioInfo.EastSeraCDR:CreateEnhancement('ResourceAllocationAdvanced')
    ScenarioInfo.EastSeraCDR:CreateEnhancement('T3Engineering')
    ScenarioInfo.EastSeraCDR:CreateEnhancement('RateOfFire')
    
    -- ScenarioFramework.CreateUnitDamagedTrigger(FletcherWarp, ScenarioInfo.FletcherCDR, .8)
    -- FletcherTM:AddTauntingCharacter(ScenarioInfo.FletcherCDR)
    ScenarioInfo.EastSeraCDR:SetCustomName( "Evil One" )

    M6SeraphimAI.SeraphimM6IslandBaseAI()
--[[
    ScenarioFramework.CreateArmyStatTrigger(M6T1FactoryBuilt, ArmyBrains[Seraphim], 'M6T1FactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 1, Category = categories.FACTORY * categories.TECH1 * categories.NAVAL}})

    ScenarioFramework.CreateArmyStatTrigger(M6T3FactoryBuilt, ArmyBrains[Seraphim], 'M6T3FactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 1, Category = categories.FACTORY * categories.TECH2 * categories.NAVAL}})
]]--
    ScenarioFramework.CreateArmyStatTrigger(M6SeraphimAI.NewEngineerCount1, ArmyBrains[Seraphim], 'NewEngCount1',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 6, Category = categories.FACTORY * categories.AIR * categories.TECH3}})

    ScenarioFramework.CreateArmyStatTrigger(M6SeraphimAI.NewEngineerCount2, ArmyBrains[Seraphim], 'NewEngCount2',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 12, Category = categories.FACTORY * categories.AIR * categories.TECH3}})

    ScenarioFramework.CreateArmyStatTrigger(M6SeraphimAI.NewEngineerCount3, ArmyBrains[Seraphim], 'NewEngCount3',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 18, Category = categories.FACTORY * categories.TECH3}})

    ScenarioFramework.CreateArmyStatTrigger(M6SeraphimAI.SeraphimM6IslandBaseAirAttacks, ArmyBrains[Seraphim], '3+T3AirFacs',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 3, Category = categories.xsb0302}})

    ScenarioFramework.CreateArmyStatTrigger(M6SeraphimAI.SeraphimM6IslandBaseNavalAttacks, ArmyBrains[Seraphim], '3+T3NavalFacs',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 1, Category = categories.xsb0303}})
end
--[[
function M6T1FactoryBuilt()
    local factory = ScenarioFramework.GetCatUnitsInArea((categories.FACTORY * categories.NAVAL), 'M6_Sera_Base_Area', ArmyBrains[Seraphim])
    IssueGuard({ScenarioInfo.EastSeraCDR}, factory[1])
end

function M6T3FactoryBuilt()
    local factory = ScenarioFramework.GetCatUnitsInArea((categories.FACTORY * categories.AIR), 'M6_Sera_Base_Area', ArmyBrains[Seraphim])
    
    IssueStop({ScenarioInfo.EastSeraCDR})
    IssueClearCommands({ScenarioInfo.EastSeraCDR})
    
    IssueGuard({ScenarioInfo.EastSeraCDR}, factory[2])

    ScenarioFramework.CreateArmyStatTrigger(M6T3AirFactory2Built, ArmyBrains[Seraphim], 'M6T3AirFactory2Built',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 1, Category = categories.xsb0302}})
end

function M6T3AirFactory2Built()
    local factory = ScenarioFramework.GetCatUnitsInArea((categories.FACTORY * categories.AIR), 'M6_Sera_Base_Area', ArmyBrains[Seraphim])
    
    IssueStop({ScenarioInfo.EastSeraCDR})
    IssueClearCommands({ScenarioInfo.EastSeraCDR})
    
    IssueGuard({ScenarioInfo.EastSeraCDR}, factory[2])

    ScenarioFramework.CreateArmyStatTrigger(M6T3AirFactory3Built, ArmyBrains[Seraphim], 'M6T3AirFactory3Built',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Area = 'M6_Sera_Base_Area', Value = 2, Category = categories.xsb0302}})
end

function M6T3AirFactory3Built()
    IssueStop({ScenarioInfo.EastSeraCDR})
    IssueClearCommands({ScenarioInfo.EastSeraCDR})
end
]]--

function FinalObjective()
    ---------------------------------------
    -- Primary Objective - Leave the Planet
    ---------------------------------------
    ScenarioInfo.M6P1 = Objectives.SpecificUnitsInArea(
        'primary',                      -- type
        'incomplete',                   -- status
        'Leave the Planet',  -- title
        'Escape the planet using Quantum Gateway',  -- description
        {                               -- target
            Units = {ScenarioInfo.PlayerCDR},
            Area = 'ACU_Evac_Area',
            MarkArea = true,
        }
   )
    ScenarioInfo.M6P1:AddResultCallback(
        function(result)
            if result then
                ScenarioFramework.FakeTeleportUnit(ScenarioInfo.PlayerCDR, true)
                ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.PlayerCDR)

                --ScenarioInfo.PlayerCDRThroughTheGate = true
                PlayerWin()
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M3P1)
end

function FinalNavalAttacks()
    -- function for continuous attacks that very nicely replaces time limit. If you dont finish the mission before this function kicks in, too bad.
    -- Spawns random attack group sends on patrol. Waits a bit and repeat. Strenght of groups is from 1 to 3 where 3 has the most fire power.
    -- North Naval Attacks
    ForkThread(
        function()      
            local NorthNavalGroups = {
                "FA_NavalN1_P1",
                "FA_NavalN1_P2",
                "FA_NavalN1_P3",
                "FA_NavalN2_P1",
                "FA_NavalN2_P2",
                "FA_NavalN2_P3",
                "FA_NavalN3_P1",
                "FA_NavalN3_P2",
                "FA_NavalN3_P3",
            }
             
            local NorthNavalChains = {
                "FA_North_Naval_Chain_1",
                "FA_North_Naval_Chain_2",
                "FA_North_Naval_Chain_3",
            }
            --[[
            while true do
                local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', NorthNavalGroups[math.random(1, table.getn(NorthNavalGroups))], 'AttackFormation')
                for k, v in EntityCategoryFilterDown(categories.xss0201, units:GetPlatoonUnits()) do
                    IssueDive({v})
                end
                ScenarioFramework.PlatoonPatrolChain(units, NorthNavalChains[math.random(1, table.getn(NorthNavalChains))])
                WaitSeconds(Random(20, 60))
            end
            ]]--
            local N_units = nil
            while true do
                local N_group = NorthNavalGroups[math.random(1, table.getn(NorthNavalGroups))]
                local N_chain = NorthNavalChains[math.random(1, table.getn(NorthNavalChains))]
         
                local N_units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', N_group, 'GrowthFormation')
                for k, v in EntityCategoryFilterDown(categories.xss0201, N_units:GetPlatoonUnits()) do
                    IssueDive({v})
                end
                ScenarioFramework.PlatoonPatrolChain(N_units, N_chain)
                LOG('*DEBUG: Spawned units of group "'..N_group..'" for chain "'..N_chain..'"')
                WaitSeconds(Random(80, 120))
            end
        end
    )
    ForkThread(
        function()      
            -- West Naval Attacks
            local WestNavalGroups = {
                "FA_NavalW1_P1",
                "FA_NavalW1_P2",
                "FA_NavalW1_P3",
                "FA_NavalW2_P1",
                "FA_NavalW2_P2",
                "FA_NavalW2_P3",
            }
             
            local WestNavalChains = {
                "M5_Sera_Main_Naval_AttackPlayer_Chain1",
                "M5_Sera_Main_Naval_AttackPlayer_Chain2",
                "M5_Sera_Main_Naval_AttackPlayer_Chain3",
            }

            local W_units = nil
            while true do
                local W_group = WestNavalGroups[math.random(1, table.getn(WestNavalGroups))]
                local W_chain = WestNavalChains[math.random(1, table.getn(WestNavalChains))]
         
                local W_units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', W_group, 'GrowthFormation')
                for k, v in EntityCategoryFilterDown(categories.xss0201, W_units:GetPlatoonUnits()) do
                    IssueDive({v})
                end
                ScenarioFramework.PlatoonPatrolChain(W_units, W_chain)
                LOG('*DEBUG: Spawned units of group "'..W_group..'" for chain "'..W_chain..'"')
                WaitSeconds(Random(90, 115))
            end
        end
    )
    ForkThread(
        function()
            -- East Naval Attacks
            local EastNavalGroups = {
                "FA_NavalE1_P1",
                "FA_NavalE1_P2",
                "FA_NavalE1_P3",
                "FA_NavalE2_P1",
                "FA_NavalE2_P2",
                "FA_NavalE2_P3",
                "FA_NavalE3_P1",
                "FA_NavalE3_P2",
                "FA_NavalE3_P3",
            }
             
            local EastNavalChains = {
                "FA_East_Naval_Chain_1",
                "FA_East_Naval_Chain_2",
            }

            local E_units = nil
            while true do
                local E_group = EastNavalGroups[math.random(1, table.getn(EastNavalGroups))]
                local E_chain = EastNavalChains[math.random(1, table.getn(EastNavalChains))]
         
                local E_units = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', E_group, 'GrowthFormation')
                for k, v in EntityCategoryFilterDown(categories.xss0201, E_units:GetPlatoonUnits()) do
                    IssueDive({v})
                end
                ScenarioFramework.PlatoonPatrolChain(E_units, E_chain)
                LOG('*DEBUG: Spawned units of group "'..E_group..'" for chain "'..E_chain..'"')
                WaitSeconds(Random(75, 125))
            end
        end
    )
end

----------------------
-- Objective Reminders
----------------------

-- M1
function M1P1Reminder1()
    if ScenarioInfo.M1BaseDialoguePlayer == false and ScenarioInfo.M1P1.Active then
        ScenarioFramework.Dialogue(OpStrings.base1remind1)
        ScenarioFramework.CreateTimerTrigger(M1P1Reminder2, 15*60)
    end
end

function M1P1Reminder2()
    if ScenarioInfo.M1BaseDialoguePlayer == false and ScenarioInfo.M1P1.Active then
        ScenarioFramework.Dialogue(OpStrings.base1remind2)
    end
end

function M1P1Reminder3()
    if ScenarioInfo.M1BaseDialoguePlayer == true and ScenarioInfo.M1P1.Active then
        ScenarioFramework.Dialogue(OpStrings.base2remind1)
    end
end

function M1S1Reminder()
    while ScenarioInfo.M1S1.Active do
        PlayRandomReminderTaunt()
        WaitSeconds(20*60)
    end
end

function M1S2Reminder()
    while ScenarioInfo.M1S2.Active and not ScenarioInfo.M1S1.Active do
        PlayRandomReminderTaunt()
        WaitSeconds(20*60)
    end
end

-- M2
function M2P1Reminder1()
    if ScenarioInfo.M2P1.Active then
        ScenarioFramework.Dialogue(OpStrings.southbaseremind1)
        ScenarioFramework.CreateTimerTrigger(M2P1Reminder2, 15*60)
    end
end

function M2P1Reminder2()
    if ScenarioInfo.M2P1.Active then
        ScenarioFramework.Dialogue(OpStrings.southbaseremind2)
    end
end

function M2S1Reminder()
    while ScenarioInfo.M2S1.Active do
        PlayRandomReminderTaunt()
        WaitSeconds(20*60)
    end
end

-- M3
function M3P1Reminder1()
    if ScenarioInfo.M3P1.Active then
        ScenarioFramework.Dialogue(OpStrings.airbaseremind1)
        ScenarioFramework.CreateTimerTrigger(M3P1Reminder2, 25*60)
    end
end

function M3P1Reminder2()
    if ScenarioInfo.M3P1.Active then
        ScenarioFramework.Dialogue(OpStrings.airbaseremind2)
    end
end

-- Epic random reminders by Washy
function PlayRandomReminderTaunt()
    local minPlayed = ReminderTaunts[1][2]
    for _, taunt in ReminderTaunts do
        if (taunt[2] < minPlayed) then
            minPlayed = taunt[2]
        end
    end
   
    while (true) do
        tauntToTest = ReminderTaunts[math.random(1, table.getn(ReminderTaunts))]
        if(tauntToTest[2] == minPlayed) then
            tauntToTest[2] = tauntToTest[2] + 1
            ScenarioFramework.Dialogue(tauntToTest[1], nil, true)
            break
        end
    end
end

---------
-- Taunts
---------

function SetupWestM5Taunts()
    --ZottooWestTM:AddUnitKilledTaunt('TAUNT1', ScenarioInfo.UnitNames[Seraphim]['M1_Seraph_East_AC'])
    ZottooWestTM:AddUnitsKilledTaunt('TAUNT2', ArmyBrains[Seraphim], categories.FACTORY * categories.NAVAL, 5)
    ZottooWestTM:AddUnitsKilledTaunt('TAUNT3', ArmyBrains[UEF], categories.NAVAL * categories.MOBILE, 20)
    ZottooWestTM:AddUnitsKilledTaunt('TAUNT4', ArmyBrains[Player], categories.TECH2 * categories.NAVAL, 10)
    ZottooWestTM:AddDamageTaunt('TAUNT5', ScenarioInfo.PlayerCDR, .02)
end

function SetupSACUM5Warnings()
    SACUTM:AddDamageTaunt('sACUDamaged25', ScenarioInfo.UEFSACU, .25)            --SACU damaged to x
    SACUTM:AddDamageTaunt('sACUDamaged50', ScenarioInfo.UEFSACU, .50)
    SACUTM:AddDamageTaunt('sACUDamaged75', ScenarioInfo.UEFSACU, .75)
    SACUTM:AddDamageTaunt('sACUDamaged90', ScenarioInfo.UEFSACU, .90)
end

------------------
-- Debug Functions
------------------

function OnShiftF4()
    SACUescape()
end

function OnCtrlF4()
    FinalNavalAttacks()
end