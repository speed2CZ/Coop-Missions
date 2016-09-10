-- Custom Mission
-- Author: speed2
local Cinematics = import('/lua/cinematics.lua')
local CustomFunctions = import('/maps/SeraMission1/SeraMission1_CustomFunctions.lua')
local M1OrderAI = import('/maps/SeraMission1/SeraMission1_m1orderai.lua')
local M1UEFAI = import('/maps/SeraMission1/SeraMission1_m1uefai.lua')
local M2CybranAI = import('/maps/SeraMission1/SeraMission1_m2cybranai.lua')
local M2OrderAI = import('/maps/SeraMission1/SeraMission1_m2orderai.lua')
local M2UEFAI = import('/maps/SeraMission1/SeraMission1_m2uefai.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local OpStrings = import('/maps/SeraMission1/SeraMission1_strings.lua')
local PingGroups = import('/lua/ScenarioFramework.lua').PingGroups
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
-- local TauntManager = import('/lua/TauntManager.lua')

----------
-- Globals
----------
ScenarioInfo.Player = 1
ScenarioInfo.UEF = 2
ScenarioInfo.Order = 3
ScenarioInfo.Cybran = 4
ScenarioInfo.Objective = 5
ScenarioInfo.Coop1 = 6
ScenarioInfo.Coop2 = 7
ScenarioInfo.Coop3 = 8

ScenarioInfo.OperationScenarios = {
    M1 = {
        Events = {
            {
                CallFunction = function() M1RiptideAttack() end,
                Delay = {10*60, 8*60, 6*60},
            },
            {
                CallFunction = function() M1SubmarineAttack() end,
                Delay = {9*60, 7*60, 5*60},
            },
        },
    },
    M2 = {
        Bases = {
            {
                CallFunction = function(baseType)
                    M2CybranIslandUnits(baseType)
                    M2CybranAI.CybranM2IslandBaseAI(baseType)
                end,
                Types = {'Air', 'Arty', 'Eco', 'Naval'},
            },
            {
                CallFunction = function(baseType) M2UEFAI.UEFM2IslandBaseAI(baseType) end,
                Types = {'Eco', 'Gate', 'Nuke'},
            },
        },
        Events = {
            {
                CallFunction = function() M2BattleshipAttack() end,
                Delay = {15*60, 11*60, 7*60},
            },
            {
                CallFunction = function() M2CybranNukeSubAttack() end,
                Delay = {19*60, 15*60, 11*60},
            },
            {
                CallFunction = function() M2ExperimentalAttack() end,
                Delay = {17*60, 13*60, 9*60},
            },
        },
    },
    M3 = {
        Bases = {
            {},
        },
        Events = {
            {},
        },
    },
}

---------
-- Locals
---------
local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local Order = ScenarioInfo.Order
local Cybran = ScenarioInfo.Cybran
local Objective = ScenarioInfo.Objective
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3

local AssignedObjectives = {}
local Difficulty = ScenarioInfo.Options.Difficulty

-- How long should we wait at the beginning of the NIS to allow slower machines to catch up?
local NIS1InitialDelay = 3

--------------
-- Debug only!
--------------
local Debug = false
local SkipDialogues = false
local SkipNIS1 = false
local SkipNIS2 = false

-----------
-- Start Up
-----------
function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()

    -- Sets Army Colors
    ScenarioFramework.SetSeraphimColor(Player)
    ScenarioFramework.SetUEFPlayerColor(UEF)
    ScenarioFramework.SetCybranPlayerColor(Cybran)
    ScenarioFramework.SetNeutralColor(Objective)
    ScenarioFramework.SetAeonEvilColor(Order)

    -- TODO: check colors, coop1,3 should have something similar to Order color, coop 1 order color maybe, coop 2 some seraphim-ish color
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

    -- Unit Cap
    ScenarioFramework.SetSharedUnitCap(1000)

    -- Disable resource sharing from friendly AI
    GetArmyBrain(Order):SetResourceSharing(false)

    -- If there is not Coop1 player then use Order AI
    if not tblArmy[ScenarioInfo.Coop1] then
        ScenarioInfo.UseOrderAI = true
    end

    --------
    -- Order
    --------
    -- Economy buildings for Carrier
    ScenarioInfo.M1_Order_Eco = ScenarioUtils.CreateArmyGroup('Order', 'M1_Order_Economy')

    -- Carrier
    ScenarioInfo.M1_Order_Carrier = ScenarioUtils.CreateArmyUnit('Order', 'M1_Order_Carrier')
    -- ScenarioInfo.M1_Order_Carrier:SetVeterancy(4 - Difficulty)

    -- Carrier fleet
    ScenarioInfo.M1_Carrier_Fleet = ScenarioUtils.CreateArmyGroup('Order', 'M1_Order_Carrier_Fleet_D' .. Difficulty)

    -- Carrier Air units
    local cargoUnits = ScenarioUtils.CreateArmyGroup('Order', 'M1_Oder_Init_Air_D' .. Difficulty)
    for _, unit in cargoUnits do
        IssueStop({unit})
        ScenarioInfo.M1_Order_Carrier:AddUnitToStorage(unit)
    end

    -- Move Carrier to starting position together with the fleet
    IssueMove({ScenarioInfo.M1_Order_Carrier}, ScenarioUtils.MarkerToPosition('M1_Order_Carrier_Start_Marker'))
    IssueGuard(ScenarioInfo.M1_Carrier_Fleet, ScenarioInfo.M1_Order_Carrier)

    ForkThread(function()
        while (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() and ScenarioInfo.M1_Order_Carrier:IsUnitState('Moving')) do
            WaitSeconds(.5)
        end

        -- Give Naval fleet to player and put on a patrol
        local givenNavalUnits = {}

        for _, unit in ScenarioInfo.M1_Carrier_Fleet do
            IssueClearCommands({unit})
            local tempUnit = ScenarioFramework.GiveUnitToArmy(unit, 'Player')
            table.insert(givenNavalUnits, tempUnit) 
        end

        ScenarioFramework.GroupPatrolChain(givenNavalUnits, 'M1_Oder_Naval_Def_Chain')

        -- Release air units from carrier, give them to player and put on a patrol
        local givenAirUnits = {}

        IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
        IssueTransportUnload({ScenarioInfo.M1_Order_Carrier}, ScenarioInfo.M1_Order_Carrier:GetPosition())

        for _, unit in cargoUnits do
            while (not unit:IsDead() and unit:IsUnitState('Attached')) do
                WaitSeconds(3)
            end
            IssueClearCommands({unit})
            local tempUnit
            if ScenarioInfo.UseOrderAI then
                tempUnit = ScenarioFramework.GiveUnitToArmy(unit, 'Player')
            else
                tempUnit = ScenarioFramework.GiveUnitToArmy(unit, 'Coop1')
            end
            table.insert(givenAirUnits, tempUnit) 
        end

        ScenarioFramework.GroupPatrolChain(givenAirUnits, 'M1_Oder_Naval_Def_Chain')

        -- Start building units from the carrier once on it's place
        M1OrderAI.OrderCarrierFactory()
    end)

    -- Tempest
    ScenarioInfo.M1_Order_Tempest = ScenarioUtils.CreateArmyUnit('Order', 'M1_Order_Tempest')
    ScenarioInfo.M1_Order_Tempest:HideBone('Turret', true)
    ScenarioInfo.M1_Order_Tempest:HideBone('Turret_Muzzle', true)
    ScenarioInfo.M1_Order_Tempest:SetWeaponEnabledByLabel('MainGun', false)

    -- Move Tempest to starting position
    IssueMove({ScenarioInfo.M1_Order_Tempest}, ScenarioUtils.MarkerToPosition('M1_Order_Tempest_Start_Marker'))

    ForkThread(function()
        while (ScenarioInfo.M1_Order_Tempest and not ScenarioInfo.M1_Order_Tempest:IsDead() and ScenarioInfo.M1_Order_Tempest:IsUnitState('Moving')) do
            WaitSeconds(.5)
        end

        IssueClearCommands({ScenarioInfo.M1_Order_Tempest})

        -- Start building units from the tempest once on it's place
        M1OrderAI.OrderTempestFactory()
    end)

    -- Sonar, only for easy/medium difficulty
    if Difficulty <= 2 then
        ScenarioInfo.M1_Order_Sonar = ScenarioUtils.CreateArmyUnit('Order', 'M1_Order_Sonar')

        -- Move Sonar to starting position
        IssueMove({ScenarioInfo.M1_Order_Sonar}, ScenarioUtils.MarkerToPosition('M1_Order_Sonar_Start_Marker'))
    end
    
    ---------
    -- UEF AI
    ---------
    M1UEFAI.UEFM1BaseAI()

    -- Walls
    ScenarioUtils.CreateArmyGroup('UEF', 'M1_UEF_Walls')
    
    -- UEF Patrols
    -- Air
    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Base_Air_Patrol_D' .. Difficulty, 'NoFormation')
    for _, v in platoon:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_UEF_Base_Air_Patrol_Chain')))
    end

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Random_Air_Patrol_D' .. Difficulty, 'NoFormation')
    for _, v in platoon:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_UEF_Naval_Random_Patrol_Chain')))
    end
    
    -- Land
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Base_Titan_Patrol', 'AttackFormation')
    for _, v in platoon:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolChain({v}, 'M1_UEF_Base_Titan_Patrol_Chain')
    end

    -- platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Base_Land_Patrol_1_D' .. Difficulty, 'AttackFormation')

    -- Naval
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Base_Naval_Patrol_D' .. Difficulty, 'NoFormation')
    for _, v in platoon:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolChain({v}, 'M1_UEF_Base_Naval_Patrol_Chain')
    end

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Patrol_NE_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_UEF_Naval_NE_Chain')

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Patrol_West_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_UEF_Naval_West_Chain')

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Random_Patrol_D' .. Difficulty, 'GrowthFormation')
    for _, v in platoon:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_UEF_Naval_Random_Patrol_Chain')))
    end

    -- Test ACU
    -- ScenarioInfo.M1UEFACU = ScenarioFramework.SpawnCommander('UEF', 'M1_UEF_ACU', false, 'TestACU')

    ------------
    -- Civilians
    ------------
    -- Objective target, with extra health
    ScenarioInfo.M1ResearchStation = ScenarioUtils.CreateArmyUnit('Objective', 'M1_Research_Station')
    ScenarioInfo.M1ResearchStation:SetCustomName('Novax Station Gama')
    ScenarioInfo.M1ResearchStation:SetMaxHealth(6250)
    ScenarioInfo.M1ResearchStation:SetHealth(ScenarioInfo.M1ResearchStation, 6250)

    -- Other buildings
    ScenarioUtils.CreateArmyGroup('Objective', 'M1_Civilian_Complex')
    ScenarioUtils.CreateArmyGroup('Objective', 'M1_Walls')

    -- Restrict playable area
    ScenarioFramework.SetPlayableArea('M1_Area', false)
end

function OnStart(scenario)
    -- Build Restrictions
    for _, Player in ScenarioInfo.HumanPlayers do
        ScenarioFramework.AddRestriction(Player, categories.xsa0402 + categories.xsb2401) -- T4 Bomber, T4 Nuke
    end
    
    -- Initialize camera
    if not SkipNIS1 then
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_1'))
    end

    ForkThread(IntroMission1NIS)
end

------------
-- Mission 1
------------
function IntroMission1NIS()
	if not SkipNIS1 then
        Cinematics.EnterNISMode()

        -- Vision for NIS location
        local VisMarker1_1 = ScenarioFramework.CreateVisibleAreaLocation(60, 'M1_UEF_Base_Marker', 0, ArmyBrains[Player])
        local VisMarker1_2 = ScenarioFramework.CreateVisibleAreaLocation(25, 'M1_Civilian_Vision_Marker', 0, ArmyBrains[Player])
        local VisMarker1_3 = ScenarioFramework.CreateVisibleAreaAtUnit(60, ScenarioInfo.UnitNames[UEF]['UEF_NIS_Unit'], 0, ArmyBrains[Player])

        WaitSeconds(NIS1InitialDelay)
        ScenarioFramework.Dialogue(OpStrings.Intro_Research_Station, nil, true)

        WaitSeconds(5)

        ScenarioFramework.Dialogue(OpStrings.Intro_UEF_Base, nil, true)
        Cinematics.CameraMoveToMarker('Cam_1_2', 4)

        WaitSeconds(2)

        ScenarioFramework.Dialogue(OpStrings.Intro_Patrols, nil, true)
        Cinematics.CameraTrackEntity(ScenarioInfo.UnitNames[UEF]['UEF_NIS_Unit'], 40, 4)

        WaitSeconds(2)

        ScenarioFramework.Dialogue(OpStrings.Intro_Carriers, nil, true)
        Cinematics.CameraMoveToMarker('Cam_1_3', 5)

        WaitSeconds(3)

        Cinematics.CameraMoveToMarker('Cam_1_4', 4)

        WaitSeconds(3)

        VisMarker1_1:Destroy()
        VisMarker1_2:Destroy()
        VisMarker1_3:Destroy()

        if Difficulty == 3 then
            ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_UEF_Base_Marker'), 80)
        end

        Cinematics.ExitNISMode()
	end
	IntroMission1()
end

function IntroMission1()
    ScenarioInfo.MissionNumber = 1

    -- Resources for AI, slightly delayed cause army didn't recieve it for some reason
    ForkThread(function()
        WaitSeconds(2)
        ArmyBrains[UEF]:GiveResource('MASS', 10000)
        ArmyBrains[Objective]:GiveResource('ENERGY', 10000)
    end)

    if Debug then
        Utilities.UserConRequest('SallyShears')
    end
    if SkipDialogues then
        StartMission1()
    else
        ScenarioFramework.Dialogue(OpStrings.M1_Kill_Research_Station_1, StartMission1, true)
    end
end

-- Assign objetives
function StartMission1()
    ----------------------------------------------
    -- Primary Objective 1 - Kill Research Station
    ----------------------------------------------
    ScenarioInfo.M1P1 = Objectives.Kill(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.M1_P1_Title,          -- title
        OpStrings.M1_P1_Description,    -- description
        {                               -- target
            Units = {ScenarioInfo.M1ResearchStation},
            FlashVisible = true,
        }
    )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(result) then
                if ScenarioInfo.M1S1.Active then
                    ScenarioFramework.Dialogue(OpStrings.M1_Research_Station_Killed_1, nil, true)
                else
                    ScenarioFramework.Dialogue(OpStrings.M1_Research_Station_Killed_2, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P1)

    ----------------------------------------------
    -- Secondary Objective 1 - Clear Landing Areas
    ----------------------------------------------
    ScenarioInfo.M1S1 = Objectives.CategoriesInArea(
        'secondary',                    -- type
        'incomplete',                   -- complete
        OpStrings.M1_S1_Title,          -- title
        OpStrings.M1_S1_Description,    -- description
        'kill',                         -- action
        {                               -- target
            -- MarkArea = true,
            Requirements = {
                {   
                    Area = 'M1_UEF_Base_Area',
                    Category = categories.ALLUNITS - categories.WALL,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
            },
        }
    )
    ScenarioInfo.M1S1:AddResultCallback(
        function(result)
            if(result) then
                -- End other objectives if they are active
                if ScenarioInfo.M1P2.Active then
                    ScenarioInfo.M1P2:ManualResult(true)
                end
                if ScenarioInfo.M1P3.Active then
                    ScenarioInfo.M1P3:ManualResult(true)
                end
                -- Destroy skip button
                if ScenarioInfo.GateInPing then
                    ScenarioInfo.GateInPing:Destroy()
                end
                -- Proceed to next mission if we aren't there yet
                if ScenarioInfo.MissionNumber == 1 then
                    ScenarioFramework.Dialogue(OpStrings.M1_Landing_Area_Cleared, IntroMission2, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1S1)

    -- Pick a random event for the first part of the mission
    CustomFunctions.ChooseRandomEvent(true)

    -- Post objective dialogue
    ScenarioFramework.CreateTimerTrigger(M1PostObjectiveDialogue, 8)
end

function M1PostObjectiveDialogue()
    ScenarioFramework.Dialogue(OpStrings.M1_Kill_Research_Station_2)

    -- Assign objective to protect mobile factories after a bit
    ScenarioFramework.CreateTimerTrigger(M1ProtectCarriersObjective, 30)
end

function M1ProtectCarriersObjective()
    -- Announce protect carriers objective
    ScenarioFramework.Dialogue(OpStrings.M1_Protect_Carriers, nil, true)

    ----------------------------------------
    -- Primary Objective 2 - Protect Carrier
    ----------------------------------------
    ScenarioInfo.M1P2 = Objectives.Protect(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.M1_P2_Title,          -- title
        OpStrings.M1_P2_Description,    -- description
        {                               -- target
            Units = {ScenarioInfo.M1_Order_Carrier, ScenarioInfo.M1_Order_Tempest},
            NumRequired = 1,
        }
    )
    ScenarioInfo.M1P2:AddResultCallback(
        function(result, unit)
            if(not result and not ScenarioInfo.OpEnded) then
                ScenarioFramework.Dialogue(OpStrings.M1_Carriers_Died, nil, true)
                M1CarriersDead(unit)
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P2)

    -- Start a timer after 3 minutes
    ScenarioFramework.CreateTimerTrigger(M1TimerObjective, 3 * 60)
end

function M1TimerObjective()
    if ScenarioInfo.MissionNumber ~= 1 then
        return
    end

    -- Announce the timer objective
    ScenarioFramework.Dialogue(OpStrings.M1_Reveal_Timer, nil, true)

    ------------------------------
    -- Primary Objective 3 - Timer
    ------------------------------
    -- Time limit for the first part of the mission
    local num = {30, 25, 20}
    ScenarioInfo.M1P3 = Objectives.Timer(
        'primary',                      -- type
        'incomplete',                   -- complete
        OpStrings.M1_P3_Title,          -- title
        OpStrings.M1_P3_Description,    -- description
        {                               -- target
            Timer = num[Difficulty] * 60,
            ExpireResult = 'failed',
        }
    )
    ScenarioInfo.M1P3:AddResultCallback(
        function(result)
            if not result then
                M1TimeRunsOut()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P3)

    ScenarioFramework.Dialogue(OpStrings.M1_Timer_Revealed) --, nil, true)

    -- Objective reminder, 10 minutes before time's up
    num = {20, 15, 10}
    ScenarioFramework.CreateTimerTrigger(M1TimerObjReminder1, num[Difficulty] * 60)

    ScenarioFramework.CreateTimerTrigger(GateInACUsButton, 6 * 60)
end

-- Button to skip first part
function GateInACUsButton()
    -- Reveal Ping
    ScenarioFramework.Dialogue(OpStrings.M1_Gate_In_Button, nil, true)

    -- Setup ping
    ScenarioInfo.GateInPing = PingGroups.AddPingGroup(OpStrings.GateIn_Button_Title, 'xsl0001', 'attack', OpStrings.GateIn_Button_Description)
    ScenarioInfo.GateInPing:AddCallback(GateInDialogue)
end

function GateInDialogue()
    -- Create a comfirmation dialogue for skipping to next part of the mission
    local dialogue = CreateDialogue(OpStrings.GateIn_Dialogue, {'<LOC _Yes>', '<LOC _No>'})
    dialogue.OnButtonPressed = function(self, info)
        dialogue:Destroy()
        if info.buttonID == 1 then
            dialogue:Destroy()
            ScenarioInfo.M1P2:ManualResult(true) -- Protct objective
            ScenarioInfo.M1P3:ManualResult(true) -- Timer
            ScenarioInfo.GateInPing:Destroy()
            IntroMission2()
        end
    end
end

-- Random Events
function M1RiptideAttack()
    -- Attack around the west edge of the map, first attacks the Tempest
    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Riptides_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_UEF_Riptide_Chain')

    -- Pick event again
    CustomFunctions.ChooseRandomEvent(true, {7*60, 5*60, 3*60})
end

function M1SubmarineAttack()
    -- Spawn submarines, move them closer to the Carrier and attack it
    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_UEF_Submarines_D' .. Difficulty, 'AttackFormation')

    ScenarioFramework.PlatoonMoveRoute(platoon, {'M1_UEF_Submarine_Marker'})
    platoon:AttackTarget(ScenarioInfo.M1_Order_Carrier)

    -- TODO: Attack tempest if carries is dead

    -- Pick event again
    CustomFunctions.ChooseRandomEvent(true, {7*60, 5*60, 3*60})
end

-- Reminders
function M1TimerObjReminder1()
    if not ScenarioInfo.M1P3.Active then
        return
    end

    -- 10 minutes remain
    ScenarioFramework.Dialogue(OpStrings.M1_Timer_Obj_Reminder_1)

    ScenarioFramework.CreateTimerTrigger(M1TimerObjReminder2, 5 * 60)
end

function M1TimerObjReminder2()
    if not ScenarioInfo.M1P3.Active then
        return
    end

    -- 5 minutes remain
    ScenarioFramework.Dialogue(OpStrings.M1_Timer_Obj_Reminder_2)

    ScenarioFramework.CreateTimerTrigger(M1TimerObjReminder3, 4 * 60)
end

function M1TimerObjReminder3()
    if not ScenarioInfo.M1P3.Active then
        return
    end

    -- 1 minute remains
    ScenarioFramework.Dialogue(OpStrings.M1_Timer_Obj_Reminder_3)
end

------------
-- Mission 2
------------
function IntroMission2()
    ForkThread(
        function()
            -- Remove any qeued up dialogues
            ScenarioFramework.FlushDialogueQueue()
            -- If there's some dialogue playing, wait until it's finished
            while(ScenarioInfo.DialogueLock) do
                WaitSeconds(0.2)
            end

            if ScenarioInfo.MissionNumber ~= 1 then
                return
            end
            ScenarioInfo.MissionNumber = 2

            -- Don't produce units for player anymore
            ArmyBrains[Order]:PBMRemoveBuildLocation('M1_Order_Carrier_Start_Marker', 'AircraftCarrier1')
            ArmyBrains[Order]:PBMRemoveBuildLocation('M1_Order_Tempest_Start_Marker', 'Tempest1')

            -- Move Carrier, Tempest and Sonar close to the island
            if ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() then
                IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
                IssueMove({ScenarioInfo.M1_Order_Carrier}, ScenarioUtils.MarkerToPosition('M2_Order_Carrier_Marker_1'))
            end
            if ScenarioInfo.M1_Order_Tempest and not ScenarioInfo.M1_Order_Tempest:IsDead() then
                IssueClearCommands({ScenarioInfo.M1_Order_Tempest})
                IssueMove({ScenarioInfo.M1_Order_Tempest}, ScenarioUtils.MarkerToPosition('M2_Order_Starting_Tempest'))
            end
            if ScenarioInfo.M1_Order_Sonar and not ScenarioInfo.M1_Order_Sonar:IsDead() then
                IssueClearCommands({ScenarioInfo.M1_Order_Sonar})
                IssueMove({ScenarioInfo.M1_Order_Sonar}, ScenarioUtils.MarkerToPosition('Rally Point 03')) -- Naval Rally Point next to the island
            end

            if ScenarioInfo.UseOrderAI then
                -----------
                -- Order AI
                -----------

                -- Spawn Order ACU, sACU
                ScenarioInfo.OrderACU = ScenarioFramework.SpawnCommander('Order', 'M2_Order_ACU', 'Warp', 'Violet', false, false, -- TODO: Come up with a name
                    {'ResourceAllocationAdvanced', 'EnhancedSensors', 'AdvancedEngineering', 'T3Engineering'})
                -- Restrict T2 Torp launchers on the ACU so it won't get killed in the water.
                ScenarioInfo.OrderACU:AddBuildRestriction(categories.AEON * categories.DEFENSE * categories.TECH2 * categories.ANTINAVY)

                -- TODO: make sACU warp effect, name for the sACU
                ScenarioFramework.SpawnCommander('Order', 'M2_Order_sACU', false, false, false, false,
                    {'EngineeringFocusingModule', 'ResourceAllocation'})

                -- Order base AI and mobile factories AI
                M2OrderAI.OrderM2BaseAI()

                -- If there are any units left in the carrier, make them patrol once carrier arrives to the island
                ForkThread(function()
                    WaitSeconds(1) -- This makes sure that the carrier gets moving before we start the check below

                    while (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() and ScenarioInfo.M1_Order_Carrier:IsUnitState('Moving')) do
                        WaitSeconds(.5)
                    end

                    if ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() then
                        if table.getn(ScenarioInfo.M1_Order_Carrier:GetCargo()) > 0  then
                            IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
                            IssueTransportUnload({ScenarioInfo.M1_Order_Carrier}, ScenarioInfo.M1_Order_Carrier:GetPosition())

                            -- Just to be sure all units are out
                            WaitSeconds(5)

                            local plat = ArmyBrains[Order]:MakePlatoon('', '')
                            for _, unit in ArmyBrains[Order]:GetListOfUnits(categories.AIR * categories.MOBILE, false) do
                                ArmyBrains[Order]:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'NoFormation')
                                ScenarioFramework.GroupPatrolRoute({unit}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Order_Base_AirDef_Chain')))
                            end
                        end
                    end
                end)
                
                -- M2OrderAI.OrderM2CarriersAI() -- TODO: Make Order use carrier is some good way

                -- Temporary unit production from the tempest
                M2OrderAI.OrderM2TempestAI(ScenarioInfo.M1_Order_Tempest)

                if Difficulty <= 2 and ScenarioInfo.M1_Order_Sonar and not ScenarioInfo.M1_Order_Sonar:IsDead() then
                    -- Make T3 Sonar Patrol, rebuild if killed
                    local platoon = ArmyBrains[Order]:MakePlatoon('', '')
                    ArmyBrains[Order]:AssignUnitsToPlatoon(platoon, {ScenarioInfo.M1_Order_Sonar}, 'Attack', 'NoFormation')
                    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_Order_Defensive_Chain_Full')
                    ScenarioFramework.CreateUnitDeathTrigger(M2OrderAI.OrderM2RebuildT3Sonar, ScenarioInfo.M1_Order_Sonar)
                else
                    -- There is no sonar on hard difficulty, so set it to be built right away
                    M2OrderAI.OrderM2RebuildT3Sonar()
                end

                -- Make sure the base will get started build fast, reset later
                ArmyBrains[Order]:PBMSetCheckInterval(6)
                ScenarioFramework.CreateTimerTrigger(ResetBuildInterval, 300)

                -- Triggers
                -- Assist first factory once build, get it asap to T3 so T3 engies can build base.
                ScenarioFramework.CreateArmyStatTrigger(M2T1AirFactoryBuilt, ArmyBrains[Order], 'M2T1AirFactoryBuilt',
                    {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH1 * categories.AIR}})

                -- Stop assisting factory once it's on T3, get back to base building.
                ScenarioFramework.CreateArmyStatTrigger(M2T3AirFactoryBuilt, ArmyBrains[Order], 'M2T3AirFactoryBuilt',
                    {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH3 * categories.AIR}})

                -- Build Antinuke once more 5000 mass in the storage
                ScenarioFramework.CreateArmyStatTrigger(M2OrderAI.OrderM2BuildAntiNuke, ArmyBrains[Order], 'M2BuildAntinuke',
                    {{StatType = 'Economy_Stored_Mass', CompareType = 'GreaterThanOrEqual', Value = 5000}})

                -- Rebuild Tempest with a gun once more 10000 mass in the storage
                ScenarioFramework.CreateArmyStatTrigger(M2OrderAI.OrderM2RebuildTempest, ArmyBrains[Order], 'M2RebuildTempest',
                    {{StatType = 'Economy_Stored_Mass', CompareType = 'GreaterThanOrEqual', Value = 10000}})
            else
                -- Spawn Coop1 ACU
                ScenarioInfo.CoopCDR1 = ScenarioFramework.SpawnCommander('Coop1', 'Commander', 'Warp', true, true, false,
                    {'ResourceAllocation', 'AdvancedEngineering', 'T3Engineering'})

                -- Spawn Coop player 3 or sACU for Coop1
                local tblArmy = ListArmies()
                if tblArmy[ScenarioInfo.Coop3] then
                    ScenarioInfo.CoopCDR3 = ScenarioFramework.SpawnCommander('Coop3', 'sACU', 'Warp', true, false, false,
                        {'EngineeringFocusingModule', 'ResourceAllocation'})
                else
                    -- TODO: make sACU warp effect, name for the sACU
                    ScenarioFramework.SpawnCommander('Coop1', 'sACU', false, false, false, false,
                        {'EngineeringFocusingModule', 'ResourceAllocation'})
                end

                -- Give Carrier to coop player, once near island
                ForkThread(function()
                    while (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() and ScenarioInfo.M1_Order_Carrier:IsUnitState('Moving')) do
                        WaitSeconds(.5)
                    end
                    if (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead()) then
                        IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
                        ScenarioFramework.GiveUnitToArmy(ScenarioInfo.M1_Order_Carrier, 'Coop1')
                    end
                end)

                -- Give Tempest to coop player once near island
                -- TODO: Find out if the hidden gun isn't causing problems.
                --       Alternative solution: Ctrl-K once it's arrives / secondary objective to reclaim
                ForkThread(function()
                    while (ScenarioInfo.M1_Order_Tempest and not ScenarioInfo.M1_Order_Tempest:IsDead() and ScenarioInfo.M1_Order_Tempest:IsUnitState('Moving')) do
                        WaitSeconds(.5)
                    end
                    if (ScenarioInfo.M1_Order_Tempest and not ScenarioInfo.M1_Order_Tempest:IsDead()) then
                        IssueClearCommands({ScenarioInfo.M1_Order_Tempest})
                        ScenarioFramework.GiveUnitToArmy(ScenarioInfo.M1_Order_Tempest, 'Coop1')
                    end
                end)

                -- Give Sonar to coop player once near island
                ForkThread(function()
                    while (ScenarioInfo.M1_Order_Sonar and not ScenarioInfo.M1_Order_Sonar:IsDead() and ScenarioInfo.M1_Order_Sonar:IsUnitState('Moving')) do
                        WaitSeconds(.5)
                    end
                    if (ScenarioInfo.M1_Order_Sonar and not ScenarioInfo.M1_Order_Sonar:IsDead()) then
                        IssueClearCommands({ScenarioInfo.M1_Order_Sonar})
                        ScenarioFramework.GiveUnitToArmy(ScenarioInfo.M1_Order_Sonar, 'Coop1')
                    end
                end)
            end

            -- Remove off map Order eco buildings from first objective
            ScenarioFramework.DestroyGroup(ScenarioInfo.M1_Order_Eco)

            -- Temporary restrict T1 and T2 engineers for Order so it builds T3 in the base
            ScenarioFramework.AddRestriction(Order, categories.ual0105 + categories.ual0208)

            ---------
            -- Common
            ---------
            -- Spawn small island bases for both Cybran and UEF, type picked randomly
            CustomFunctions.ChooseRandomBases()

            ------------
            -- Cybran AI
            ------------
            -- Spawn cybran base
            M2CybranAI.CybranM2BaseAI()

            -- Extra main island defences
            ScenarioUtils.CreateArmyGroup('Cybran', 'M2_Cybran_Base_Front_Defences_D' .. Difficulty)

            -- Initial Patrols
            -- Main Base

            -- Naval Patrol 
            local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Naval_Patrol_D' .. Difficulty, 'NoFormation')
            for _, v in platoon:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Cybran_Base_Naval_Defense_Chain')))
            end
            -- On medium and hard difficulty send a new patrol from off map once dead
            if Difficulty >= 2 then
                ScenarioFramework.CreatePlatoonDeathTrigger(M2CybranNavalPatrol, platoon)
            end

            -- Air Patrol
            platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Base_Air_Patrol_D' .. Difficulty, 'NoFormation')
            for _, v in platoon:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Cybran_Base_AirDeffense_Chain')))
            end
            -- ASFs (hard difficulty, sent from off map,)
            if Difficulty == 3 then
                platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Offmap_ASFs', 'NoFormation')
                for _, v in platoon:GetPlatoonUnits() do
                    ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Cybran_Base_AirDeffense_Chain')))
                end
                -- Trigger to rebuild if killed
                ScenarioFramework.CreatePlatoonDeathTrigger(M2CybranASFsPatrol, platoon)
            end

            -- TML Launchers
            for _, unit in ArmyBrains[Cybran]:GetListOfUnits(categories.urb2108, false) do
                local plat = ArmyBrains[Cybran]:MakePlatoon('', '')
                ArmyBrains[Cybran]:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'NoFormation')
                plat:ForkAIThread(plat.TacticalAI)
            end

            -- Walls
            ScenarioUtils.CreateArmyGroup('Cybran', 'M2_Cybran_Walls')
            
            ---------
            -- UEF AI
            ---------
            M2UEFAI.UEFM2BaseAI()

            -- Walls
            ScenarioUtils.CreateArmyGroup('UEF', 'M2_UEF_Walls')
              
            -- TML Launchers
            for k,unit in ArmyBrains[UEF]:GetListOfUnits(categories.ueb2108, false) do
                local plat = ArmyBrains[UEF]:MakePlatoon('', '')
                ArmyBrains[UEF]:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'NoFormation')
                plat:ForkAIThread(plat.TacticalAI)
            end

            --------
            -- Other
            --------
            -- Spawn and open the satellites for the post intro
            ScenarioInfo.M2_Intro_Satellites = ScenarioUtils.CreateArmyGroup('UEF', 'M2_Satellites')
            for _, unit in ScenarioInfo.M2_Intro_Satellites do
                unit:Open()
            end

            -- Destroy all wrecks that are offmap
            for _, prop in GetReclaimablesInRect(ScenarioUtils.AreaToRect('M2_Offmap_Area')) do
                if prop.IsWreckage then
                    prop:Destroy()
                end
            end

            -- Give resources armies
            --ArmyBrains[UEF]:GiveResource('MASS', 25000)
            --ArmyBrains[Order]:GiveResource('MASS', 8000)
            --ArmyBrains[Player]:GiveResource('MASS', 6000)

            ForkThread(IntroMission2NIS)
        end
    )
