--##########################################################
--#                    Order Base
--##########################################################
--# Available Chain:
--# Air:
--# {'M2_Order_Base_AirDef_Chain'}
--#
--# Naval:
--# 
--# {'M2_Order_Defensive_Chain_Full', 'M2_Order_Defensive_Chain_West'},
--# {'', ''},
--##########################################################
--# Move Positions:
--# Naval:
--# Left, right side
--# {'M2_Carrier_Move_Order_1', 'M2_Carrier_Move_Order_2'},
--##########################################################
--#                  Aeon Naval Unit IDs
--# { 'uas0102', 1, 1, 'Attack', 'AttackFormation' },  -- AA Boat
--# { 'uas0103', 1, 1, 'Attack', 'AttackFormation' },  -- Frigate
--# { 'uas0203', 1, 1, 'Attack', 'AttackFormation' },  -- Submarine
--# { 'uas0201', 1, 1, 'Attack', 'AttackFormation' },  -- Destroyer
--# { 'uas0202', 1, 1, 'Attack', 'AttackFormation' },  -- Cruiser
--# { 'xas0204', 1, 1, 'Attack', 'AttackFormation' },  -- T2 Sub
--# { 'uas0302', 1, 1, 'Attack', 'AttackFormation' },  -- Battleship
--# { 'uas0303', 1, 1, 'Attack', 'AttackFormation' },  -- Carrier
--# { 'uas0304', 1, 1, 'Attack', 'AttackFormation' },  -- Nuke Sub
--# { 'xas0306', 1, 1, 'Attack', 'AttackFormation' },  -- Missile Ship
--##########################################################

local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/ScenarioPlatoonAI.lua'
import('/maps/SeraMission1/SeraMission1_Buffs.lua')

---------
-- Locals
---------
local Order = 3
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local OrderM2Base = BaseManager.CreateBaseManager()

function OrderM2BaseAI()
    ----------------
    -- Order M2 Base
    ----------------
    OrderM2Base:InitializeDifficultyTables(ArmyBrains[Order], 'M2_Order_Base', 'M2_Order_Base_Marker', 80, {M2_Order_Base = 100,})
    OrderM2Base:StartNonZeroBase({{15, 13, 11}, {13, 11, 9}})
    OrderM2Base:SetMaximumConstructionEngineers(2)
    OrderM2Base:SetEngineerBuildRateBuff('EngiesBuildRate')
    OrderM2Base:SetFactoryBuildRateBuff('FactoryBuildRate')
    OrderM2Base:SetActive('AirScouting', true)
    ForkThread(
        function()
            WaitSeconds(1)
            OrderM2Base:AddBuildGroup('M2_Order_Support_Factories', 110, true)
            -- OrderM2Base:AddBuildGroup('M2_Order_Defences', 90, true)
        end
    )

    OrderM2BaseAirAttacks()
    OrderM2BaseLandAttacks()
    OrderM2BaseNavalAttacks()
end

function OrderM2BaseAirAttacks()
    local opai = nil
    local quantity = {}

    -- Air Defense
    for i = 1, 3 do
        quantity = {4, 3, 3}
        opai = OrderM2Base:AddOpAI('AirAttacks', 'M2_Order_Base_AirDefense1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_Order_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('AirSuperiority', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end
    for i = 1, 2 do
        quantity = {4, 4, 3}
        opai = OrderM2Base:AddOpAI('AirAttacks', 'M2_Order_Base_AirDefense2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_Order_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('HeavyTorpedoBombers', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end

    for i = 1, 2 do
        quantity = {4, 4, 3}
        opai = OrderM2Base:AddOpAI('AirAttacks', 'M2_Order_Base_AirDefense3_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_Order_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('HeavyGunships', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end
end

function OrderM2BaseLandAttacks()
    local opai = nil
end

function OrderM2BaseNavalAttacks()

    local opai = nil
    local maxQuantity = {}
    local minQuantity = {}
    local trigger = {}
    local template = {}
    local builder = {}

        --[[
    trigger = {16, 14, 12}
    Temp = {
        'M2_Order_North_Battlecruiser_Attack_1',
        'NoPlan',
        { 'xes0307', 1, 2, 'Attack', 'AttackFormation' },  -- Battlecruiser
        { 'ues0203', 1, 4, 'Attack', 'AttackFormation' },  -- Submarine
        { 'xes0205', 1, 2, 'Attack', 'AttackFormation' },  -- Shield Boat

    }
    Builder = {
        BuilderName = 'M2_Order_North_Battlecruiser_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 120,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_Order_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread' },       
        PlatoonData = {
            PatrolChains = {'M2_OrderNorth_NavalAttack_Chain_1',
                            'M2_OrderNorth_NavalAttack_Chain_2',
                            'M2_OrderNorth_NavalAttack_Chain_3',
                            'M2_OrderNorth_NavalAttack_Chain_4'}
        },
        BuildConditions = {
            { '/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.NAVAL * categories.TECH2 * categories.MOBILE}},
        },
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )

    trigger = {2, 2, 1}
    Temp = {
        'M2_Order_North_Battlecruiser_Attack_2',
        'NoPlan',
        { 'xes0307', 1, 2, 'Attack', 'AttackFormation' },  -- Battlecruiser
        { 'ues0203', 1, 4, 'Attack', 'AttackFormation' },  -- Submarine
        { 'xes0205', 1, 2, 'Attack', 'AttackFormation' },  -- Shield Boat

    }
    Builder = {
        BuilderName = 'M2_Order_North_Battlecruiser_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 120,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_Order_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread' },       
        PlatoonData = {
            PatrolChains = {'M2_OrderNorth_NavalAttack_Chain_1',
                            'M2_OrderNorth_NavalAttack_Chain_2',
                            'M2_OrderNorth_NavalAttack_Chain_3',
                            'M2_OrderNorth_NavalAttack_Chain_4'}
        },
        BuildConditions = {
            { '/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.NAVAL * categories.TECH3 * categories.MOBILE}},
        },
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )
    
    opai = OrderM2Base:AddNavalAI('M2_OrderNorth_NavalAttack_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_OrderNorth_NavalAttack_Chain_1',
            },
            MaxFrigates = 30,
            MinFrigates = 30,
            Priority = 100,
        }
    )
    --opai:SetChildActive('T3', false)

    opai = OrderM2Base:AddNavalAI('M2_OrderNorth_NavalAttack_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_OrderNorth_NavalAttack_Chain_1',
            },
            MaxFrigates = 50,
            MinFrigates = 50,
            Priority = 100,
        }
    )

    opai = OrderM2Base:AddOpAI({'M2_Atlantis_1', 'M2_Atlantis_2'},
        {
            Amount = 2,
            KeepAlive = true,
            PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_OrderNorth_NavalAttack_Chain_1',
            },

            MaxAssist = 6,
            Retry = true,
        }
    )
    ]]--
