-- Custom Mission
-- Author: speed2
local Cinematics = import('/lua/cinematics.lua')
local M1OrderAI = import('/maps/SeraMission1/SeraMission1_m1orderai.lua')
local M1UEFAI = import('/maps/SeraMission1/SeraMission1_m1uefai.lua')
local M2OrderAI = import('/maps/SeraMission1/SeraMission1_m2orderai.lua')
local M2UEFAI = import('/maps/SeraMission1/SeraMission1_m2uefai.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local OpStrings = import('/maps/SeraMission1/SeraMission1_strings.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
-- local TauntManager = import('/lua/TauntManager.lua')

----------
-- Globals
----------
ScenarioInfo.Player = 1
ScenarioInfo.UEF = 2
ScenarioInfo.Order = 3
ScenarioInfo.Seraphim = 4
ScenarioInfo.Objective = 5
ScenarioInfo.Coop1 = 6
ScenarioInfo.Coop2 = 7
ScenarioInfo.Coop3 = 8

---------
-- Locals
---------
local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local Order = ScenarioInfo.Order
local Seraphim = ScenarioInfo.Seraphim
local Objective = ScenarioInfo.Objective
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3

local AssignedObjectives = {}
local Difficulty = ScenarioInfo.Options.Difficulty

local useOrderAI = false

-- How long should we wait at the beginning of the NIS to allow slower machines to catch up?
local NIS1InitialDelay = 3

--------------
-- Debug only!
--------------
local Debug = false
local SkipNIS1 = false
local SkipNIS2 = false

-----------------
-- Taunt Managers
-----------------
-- local UEFACU = TauntManager.CreateTauntManager('UEFACUTM', '/maps/colony/colony_strings.lua')

function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()

    -- Sets Army Colors
    ScenarioFramework.SetSeraphimColor(Player)
    ScenarioFramework.SetUEFPlayerColor(UEF)
    ScenarioFramework.SetNeutralColor(Objective)
    ScenarioFramework.SetAeonEvilColor(Order)

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
    GetArmyBrain(Seraphim):SetResourceSharing(false)

    --------
    -- Order
    --------
    -- Economy buildings for Carrier
    ScenarioInfo.M1_Order_Eco = ScenarioUtils.CreateArmyGroup('Order', 'M1_Order_Economy')

    -- Carrier
    ScenarioInfo.M1_Order_Carrier = ScenarioUtils.CreateArmyUnit('Order', 'M1_Order_Carrier')
    ScenarioInfo.M1_Order_Carrier:SetVeterancy(4 - Difficulty)

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
            local tempUnit = ScenarioFramework.GiveUnitToArmy(unit, 'Player')
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
        local VisMarker1_2 = ScenarioFramework.CreateVisibleAreaAtUnit(60, ScenarioInfo.UnitNames[UEF]['UEF_NIS_Unit'], 0, ArmyBrains[Player])

        WaitSeconds(NIS1InitialDelay)

        WaitSeconds(1)
        Cinematics.CameraMoveToMarker('Cam_1_2', 6)
        WaitSeconds(3)
        Cinematics.CameraTrackEntity(ScenarioInfo.UnitNames[UEF]['UEF_NIS_Unit'], 40, 2)
        WaitSeconds(5)
        Cinematics.CameraMoveToMarker('Cam_1_3', 5)
        WaitSeconds(3)
        Cinematics.CameraMoveToMarker('Cam_1_4', 4)
        WaitSeconds(3)
        VisMarker1_1:Destroy()
        VisMarker1_2:Destroy()

        if Difficulty == 3 then
            ScenarioFramework.ClearIntel(ScenarioUtils.MarkerToPosition('M1_UEF_Base_Marker'), 70)
        end

        Cinematics.ExitNISMode()
        --Cinematics.CameraReset()
	end
	IntroMission1()
end

function IntroMission1()
    ScenarioInfo.MissionNumber = 1

    StartMission1()
end

function StartMission1()
    ----------------------------------------
    -- Primary Objective 1 - Protect Carrier
    ----------------------------------------
    ScenarioInfo.M1P1 = Objectives.Protect(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Protect Order Aircraft Carrier and Tempest',                 -- title
        'Order will provide you units for an attack on the UEF island base. Make sure don\'t lose mobile factories.',         -- description
        {                               -- target
            Units = {ScenarioInfo.M1_Order_Carrier, ScenarioInfo.M1_Order_Tempest},
        }
   )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(not result and not ScenarioInfo.OpEnded) then
                PlayerLose()
            end
        end
   )
    table.insert(AssignedObjectives, ScenarioInfo.M1P1)

    -----------------------------------------------
    -- Primary Objective 1 - Destroy First UEF Base
    -----------------------------------------------
    ScenarioInfo.M1P2 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy UEF Forward Bases',                 -- title
        'Eliminate the marked UEF structures to establish a foothold on the island.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M1_UEF_Base_Area',
                    Category = categories.FACTORY + (categories.ECONOMIC * categories.TECH2),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
            },
        }
   )
    ScenarioInfo.M1P2:AddResultCallback(
        function(result)
            if(result) then
                ScenarioInfo.M1P1:ManualResult(true)
                if not Debug then
                    ScenarioInfo.M1S1:ManualResult(true)
                end
                IntroMission2()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P2)

    if not Debug then
        -- Assign secondary objective after few seconds
        ScenarioFramework.CreateTimerTrigger(M1SecondaryObjective, 20)
    end