end

-- Spawn island patrols depending on the base type
function M2CybranIslandUnits(baseType)
    if baseType == 'Naval' then
        -- Naval patrol around the base
        local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Island_Naval_Patrol_D' .. Difficulty, 'NoFormation')
        for _, v in platoon:GetPlatoonUnits() do
            ScenarioFramework.GroupPatrolChain({v}, 'M2_Cybran_Island_Naval_Defense_Chain')
        end

    elseif baseType == 'Air' then
        -- Spawn carriers for unit production
        ScenarioUtils.CreateArmyGroup('Cybran', 'M2_Cybran_Carriers')

        -- Air patrol around the base
        local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Island_Air_Patrol_D' .. Difficulty, 'NoFormation')
        for _, v in platoon:GetPlatoonUnits() do
            ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Cybran_Island_Naval_Defense_Chain')))
        end
    end
end

function IntroMission2NIS()
    ScenarioFramework.SetPlayableArea('M2_Area', false)

    -- Move players' units to the new playable area and patrol
    for _, unit in GetUnitsInRect(ScenarioUtils.AreaToRect('M2_Offmap_Area')) do
        if EntityCategoryContains(categories.AIR, unit ) and unit:GetAIBrain() ~= ArmyBrains[Order] then
            -- Air units need to be warped to the playable area, else they're getting stucked
            IssueClearCommands({unit})
            Warp(unit, ScenarioUtils.MarkerToPosition('M2_Warp_Marker'))
            ScenarioFramework.GroupPatrolRoute({unit}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Order_Base_AirDef_Chain')))
        elseif EntityCategoryContains(categories.NAVAL, unit ) and unit:GetAIBrain() ~= ArmyBrains[Order] then
            IssueClearCommands({unit})
            ScenarioFramework.GroupPatrolChain({unit}, 'M2_Order_Defensive_Chain_West')
        end
    end

    local tblArmy = ListArmies()

    -- Start NIS
    if not SkipNIS2 then
        Cinematics.EnterNISMode()
        -- Ensure that Order starts building base sooner rather than later
        ArmyBrains[Order]:PBMSetCheckInterval(2)

        WaitSeconds(1)
        ScenarioFramework.Dialogue(OpStrings.M2_Intro_1, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_1'), 0)
        WaitSeconds(4)
        
        ScenarioFramework.Dialogue(OpStrings.M2_Intro_2, nil, true)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_2'), 3)

        -- Spawn Player and Coop 2
        ScenarioInfo.PlayerCDR = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true, false,
            {'AdvancedEngineering', 'T3Engineering', 'ResourceAllocation'})

        if tblArmy[ScenarioInfo.Coop2] then
            ScenarioInfo.CoopCDR2 = ScenarioFramework.SpawnCommander('Coop2', 'sACU', false, true, false, false,
                {'EngineeringThroughput', 'EnhancedSensors'})
        else
            -- TODO: make sACU warp effect, name for the sACU
            ScenarioFramework.SpawnCommander('Player', 'sACU', false, false, false, false,
                {'EngineeringThroughput', 'EnhancedSensors'})
        end

        WaitSeconds(3)
        
        Cinematics.ExitNISMode()

        -- Set back to default
        ArmyBrains[Order]:PBMSetCheckInterval(6)
    else
        -- Spawn Player and Coop 2
        ScenarioInfo.PlayerCDR = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true, false,
            {'AdvancedEngineering', 'T3Engineering', 'ResourceAllocation'})

        if tblArmy[ScenarioInfo.Coop2] then
            ScenarioInfo.CoopCDR2 = ScenarioFramework.SpawnCommander('Coop2', 'sACU', false, true, false, false,
                {'EngineeringThroughput', 'EnhancedSensors'})
        else
            -- TODO: make sACU warp effect, name for the sACU
            ScenarioFramework.SpawnCommander('Player', 'sACU', false, false, false, false,
                {'EngineeringThroughput', 'EnhancedSensors'})
        end
    end
    
    M2CounterAttack()
    M2PostIntro()