end

function CarrierRebuild1()
    local Temp = {
        'M2_Order_Carrier_1',
        'NoPlan',
        { 'uas0303', 1, 1, 'Attack', 'AttackFormation' },  -- Carrier

    }
    local Builder = {
        BuilderName = 'M2_Order_Carrier_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 100,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_Order_Base',
        PlatoonAIFunction = {SPAIFileName, 'MoveToThread' },       
        PlatoonData = {
            MoveRoute = {'M2_Carrier_Move_Order_1'},
        },
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )
end

function CarrierRebuild2()
    local Temp = {
        'M2_Order_Carrier_2',
        'NoPlan',
        { 'uas0303', 1, 1, 'Attack', 'AttackFormation' },  -- Carrier

    }
    local Builder = {
        BuilderName = 'M2_Order_Carrier_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 100,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_Order_Base',
        PlatoonAIFunction = {SPAIFileName, 'MoveToThread' },       
        PlatoonData = {
            MoveRoute = {'M2_Carrier_Move_Order_2'},
        },
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )
end

function PatrolWestRebuild1()
    --[[
    local Temp = {
        'M2_Order_Naval_Defense_1',
        'NoPlan',
        { 'uas0201', 1, 6, 'Attack', 'GrowthFormation' },  -- Destroyer
        { 'uas0202', 1, 3, 'Attack', 'GrowthFormation' },  -- Cruiser

    }
    local Builder = {
        BuilderName = 'M2_Order_Naval_Defense_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 110,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_Order_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread' },       
        PlatoonData = {
            PatrolChain = 'M2_Order_Defensive_Chain_West',
            Ratio = 0.5,
            PlatoonName = 'M2_Order_Naval_Defense_Builder_1'
        },
        PlatoonBuildCallbacks = {
            [0] = {'/lua/editor/amplatoonhelperfunctions.lua', 'AMUnlockPlatoon',
                {'Order','M2_Order_Naval_Defense_Builder_1'},
                {'Order','M2_Order_Naval_Defense_Builder_1'}
            },
        },
        PlatoonAddFunctions = {
            [0] = {'/lua/editor/amplatoonhelperfunctions.lua', 'AMLockPlatoon',
                {'M2_Order_Naval_Defense_Builder_1'},
                {'M2_Order_Naval_Defense_Builder_1'}
            },
            [1] = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'AMUnlockRatio', 'M2_Order_Naval_Defense_Builder_1'}
        }
    }
    ArmyBrains[Order]:PBMAddPlatoon( Builder )
    ]]--
    local opai = OrderM2Base:AddNavalAI('M2_Order_NavalDefense_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_Order_Defensive_Chain_West',
            },
            MaxFrigates = 40,
            MinFrigates = 40,
            Priority = 200,
        }
    )
    opai:SetChildActive('T1', false)
    opai:SetChildActive('T3', false)
    opai:SetLockingStyle('DeathRatio', {Ratio = .4})
end

function PatrolWestRebuild2()
    local opai = OrderM2Base:AddNavalAI('M2_Order_NavalDefense_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_Order_Defensive_Chain_West',
            },
            MaxFrigates = 25,
            MinFrigates = 25,
            Priority = 190,
        }
    )
end
function PatrolFullRebuild()
    local opai = OrderM2Base:AddNavalAI('M2_Order_NavalDefense_3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_Order_Defensive_Chain_Full',
            },
            MaxFrigates = 30,
            MinFrigates = 30,
            Priority = 180,
        }
    )
    opai:SetChildActive('T1', false)
    opai:SetChildActive('T3', false)
    opai:SetLockingStyle('DeathRatio', {Ratio = .5})
end