end

function M1SecondaryObjective()
    -- Get player's cruiser for objective
    ScenarioInfo.M1_Objective_Cruiser = ArmyBrains[Player]:GetListOfUnits(categories.uas0202, false)[1]

    -- Make sure that cruiser isnt dead
    if (ScenarioInfo.M1_Objective_Cruiser and not ScenarioInfo.M1_Objective_Cruiser:IsDead()) then
        ------------------------------------------
        -- Secondary Objective 1 - Protect Cruiser
        ------------------------------------------
        ScenarioInfo.M1S1 = Objectives.Protect(
            'secondary',                      -- type
            'incomplete',                   -- complete
            'Protect Cruiser',                 -- title
            'TODO: description',         -- description
            {                               -- target
                Units = {ScenarioInfo.M1_Objective_Cruiser},
            }
       )
        ScenarioInfo.M1S1:AddResultCallback(
            function(result)
                if(not result and not ScenarioInfo.OpEnded) then
                    ScenarioFramework.Dialogue(OpStrings.M1_CruiserLost)
                end
            end
       )
        table.insert(AssignedObjectives, ScenarioInfo.M1S1)
    end
end

------------
-- Mission 2
------------
function IntroMission2()
    ForkThread(function()
        ScenarioInfo.MissionNumber = 2

        -----------
        -- Order AI
        -----------
        -- Spawn Coop player 1 or Order ACU
        ScenarioInfo.CoopCDR = {}
        local tblArmy = ListArmies()

        if tblArmy[ScenarioInfo.Coop1] then
            ScenarioInfo.CoopCDR1 = ScenarioFramework.SpawnCommander('Coop1', 'Commander', 'Warp', true, true,
                {'ResourceAllocation', 'AdvancedEngineering', 'T3Engineering'})
        else
            useOrderAI = true
            ScenarioInfo.OrderACU = ScenarioFramework.SpawnCommander('Order', 'M2_Order_ACU', 'Warp', 'Violet', false, false, -- TODO: Come up with a name
                {'ResourceAllocationAdvanced', 'EnhancedSensors', 'AdvancedEngineering', 'T3Engineering'})
        end

        if tblArmy[ScenarioInfo.Coop3] then
            ScenarioInfo.CoopCDR3 = ScenarioFramework.SpawnCommander('Coop3', 'Commander', 'Warp', true, true)
        end

        -- Don't produce units for player anymore
        ArmyBrains[Order]:PBMRemoveBuildLocation('M1_Order_Carrier_Start_Marker', 'AircraftCarrier1')
        ArmyBrains[Order]:PBMRemoveBuildLocation('M1_Order_Tempest_Start_Marker', 'Tempest1')
        IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
        IssueClearCommands({ScenarioInfo.M1_Order_Tempest})

        -- Move Carrier and Tempest on map close to the island
        IssueMove({ScenarioInfo.M1_Order_Carrier}, ScenarioUtils.MarkerToPosition('M2_Order_Carrier_Marker_1'))
        IssueMove({ScenarioInfo.M1_Order_Tempest}, ScenarioUtils.MarkerToPosition('M2_Order_Tempest_Marker'))

        if useOrderAI then
            M2OrderAI.OrderM2BaseAI()
            -- M2OrderAI.OrderM2Carriers()

            ArmyBrains[Order]:PBMSetCheckInterval(6)

            ScenarioFramework.CreateTimerTrigger(ResetBuildInterval, 300)

            ScenarioFramework.CreateArmyStatTrigger(M2T1AirFactoryBuilt, ArmyBrains[Order], 'M2T1AirFactoryBuilt',
                {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH1 * categories.AIR}})

            ScenarioFramework.CreateArmyStatTrigger(M2T3AirFactoryBuilt, ArmyBrains[Order], 'M2T3AirFactoryBuilt',
                {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH3 * categories.AIR}})
        else
            ForkThread(function()
                while (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() and ScenarioInfo.M1_Order_Carrier:IsUnitState('Moving')) do
                    WaitSeconds(.5)
                end
                if (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead()) then
                    IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
                    ScenarioFramework.GiveUnitToArmy(ScenarioInfo.M1_Order_Carrier, 'Coop1')
                end
            end)

            ForkThread(function()
                while (ScenarioInfo.M1_Order_Tempest and not ScenarioInfo.M1_Order_Tempest:IsDead() and ScenarioInfo.M1_Order_Tempest:IsUnitState('Moving')) do
                    WaitSeconds(.5)
                end
                if (ScenarioInfo.M1_Order_Tempest and not ScenarioInfo.M1_Order_Tempest:IsDead()) then
                    IssueClearCommands({ScenarioInfo.M1_Order_Tempest})
                    ScenarioFramework.GiveUnitToArmy(ScenarioInfo.M1_Order_Tempest, 'Coop1')
                end
            end)
        end

        -- Remove off map Order eco buildings from first objective
        for _, v in ScenarioInfo.M1_Order_Eco do
            v:Destroy()
        end

        -- Temporary restrict T1 and T2 engineers for Order so it builds T3 in the base
        ScenarioFramework.AddRestriction(Order, categories.ual0105 + categories.ual0208)

        ---------
        -- UEF AI
        ---------
        M2UEFAI.UEFM2NorthBaseAI()

        -- Battleships, rebuilds if killed
        local BattleshipsFunctions = {
            [1] = M2UEFAI.BattleshipRebuild1,
            [2] = M2UEFAI.BattleshipRebuild2,
            [3] = M2UEFAI.BattleshipRebuild3,
            [4] = M2UEFAI.BattleshipRebuild4,
            [5] = M2UEFAI.BattleshipRebuild5,
        }
        local Battleships = {}
        for i = 1, (2 + Difficulty) do
            Battleships[i] = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_North_Battleship_' .. i, 'GrowthFormation')
            for k, v in Battleships[i]:GetPlatoonUnits() do
                v:SetVeterancy(Difficulty)
            end
            ScenarioFramework.CreatePlatoonDeathTrigger(BattleshipsFunctions[i], Battleships[i])
        end

        for i = 1, 4 do
            local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_UEF_NorthNaval_Defense_' .. i .. '_D' .. Difficulty, 'GrowthFormation')
            ScenarioFramework.PlatoonPatrolChain(units, 'M2_UEFNorth_NavalDefense_Chain_' .. i)
        end
        --[[
        local units = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_North_Air_Patrol', 'GrowthFormation')
        for k, v in units:GetPlatoonUnits() do
            ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M2_UEF_North_Base_AirDef_Chain')))
        end
        ]]--
        -- TML Launchers
        for k,unit in ArmyBrains[UEF]:GetListOfUnits(categories.ueb2108, false) do
            local plat = ArmyBrains[UEF]:MakePlatoon('', '')
            ArmyBrains[UEF]:AssignUnitsToPlatoon(plat, {unit}, 'Attack', 'NoFormation')
            plat:ForkAIThread(plat.TacticalAI)
        end

        -- Give resources armies
        ArmyBrains[UEF]:GiveResource('MASS', 25000)
        ArmyBrains[Order]:GiveResource('MASS', 8000)
        ArmyBrains[Player]:GiveResource('MASS', 6000)

        IntroMission2NIS()
    end)