end

-- Order Base building functions
function ResetBuildInterval()
    ArmyBrains[Order]:PBMSetCheckInterval(6)
end

function M2T1AirFactoryBuilt()
    local factory = ArmyBrains[Order]:GetListOfUnits(categories.FACTORY * categories.AIR, false)
    IssueGuard({ScenarioInfo.OrderACU}, factory[1])
end

function M2T3AirFactoryBuilt()
    IssueStop({ScenarioInfo.OrderACU})
    IssueClearCommands({ScenarioInfo.OrderACU})

    -- Allow T1, T2 engineers again
    ScenarioFramework.RemoveRestriction(Order, categories.ual0105 + categories.ual0208)

    -- Trigger to assist naval factory once built
    ScenarioFramework.CreateArmyStatTrigger(M2T1NavalFactoryBuilt, ArmyBrains[Order], 'M2T1NavalFactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH1 * categories.NAVAL}})

    -- Trigger to start air attacks once at least 1 T3 pgens are built
    ScenarioFramework.CreateArmyStatTrigger(M2OrderT3AirAttacks, ArmyBrains[Order], 'M2OrderT3AirAttacks',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH3}})
end

function M2OrderT3AirAttacks()
    M2OrderAI.OrderM2BaseAirAttacks()
end

function M2T1NavalFactoryBuilt()
    local factory = ArmyBrains[Order]:GetListOfUnits(categories.FACTORY * categories.NAVAL * categories.STRUCTURE, false)

    --IssueStop({ScenarioInfo.OrderACU})
    --IssueClearCommands({ScenarioInfo.OrderACU})

    IssueGuard({ScenarioInfo.OrderACU}, factory[1])

    ScenarioFramework.CreateArmyStatTrigger(M2T3NavalFactoryBuilt, ArmyBrains[Order], 'M2T3NavalFactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH3 * categories.NAVAL * categories.STRUCTURE}})
end

function M2T3NavalFactoryBuilt()
    -- Stop assisting naval HQ with ACU
    IssueStop({ScenarioInfo.OrderACU})
    IssueClearCommands({ScenarioInfo.OrderACU})

    -- Qeue up support factories right away so they are built as soon as possible
    local aiBrain = ScenarioInfo.OrderACU:GetAIBrain()
    local supportFactories = {'M2_Order_Naval_Support_Factory_1', 'M2_Order_Naval_Support_Factory_2'}

    for _, v in supportFactories do
        local unitData = ScenarioUtils.FindUnit(v, Scenario.Armies['Order'].Units)

        if unitData and aiBrain:CanBuildStructureAt( unitData.type, unitData.Position ) then
            aiBrain:BuildStructure( ScenarioInfo.OrderACU, unitData.type, { unitData.Position[1], unitData.Position[3], 0}, false)
        end
    end

    -- Assist LandFactory
    local factory = ArmyBrains[Order]:GetListOfUnits(categories.FACTORY * categories.LAND * categories.STRUCTURE, false)
    IssueGuard({ScenarioInfo.OrderACU}, factory[1])

    -- Start building naval units
    M2OrderAI.OrderM2BaseNavalAttacks()

    ScenarioFramework.CreateArmyStatTrigger(M2T3LandFactoryBuilt, ArmyBrains[Order], 'M2T3LandFactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH3 * categories.LAND}})
end

function M2T3LandFactoryBuilt()
    -- Start land attacks
    M2OrderAI.OrderM2BaseLandAttacks()

    -- Stop assisting land HQ with ACU
    IssueStop({ScenarioInfo.OrderACU})
    IssueClearCommands({ScenarioInfo.OrderACU})

    -- Qeue up support factories right away so they are built as soon as possible
    local aiBrain = ScenarioInfo.OrderACU:GetAIBrain()
    local supportFactories = {'M2_Order_Land_Support_Factory_1', 'M2_Order_Land_Support_Factory_2'}

    for _, v in supportFactories do
        local unitData = ScenarioUtils.FindUnit(v, Scenario.Armies['Order'].Units)

        if unitData and aiBrain:CanBuildStructureAt( unitData.type, unitData.Position ) then
            aiBrain:BuildStructure( ScenarioInfo.OrderACU, unitData.type, { unitData.Position[1], unitData.Position[3], 0}, false)
        end
    end
    
    -- Put more engies on permanent assist
    M2OrderAI.OrderM2BaseEngieCount()
end

-- Initial counter attack
function M2CounterAttack()
    local platoon = nil

    ---------
    -- Cybran
    ---------
    -- Air
    for i = 1, 2 do
        platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_CA_Air_' .. i .. '_D' .. Difficulty, 'GrowthFormation')
        --ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_Cybran_Init_Air_Attack_Chain_' .. i)
        for _, v in platoon:GetPlatoonUnits() do
            ScenarioFramework.GroupPatrolChain({v}, 'M2_Cybran_Init_Air_Attack_Chain_' .. i)
        end
    end

    -- Wagners
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_CA_Wagners_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_Cybran_Init_Air_Attack_Chain_1')

    -- Naval
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_CA_Destroyers_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_Cybran_Init_Naval_Attack_Chain')

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_CA_Frigates_D' .. Difficulty, 'AttackFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_Cybran_Init_Naval_Attack_Chain')

    ------
    -- UEF
    ------
end

-- Post Intro Satellites
function M2PostIntro()
    -- Attack the player with satellites, trigger to destroy them with a dialogue when they get close
    for _, unit in ScenarioInfo.M2_Intro_Satellites do
        -- Mark the units as in objective
        unit:SetStrategicUnderlay('icon_objective_primary')

        IssueAttack({unit}, ScenarioInfo.PlayerCDR)
        ScenarioFramework.CreateUnitDistanceTrigger(M2SatellitesNearACU, unit, ScenarioInfo.PlayerCDR, 125)

        -- Set up vision on the satellites
        local pos = unit:GetPosition()
        local spec = {
            X = pos[1],
            Z = pos[2],
            Radius = 20,
            LifeTime = -1,
            Omni = false,
            Vision = true,
            Radar = false,
            Army = 1,
        }
        local vizmarker = VizMarker(spec)
        unit.Trash:Add( vizmarker )
        vizmarker:AttachBoneTo(-1, unit, -1)
    end
end

function M2SatellitesNearACU()
    if not ScenarioInfo.M2_Intro_Sat_Destroyed then
        ScenarioInfo.M2_Intro_Sat_Destroyed = true
    else
        return
    end
    ScenarioFramework.Dialogue(OpStrings.M2_Post_Intro_1, M2DestroyPostIntroSatellites, true) -- Virus uploaded
end

function M2DestroyPostIntroSatellites()
    for _, unit in ScenarioInfo.M2_Intro_Satellites do
        unit:Kill()
        WaitSeconds(Random(0.5, 0.9))
    end
    ScenarioFramework.Dialogue(OpStrings.M2_Post_Intro_2, StartMission2, true) -- What's going on to my HBO??
end

-- Assign objectives
function StartMission2()
    -----------------------------------------
    -- Primary Objective 1 - Destroy Factories
    -----------------------------------------
    ScenarioInfo.M2P1 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- status
        'Destroy UEF Bases',  -- title
        'Yes yes',  -- description
        'kill',
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {Area = 'M2_UEF_Base_Area', Category = categories.FACTORY * categories.STRUCTURE, CompareOp = '<=', Value = 0, ArmyIndex = UEF},
            },
        }
    )
    ScenarioInfo.M2P1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.M2_Bases_Killed, IntroMission3, true)
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P1)

    -- Pick a random event for second part of the mission
    CustomFunctions.ChooseRandomEvent(true)

    WIPDialogue('You\'ve reached a stage of the mission that is still under development. Bugs and issues might appear. Thank you for testing, speed2', {'OK'})
