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

--------------
-- Debug only!
--------------
local SkipNIS1 = true
local SkipNIS2 = true

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
    local units = ScenarioUtils.CreateArmyGroup('Order', 'M1_Oder_Init_Air_D' .. Difficulty)
    for k, v in units do
        IssueStop({v})
        ScenarioInfo.M1_Order_Carrier:AddUnitToStorage(v)
    end

    -- Move Carrier to starting position together with the fleet
    IssueMove({ScenarioInfo.M1_Order_Carrier}, ScenarioUtils.MarkerToPosition('M1_Order_Carrier_Start_Marker'))
    IssueGuard(ScenarioInfo.M1_Carrier_Fleet, ScenarioInfo.M1_Order_Carrier)

    ForkThread(function()
        while (ScenarioInfo.M1_Order_Carrier and not ScenarioInfo.M1_Order_Carrier:IsDead() and ScenarioInfo.M1_Order_Carrier:IsUnitState('Moving')) do
            WaitSeconds(.5)
        end

        -- Put Naval fleet on patrol
        for _, v in ScenarioInfo.M1_Carrier_Fleet do
            IssueClearCommands({v})
            ScenarioFramework.GroupPatrolChain({v}, 'M1_Oder_Naval_Def_Chain')
        end

        -- Release air units from carrier and give them to player
        IssueClearCommands({ScenarioInfo.M1_Order_Carrier})
        IssueTransportUnload({ScenarioInfo.M1_Order_Carrier}, ScenarioInfo.M1_Order_Carrier:GetPosition())
        for _, v in units do
            while (not v:IsDead() and v:IsUnitState('Attached')) do
                WaitSeconds(3)
            end
            IssueClearCommands({v})
            ScenarioFramework.GiveUnitToArmy(v, 'Player')
        end

        -- Start building units from the carrier once on it's place
        M1OrderAI.OrderCarrierFactory()
    end)

    -- Tempest
    ScenarioInfo.M1_Order_Tempest = ScenarioUtils.CreateArmyUnit('Order', 'M1_Order_Tempest')
    ScenarioInfo.M1_Order_Tempest:HideBone('Turret', true)
    ScenarioInfo.M1_Order_Tempest:HideBone('Turret_Muzzle', true)
    ScenarioInfo.M1_Order_Tempest:SetWeaponEnabledByLabel('MainGun', false)
    
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
    --Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_1'))
    ForkThread(IntroMission1NIS)
end

------------
-- Mission 1
------------
function IntroMission1NIS()
	if not SkipNIS1 then


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
        'Protect Order AirCraft Carrier',                 -- title
        'Make sure you dont lose carrier.',         -- description
        {                               -- target
            Units = {ScenarioInfo.M1_Order_Carrier},
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
                IntroMission2()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P2)
end