end

function IntroMission2NIS()
    ScenarioFramework.SetPlayableArea('M2_Area', false)

    if not SkipNIS2 then
        Cinematics.EnterNISMode()
        -- Ensure that Order starts building base sooner rather than later
        ArmyBrains[Order]:PBMSetCheckInterval(2)

        WaitSeconds(1)
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_1'), 0)
        WaitSeconds(4)
        -- ScenarioFramework.Dialogue(OpStrings.Introduction, nil, true)

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_2_2'), 3)

        ScenarioInfo.PlayerCDR = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true, false,
            {'AdvancedEngineering', 'T3Engineering', 'ResourceAllocation'})
        
        Cinematics.ExitNISMode()

        -- Set back to default
        ArmyBrains[Order]:PBMSetCheckInterval(6)
    end
    
    StartMission2()
end

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

    ScenarioFramework.CreateArmyStatTrigger(M2T1NavalFactoryBuilt, ArmyBrains[Order], 'M2T1NavalFactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH1 * categories.NAVAL}})

    ScenarioFramework.CreateArmyStatTrigger(M2_T3AirAttacks, ArmyBrains[Order], 'M2_T3AirAttacks',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 2, Category = categories.ENERGYPRODUCTION * categories.STRUCTURE * categories.TECH3}})