end

-- function M2SecondaryObjective()
-- end

-- Other M2 functions
function M2CybranASFsPatrol()
    -- Send new group of ASFs after 90 seconds
    ForkThread(function()
        WaitSeconds(90)

        if ScenarioInfo.MissionNumber == 2 then
            local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Offmap_ASFs', 'NoFormation')
            -- Random patrol for each unit
            for _, v in platoon:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Cybran_Base_Naval_Defense_Chain')))
            end
            -- Trigger to rebuild again if killed
            ScenarioFramework.CreatePlatoonDeathTrigger(M2CybranASFsPatrol, platoon)
        end
    end)
end

function M2CybranNavalPatrol()
    -- Send new naval patrol after 2, 3 minutes
    ForkThread(function()
        WaitSeconds((5 - Difficulty) * 60)

        if ScenarioInfo.MissionNumber == 2 then
            local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Offmap_Naval_Patrol_D' .. Difficulty, 'AttackFormation')
            -- Move closer to the island
            ScenarioFramework.PlatoonMoveRoute(platoon, {'M2_Cybran_Naval_Def_Regroup_Marker'})
            -- Random Patrol for each unit
            for _, v in platoon:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_Cybran_Base_AirDeffense_Chain')))
            end
            -- Trigger to rebuild again if killed
            ScenarioFramework.CreatePlatoonDeathTrigger(M2CybranNavalPatrol, platoon)
        end
    end)
