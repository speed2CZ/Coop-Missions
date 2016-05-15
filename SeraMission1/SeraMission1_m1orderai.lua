local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ThisFile = '/maps/SeraMission1/SeraMission1_m1orderai.lua'

---------
-- Locals
---------
local Order = 3
local Difficulty = ScenarioInfo.Options.Difficulty

function OrderCarrierFactory()
    -- Adding build location for AI
	ArmyBrains[Order]:PBMAddBuildLocation('M1_Order_Carrier_Start_Marker', 150, 'AircraftCarrier1')

	local Carrier = ScenarioInfo.M1_Order_Carrier
	local location
    for num, loc in ArmyBrains[Order].PBM.Locations do
        if loc.LocationType == 'AircraftCarrier1' then
            location = loc
            OrderCarrierAttacks()
            break
        end
    end
	location.PrimaryFactories.Air = Carrier
	
	while (Carrier and not Carrier:IsDead()) do
        if  table.getn(Carrier:GetCargo()) > 0 and Carrier:IsIdleState() then
            IssueClearCommands({Carrier})
            IssueTransportUnload({Carrier}, Carrier:GetPosition())
        end
        WaitSeconds(1)
    end
end

function OrderCarrierAttacks()
	local torpBomberNum = {6, 4, 3}
    local swiftWindNum = {7, 5, 4}
    local gunshipNum = {8, 6, 5}

    local Temp = {
        'M1_Order_Carrier_Air_Attack_1',
        'NoPlan',
        { 'uaa0204', 1, torpBomberNum[Difficulty], 'Attack', 'AttackFormation' }, -- T2 Torp Bomber
        { 'xaa0202', 1, swiftWindNum[Difficulty], 'Attack', 'AttackFormation' }, -- Swift Wind
        { 'uaa0203', 1, gunshipNum[Difficulty], 'Attack', 'AttackFormation' }, -- T2 Gunship
        { 'uaa0101', 1, 3, 'Attack', 'AttackFormation' }, -- T1 Scout
    }
    local Builder = {
        BuilderName = 'M1_Order_Carrier_Air_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 100,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'AircraftCarrier1',
        PlatoonAIFunction = {ThisFile, 'GivePlatoonToPlayer'},       
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )

    --[[
    quantity = {9, 7, 5}
    Temp = {
        'M1_Order_Carrier_Air_Attack_2',
        'NoPlan',
        { 'xaa0202', 1, quantity[Difficulty], 'Attack', 'AttackFormation' }, -- Swift Wind
        { 'uaa0101', 1, 2, 'Attack', 'AttackFormation' }, -- T1 Scout
    }
    Builder = {
        BuilderName = 'M1_Order_Carrier_Air_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 100,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'AircraftCarrier1',
        PlatoonAIFunction = {ThisFile, 'GivePlatoonToPlayer'},       
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )

    quantity = {10, 8, 6}
    Temp = {
        'M1_Order_Carrier_Air_Attack_3',
        'NoPlan',
        { 'uaa0203', 1, quantity[Difficulty], 'Attack', 'AttackFormation' }, -- T2 Gunship
        { 'uaa0101', 1, 2, 'Attack', 'AttackFormation' }, -- T1 Scout
    }
    Builder = {
        BuilderName = 'M1_Order_Carrier_Air_Builder_3',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 100,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'AircraftCarrier1',
        PlatoonAIFunction = {ThisFile, 'GivePlatoonToPlayer'},       
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )

    if Difficulty <= 2 then
        quantity = {2, 1, 0}
        Temp = {
            'M1_Order_Carrier_Air_Attack_4',
            'NoPlan',
            { 'xaa0305', 1, quantity[Difficulty], 'Attack', 'AttackFormation' }, -- T3 Gunship
            { 'uaa0302', 1, 1, 'Attack', 'AttackFormation' }, -- T3 Scout
        }
        Builder = {
            BuilderName = 'M1_Order_Carrier_Air_Builder_4',
            PlatoonTemplate = Temp,
            InstanceCount = 1,
            Priority = 100,
            PlatoonType = 'Air',
            RequiresConstruction = true,
            LocationType = 'AircraftCarrier1',
            PlatoonAIFunction = {ThisFile, 'GivePlatoonToPlayer'},       
        }
        ArmyBrains[Order]:PBMAddPlatoon( Builder )
    end
    ]]--
end

function GivePlatoonToPlayer(platoon)
	for _, unit in platoon:GetPlatoonUnits() do
        while (not unit:IsDead() and unit:IsUnitState('Attached')) do
            WaitSeconds(1)
        end
        ScenarioFramework.GiveUnitToArmy(unit, 'Player')
    end    
end