end

function M2_T3AirAttacks()
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
    IssueStop({ScenarioInfo.OrderACU})
    IssueClearCommands({ScenarioInfo.OrderACU})

    M2OrderAI.OrderM2BaseNavalAttacks()

    ScenarioFramework.CreateArmyStatTrigger(M2T3LandFactoryBuilt, ArmyBrains[Order], 'M2T3LandFactoryBuilt',
        {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 1, Category = categories.FACTORY * categories.TECH3 * categories.LAND}})
end

function M2T3LandFactoryBuilt()
    M2OrderAI.OrderM2BaseLandAttacks()
    M2OrderAI.OrderM2BaseEngieCount()
end

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
                {Area = 'M2_UEF_North_Base_Area', Category = categories.FACTORY * categories.STRUCTURE, CompareOp = '<=', Value = 0, ArmyIndex = UEF},
            },
        }
    )
    ScenarioInfo.M2P1:AddResultCallback(
        function(result)
            if(result) then
                ScenarioFramework.Dialogue(OpStrings.M2_Bases_Killed, IntroMission2, true)
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P1)

    CreateAreaTrigger(UEFBuildArties, ScenarioUtils.AreaToRect('M2_Area'), categories.uab2302 + categories.xsb2302, true, false, 1, false)
end

function UEFBuildArties()
    M2UEFAI.UEFM2NorthArtyBaseAI()
    --M2UEFAI.UEFM2WestArtyBaseAI()
end

function PlayerLose()
end

------------------
-- Debug Functions
------------------
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
    UEFBuildArties()
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