end

-- Random events
function M2BattleshipAttack()
    -- Send group of battleships/unitities boat on attack. Pick randomly: 1 for west, 2 for east
    local army
    if Random(1, 2) == 1 then
        army = 'Cybran'
    else
        army = 'UEF'
    end

    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon(army, 'M2_' .. army .. '_Battleship_Attack_D' .. Difficulty, 'GrowthFormation')

    local battleships = {}
    local utilityBoats = {}
    
    for _, unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains( categories.BATTLESHIP, unit ) then
            table.insert(battleships, unit)
        elseif EntityCategoryContains( categories.DEFENSIVEBOAT, unit ) then
            table.insert(utilityBoats, unit)
        end
    end

    ScenarioFramework.GroupFormPatrolChain(battleships, 'M2_' .. army .. '_Battleship_Chain', 'AttackFormation')

    -- Each battleship is assisted by one utility boat
    for i = 1, 3 do
        IssueGuard({utilityBoats[i]}, battleships[i])
    end
end

function M2CybranNukeSubAttack()
    -- Spawn nuke sub as a platoon for easier moving on thee map
    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Cybran_Nuke_Sub', 'NoFormation')
    local nukeSub = platoon:GetPlatoonUnits()[1]

    local nukeMarkers = {'M2_Nuke_Marker_1', 'M2_Nuke_Marker_2', 'M2_Nuke_Marker_3', 'M2_Nuke_Marker_4'}
    local moveChains = {'M2_Nuke_Sub_Move_Chain_1', 'M2_Nuke_Sub_Move_Chain_2', 'M2_Nuke_Sub_Move_Chain_3'}

    while (nukeSub and not nukeSub:IsDead()) do
        -- Move it to attack position
        ScenarioFramework.PlatoonMoveChain(platoon, moveChains[Random(1, table.getn(moveChains))])

        -- Wait a bit to be sure it's really moving
        WaitSeconds(2)

        -- Wait till it arrives to the attack position
        while (nukeSub and not nukeSub:IsDead() and nukeSub:IsUnitState('Moving')) do
            WaitSeconds(5)
        end

        -- Check if sub didn't get killed
        if (not nukeSub or nukeSub:IsDead()) then
            return
        end

        -- Fire a nuke
        nukeSub:GiveNukeSiloAmmo(1)
        IssueNuke({nukeSub}, ScenarioUtils.MarkerToPosition(nukeMarkers[Random(1, table.getn(nukeMarkers))]))

        WaitSeconds(10)
        IssueClearCommands({nukeSub})

        -- Move back to the edge of the map
        IssueMove({nukeSub}, ScenarioUtils.MarkerToPosition('M2_Nuke_Sub_Move_2'))

        -- Wait few minutes and repeat
        WaitSeconds((6 - Difficulty) * 60)
    end