------------
-- Mission 2
------------
function IntroMission2()
    ScenarioInfo.Mission = 2

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

    -----------
    -- Order AI
    -----------
    M2OrderAI.OrderM2BaseAI()

    ScenarioInfo.OrderACU = ScenarioUtils.CreateArmyUnit('Order', 'M2_Order_ACU')
    ScenarioInfo.OrderACU:CreateEnhancement('T3Engineering')
    ScenarioInfo.OrderACU:CreateEnhancement('EnhancedSensors')
    ScenarioInfo.OrderACU:CreateEnhancement('ResourceAllocationAdvanced')
    ScenarioInfo.OrderACU:SetCustomName('Order')

    -- Carriers, AI rebuilds them if killed
    local CarriersFunctions = {
        [1] = M2OrderAI.CarrierRebuild1,
        [2] = M2OrderAI.CarrierRebuild2,
    }
    local Carriers = {}
    for i = 1, 2 do
        Carriers[i] = ScenarioUtils.CreateArmyUnit('Order', 'M2_Order_Carrier_' .. i)
        Carriers[i]:SetVeterancy(1)
        ScenarioFramework.CreateUnitDeathTrigger(CarriersFunctions[i], Carriers[i])
    end

    local OrderWestPatrol1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_Order_Naval_Patrol_West_1', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(OrderWestPatrol1, 'M2_Order_Defensive_Chain_West')
    ScenarioFramework.CreatePlatoonDeathTrigger(M2OrderAI.PatrolWestRebuild1, OrderWestPatrol1)

    local OrderWestPatrol2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_Order_Naval_Patrol_West_2', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(OrderWestPatrol2, 'M2_Order_Defensive_Chain_West')
    ScenarioFramework.CreatePlatoonDeathTrigger(M2OrderAI.PatrolWestRebuild2, OrderWestPatrol2)

    local OrderFullPatrol = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_Order_Naval_Patrol_Full', 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(OrderFullPatrol, 'M2_Order_Defensive_Chain_Full')
    ScenarioFramework.CreatePlatoonDeathTrigger(M2OrderAI.PatrolFullRebuild, OrderFullPatrol)

    ----------------
    -- Player's Base
    ----------------
    ScenarioUtils.CreateArmyGroup('Player', 'M2_Player_Base_D' .. Difficulty)
    ScenarioUtils.CreateArmyGroup('Player', 'M2_Players_Support_Factories_D' .. Difficulty)

    -- Make Engineers assist factoris and support factories assist HQ, set rally points
    local num = {6, 4, 3}
    for i = 1, num[Difficulty] do
        IssueClearFactoryCommands({ScenarioInfo.UnitNames[Player]['Factory_' .. i]})
        IssueFactoryRallyPoint({ScenarioInfo.UnitNames[Player]['Factory_' .. i]}, ScenarioUtils.MarkerToPosition('Player_Rally_Point'))
        for j = 1, 3 do
            IssueGuard({ScenarioInfo.UnitNames[Player]['Engineer_' .. i .. '_' .. j]}, ScenarioInfo.UnitNames[Player]['Factory_' .. i])
        end
    end
    for i = 2, num[Difficulty] do
        IssueFactoryAssist({ScenarioInfo.UnitNames[Player]['Factory_' .. i]}, ScenarioInfo.UnitNames[Player]['Factory_1'])
    end

    -- Produce units in factories
    local numDestroyers = {12, 6, 3}
    local navalPlatoon = {'', '',}
    table.insert(navalPlatoon, {'xss0302', 2, 2, 'attack', 'AttackFormation'})
    table.insert(navalPlatoon, {'xss0304', 2, 2, 'attack', 'AttackFormation'})
    table.insert(navalPlatoon, {'xss0201', numDestroyers[Difficulty], numDestroyers[Difficulty], 'attack', 'AttackFormation'})
    ArmyBrains[Player]:BuildPlatoon(navalPlatoon, {ScenarioInfo.UnitNames[Player]['Factory_1']}, 1)

    -- Give resources armies
    ArmyBrains[UEF]:GiveResource('MASS', 25000)
    ArmyBrains[Order]:GiveResource('MASS', 8000)
    ArmyBrains[Player]:GiveResource('MASS', 6000)

end

function IntroMission2NIS()
    ScenarioFramework.SetPlayableArea('M2_Area', false)

    if not SkipNIS2 then
        Cinematics.EnterNISMode()
        ScenarioFramework.Dialogue(OpStrings.Introduction, nil, true)

        ScenarioInfo.PlayerACU = ScenarioUtils.CreateArmyUnit('Player', 'Player_ACU')
        ScenarioInfo.PlayerACU:SetCustomName(ArmyBrains[Player].Nickname)
        ScenarioInfo.PlayerACU:PlayCommanderWarpInEffect()

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_1'), 0)
        WaitSeconds(1)
        
        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_2'), 5)
        WaitSeconds(1)

        Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_3'), 0)
        WaitSeconds(3)
        Cinematics.ExitNISMode()
    end
    
    StartMission2()
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
    M2UEFAI.StopSACU()
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