end

function M2ExperimentalAttack()
    -- Spawn spider/fatboy and send it to the player's base
    local army
    if Random(1, 2) == 1 then
        army = 'Cybran'
    else
        army = 'UEF'
    end

    local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon(army, 'M2_' .. army ..'_Experimental_Attack', 'NoFormation')

    local moveChains = {'M2_Experimental_Move_Chain_1', 'M2_Experimental_Move_Chain_2', 'M2_Experimental_Move_Chain_3'}

    -- First move spider/fatboy on the island, then start attacking, so it doesn't try to attack anything on attack range with torpedoes
    ScenarioFramework.PlatoonMoveChain(platoon, moveChains[Random(1, table.getn(moveChains))])
    ScenarioFramework.PlatoonAttackChain(platoon, 'M2_Player_Island_Drop_Chain')
end

------------
-- Mission 3
------------
function IntroMission3()
    ForkThread(
        function()
            -- Remove any qeued up dialogues
            ScenarioFramework.FlushDialogueQueue()
            -- If there's some dialogue playing, wait until it's finished
            while(ScenarioInfo.DialogueLock) do
                WaitSeconds(0.2)
            end

            if ScenarioInfo.MissionNumber ~= 2 then
                return
            end
            ScenarioInfo.MissionNumber = 3

            ForkThread(IntroMission3NIS)
        end
    )
end

function IntroMission3NIS()
end

function StartMission3()
end

-----------
-- End Game
-----------
function PlayerWin()
end

function M1CarriersDead(unit)
    ForkThread(
        function()
            -- AI kills the carriers
            ScenarioFramework.CDRDeathNISCamera(unit)
            WaitSeconds(8)
            PlayerLose()
        end
    )
end

function M1TimeRunsOut()
    -- Attack with sattelites
    local units = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Satellites')

    for i = 1, 2 do
        units[i]:Open()
        IssueAttack({units[i]}, ScenarioInfo.M1_Order_Carrier)
    end
    for i = 3, 5 do
        units[i]:Open()
        IssueAttack({units[i]}, ScenarioInfo.M1_Order_Tempest)
    end

    -- Move camera to carriers
    Cinematics.EnterNISMode()

    Cinematics.CameraMoveToMarker('Cam_1_Fail_1', 3)
    ScenarioFramework.Dialogue(OpStrings.M1_Time_Ran_Out, nil, true)
    WaitSeconds(2)
    Cinematics.CameraMoveToMarker('Cam_1_Fail_2', 3)
    WaitSeconds(2)

    -- Track one satellite
    Cinematics.CameraTrackEntity(units[4], 95)

    WaitSeconds(11)
    ScenarioInfo.M1_Order_Carrier:Kill()
    ScenarioInfo.M1_Order_Tempest:Kill()

    WaitSeconds(4)
    PlayerLose()
end

function PlayerLose()
    -- ScenarioFramework.PlayerLose(OpStrings.M1_Time_Ran_Out, AssignedObjectives) -- TODO: fix this in the coop mod

    ScenarioFramework.EndOperationSafety()
    ScenarioInfo.OpComplete = false

    -- Mark objectives as failed
    for k, v in AssignedObjectives do
        if(v and v.Active) then
            v:ManualResult(false)
        end
    end

    -- Play dialogue and end the game
    ScenarioFramework.Dialogue(OpStrings.Kill_Game_Dialogue, KillGame, true)
end

function PlayerDeath(deadCommander)
end

function KillGame()
    UnlockInput()
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, false)
end

------------------
-- Debug Functions
------------------
function OnCtrlF3()
    GateInACUsButton()

    --LOG('platoon tables:', repr(ArmyBrains[UEF]:GetPlatoonsList()))
    --LOG(repr(ArmyBrains[UEF]:GetPlatoonUniquelyNamed( 'BaseManager_CDRPlatoon_M1_UEF_Base' )))
end

function OnShiftF3()
end

function OnCtrlF4()
    if ScenarioInfo.MissionNumber == 1 then
        for _, v in ArmyBrains[UEF]:GetListOfUnits(categories.ALLUNITS, false) do
            v:Kill()
        end
    elseif ScenarioInfo.MissionNumber == 2 then
        ScenarioFramework.SetPlayableArea('M3_Area', false)  
    end
end

function OnShiftF4()
    WIPDialogue('You\'ve reached a stage of the mission that is still under development. Bugs and issues might appear. Thank you for testing, speed2', {'OK'})
end

-------------------
-- Custom Functions
-------------------
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
                    --If we want to trigger as soon as one of a type is in there, kick out immediately.
                    if not number then
                        triggeringEntity = v
                        triggered = true
                        break
                    --If we want to trigger on an amount, then add the entity into the triggeringEntity table
                    --so we can pass that table back to the callback function.
                    else
                        if not triggeringEntity then
                            triggeringEntity = {}
                        end
                        table.insert(triggeringEntity, v)
                    end
                end
            end
        end
        --Check to see if we have a triggering amount inside in the area.
        if number and ((amount >= number and not invert) or (amount < number and invert)) then
            triggered = true
        end
        --TRIGGER IF:
        --You don't want a specific amount and the correct unit category entered
        --You don't want a specific amount, there are no longer the category inside and you wanted the test inverted
        --You want a specific amount and we have enough.
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

function WIPDialogue(title, tblButtons)
    local dialogue = CreateDialogue(title, tblButtons)
    dialogue.OnButtonPressed = function(self, info)
        dialogue:Destroy()
    end
end