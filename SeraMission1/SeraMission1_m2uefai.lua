--#####################################################################
--###                       ### UEF Base ###                        ###
--#####################################################################
--# Available Chain
--# Air:
--# {'M2_UEF_Base_AirDef_Chain'}
--#
--# Naval:
--# 1, 2 goes to the left; 3, 4 to the right
--# {'M2_UEF_Base_NavalAttack_Chain_1', 'M2_UEF_Base_NavalAttack_Chain_2', 'M2_UEF_Base_NavalAttack_Chain_3', 'M2_UEF_Base_NavalAttack_Chain_4'},
--#
--# {'M2_UEF_Base_NavalDefense_Chain_1', 'M2_UEF_Base_NavalDefense_Chain_2'},
--#####################################################################
--#
--#####################################################################
--#                 UEF Naval Unit IDs
--# { 'ues0103', 1, 1, 'Attack', 'AttackFormation' },  -- Frigate
--# { 'ues0203', 1, 1, 'Attack', 'AttackFormation' },  -- Submarine
--# { 'ues0201', 1, 1, 'Attack', 'AttackFormation' },  -- Destroyer
--# { 'ues0202', 1, 1, 'Attack', 'AttackFormation' },  -- Cruise
--# { 'xes0102', 1, 1, 'Attack', 'AttackFormation' },  -- Torp Boat
--# { 'xes0205', 1, 1, 'Attack', 'AttackFormation' },  -- Shield Boat
--# { 'ues0302', 1, 1, 'Attack', 'AttackFormation' },  -- Battleship
--# { 'ues0304', 1, 1, 'Attack', 'AttackFormation' },  -- Nuke Sub
--# { 'xes0307', 1, 1, 'Attack', 'AttackFormation' },  -- Battlecruiser
--#####################################################################

local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/ScenarioPlatoonAI.lua'

---------
-- Locals
---------
local UEF = 2
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local UEFM2Base = BaseManager.CreateBaseManager()
local UEFM2IslandBase = BaseManager.CreateBaseManager()

-------------------
-- UEF M2 Main Base
-------------------
function UEFM2BaseAI()
    UEFM2Base:InitializeDifficultyTables(ArmyBrains[UEF], 'M2_UEF_Base', 'M2_UEF_Base_Marker', 160, {M2_UEF_Base = 100,})
    UEFM2Base:StartNonZeroBase({{18, 21, 24}, {14, 17, 20}})
    UEFM2Base:SetMaximumConstructionEngineers(4)
    
    UEFM2Base:SetActive('AirScouting', true)
    UEFM2Base:SetSupportACUCount(1)
    --UEFM2Base:SetSACUUpgrades({'ResourceAllocation', 'RadarJammer', 'SensorRangeEnhancer'}, true)
    ForkThread(
        function()
            WaitSeconds(1)
            UEFM2Base:AddBuildGroupDifficulty('M2_UEF_Base_Support_Factories', 110, true)
        end
    )

    --UEFM2BaseLandAttacks()
    --UEFM2BaseAirAttacks()
    --UEFM2BaseNavalAttacks()
end

function UEFM2BaseAirAttacks()
    local opai = nil
    local quantity = {}

    -- Transport Builder
    opai = UEFM2Base:AddOpAI('EngineerAttack', 'M2_UEF_TransportBuilder',
    {
        MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
        PlatoonData = {
            LandingChain = 'M2_UEF_Base_NavalAttack_Chain_1',
            TransportReturn = 'M2_UEF_Base_Marker',
        },
        Priority = 1000,
    })
    opai:SetChildActive('All', false)
    opai:SetChildActive('T2Transports', true)
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {'default_brain', 8, categories.uea0104})

    -- Air Defense
    for i = 1, 3 do
        quantity = {3, 4, 5}
        opai = UEFM2Base:AddOpAI('AirAttacks', 'M2_UEF_Base_AirDefense1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_UEF_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('TorpedoBombers', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end
    for i = 1, 3 do
        quantity = {3, 4, 5}
        opai = UEFM2Base:AddOpAI('AirAttacks', 'M2_UEF_Base_AirDefense2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_UEF_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('AirSuperiority', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end
    for i = 1, 2 do
        quantity = {2, 2, 3}
        opai = UEFM2Base:AddOpAI('AirAttacks', 'M2_UEF_Base_AirDefense3_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_UEF_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('StratBombers', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end
    for i = 1, 2 do
        quantity = {3, 3, 4}
        opai = UEFM2Base:AddOpAI('AirAttacks', 'M2_UEF_Base_AirDefense4_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_UEF_Base_AirDef_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('HeavyGunships', quantity[Difficulty])
        opai:SetLockingStyle('DeathRatio', {Ratio = .5})
    end
end

function UEFM2BaseLandAttacks()
    local opai = nil
    
    local Temp = {
        'M2UEFSACU',
        'NoPlan',
        { 'uel0301_RAS', 1, 2, 'Attack', 'None' },   -- SACU
    }
    local Builder = {
        BuilderName = 'M2SACUBuilder',
        PlatoonTemplate = Temp,
        InstanceCount = 3,
        Priority = 300,
        PlatoonType = 'Gate',
        RequiresConstruction = true,
        LocationType = 'M2_UEF_Base',
        PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread' },       
        PlatoonData = {
            PatrolChain = 'M2_UEF_Base_EngineerChain',
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )
    --[[
    opai = UEFM2Base:AddOpAI('EngineerAttack', 'M2_EngAttack1',
        {
            MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'StartBaseEngineerThread'},
            PlatoonData = {
                LandingLocation = 'M2_North_Arty_Base_Marker',
                TransportReturn = 'M2_UEF_Base_Marker',
                UseTransports = true,
                BaseName = 'M2_North_Arty_Base',
            },
            Priority = 90,
        }
    )
    opai:SetChildActive('All', false)
    opai:SetChildActive({'T3Engineers', 'T3Transports'}, false)
    ]]--
end

function UEFM2BaseNavalAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    --[[
    local opai = nil
    local maxQuantity = {}
    local minQuantity = {}
    local trigger = {}
    local template = {}
    local builder = {}

    Temp = {
        'M2_UEF_Base_Destroyer_Attack_1',
        'NoPlan',
        { 'ues0201', 1, 4, 'Attack', 'AttackFormation' },  -- Destroyer
        { 'ues0103', 1, 4, 'Attack', 'AttackFormation' },  -- Frigate
        { 'ues0203', 1, 8, 'Attack', 'AttackFormation' },  -- Submarine
        { 'xes0205', 1, 2, 'Attack', 'AttackFormation' },  -- Shield Boat

    }
    Builder = {
        BuilderName = 'M2_UEF_Base_Destroyer_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 110,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_UEF_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread' },       
        PlatoonData = {
            PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                            'M2_UEF_Base_NavalAttack_Chain_2',
                            'M2_UEF_Base_NavalAttack_Chain_3',
                            'M2_UEF_Base_NavalAttack_Chain_4'}
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

    trigger = {16, 14, 12}
    Temp = {
        'M2_UEF_Base_Battlecruiser_Attack_1',
        'NoPlan',
        { 'xes0307', 1, 2, 'Attack', 'AttackFormation' },  -- Battlecruiser
        { 'ues0203', 1, 4, 'Attack', 'AttackFormation' },  -- Submarine
        { 'xes0205', 1, 2, 'Attack', 'AttackFormation' },  -- Shield Boat

    }
    Builder = {
        BuilderName = 'M2_UEF_Base_Battlecruiser_Builder_1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 120,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_UEF_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread' },       
        PlatoonData = {
            PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                            'M2_UEF_Base_NavalAttack_Chain_2',
                            'M2_UEF_Base_NavalAttack_Chain_3',
                            'M2_UEF_Base_NavalAttack_Chain_4'}
        },
        BuildConditions = {
            { '/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.NAVAL * categories.TECH2 * categories.MOBILE}},
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

    trigger = {2, 2, 1}
    Temp = {
        'M2_UEF_Base_Battlecruiser_Attack_2',
        'NoPlan',
        { 'xes0307', 1, 2, 'Attack', 'AttackFormation' },  -- Battlecruiser
        { 'ues0203', 1, 4, 'Attack', 'AttackFormation' },  -- Submarine
        { 'xes0205', 1, 2, 'Attack', 'AttackFormation' },  -- Shield Boat

    }
    Builder = {
        BuilderName = 'M2_UEF_Base_Battlecruiser_Builder_2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 120,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M2_UEF_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread' },       
        PlatoonData = {
            PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                            'M2_UEF_Base_NavalAttack_Chain_2',
                            'M2_UEF_Base_NavalAttack_Chain_3',
                            'M2_UEF_Base_NavalAttack_Chain_4'}
        },
        BuildConditions = {
            { '/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.NAVAL * categories.TECH3 * categories.MOBILE}},
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

    -- Battleship, 2 BCs, 2 sheilds if Player has more than 1 Battleship
    trigger = {3, 2, 1}
    opai = UEFM2Base:AddNavalAI('M2_UEF_Base_BattleshipAttack_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                                'M2_UEF_Base_NavalAttack_Chain_2',
                                'M2_UEF_Base_NavalAttack_Chain_3',
                                'M2_UEF_Base_NavalAttack_Chain_4'}
            },
            MaxFrigates = 25,
            MinFrigates = 25,
            Priority = 130,
            Overrides = {
                CORE_TO_FATTIES = 0.5,
                CORE_TO_UTILITY = 0.5,
            },
        }
    )
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.BATTLESHIP})

    -- 2 Batteships, 2 Battlecruisers, 4 shields
    trigger = {5, 4, 3}
    opai = UEFM2Base:AddNavalAI('M2_UEF_Base_BattleshipAttack_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                                'M2_UEF_Base_NavalAttack_Chain_2',
                                'M2_UEF_Base_NavalAttack_Chain_3',
                                'M2_UEF_Base_NavalAttack_Chain_4'}
            },
            MaxFrigates = 50,
            MinFrigates = 50,
            Priority = 140,
            Overrides = {
                CORE_TO_SUBS = 3,
                CORE_TO_FATTIES = 1,
                CORE_TO_UTILITY = 0.5,
            },
        }
    )
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.BATTLESHIP})

    -- 5 Batteships
    trigger = {7, 6, 5}
    opai = UEFM2Base:AddNavalAI('M2_UEF_Base_BattleshipAttack_3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                                'M2_UEF_Base_NavalAttack_Chain_2',
                                'M2_UEF_Base_NavalAttack_Chain_3',
                                'M2_UEF_Base_NavalAttack_Chain_4'}
            },
            MaxFrigates = 125,
            MinFrigates = 125,
            Priority = 150,
            Overrides = {
                CORE_TO_SUBS = 6,
                CORE_TO_CRUISERS = 6,
                CORE_TO_FATTIES = 6,
                CORE_TO_LIGHT = 6,
                CORE_TO_UTILITY = 6,
            }
        }
    )
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.BATTLESHIP})

    -- 5 Batteships
    trigger = {9, 8, 7}
    opai = UEFM2Base:AddNavalAI('M2_UEF_Base_BattleshipAttack_4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_UEF_Base_NavalAttack_Chain_1',
                                'M2_UEF_Base_NavalAttack_Chain_2',
                                'M2_UEF_Base_NavalAttack_Chain_3',
                                'M2_UEF_Base_NavalAttack_Chain_4'}
            },
            MaxFrigates = 150,
            MinFrigates = 150,
            Priority = 150,
            Overrides = {
                CORE_TO_SUBS = 7,
                CORE_TO_CRUISERS = 7,
                CORE_TO_FATTIES = 7,
                CORE_TO_LIGHT = 7,
                CORE_TO_UTILITY = 7,
            }
        }
    )
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.BATTLESHIP})

    for i = 1, 2 do
        opai = UEFM2Base:AddOpAI({'M2_Sonar_' .. i},
            {
                Amount = 1,
                KeepAlive = true,
                PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M2_UEF_Base_Sonar_Patrol_Chain_' .. i,
                },

                MaxAssist = 1,
                Retry = true,
            }
        )
    end
    ]]--
    --[[
    opai = UEFM2Base:AddOpAI({'M2_Atlantis_1', 'M2_Atlantis_2'},
        {
            Amount = 2,
            KeepAlive = true,
            PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_UEF_Base_NavalAttack_Chain_1',
            },

            MaxAssist = 6,
            Retry = true,
        }
    )
    ]]--
end

---------------------
-- UEF M2 Island Base
---------------------
function UEFM2IslandBaseAI(baseType)
    if baseType == 'Eco' then
        -- Economy Base
        UEFM2IslandBase:InitializeDifficultyTables(
            ArmyBrains[UEF],
            'M2_UEF_Island_Base',
            'M2_UEF_Island_Base_Marker',
            30,
            {
                M2_UEF_Island_Mass = 100,
                M2_UEF_Island_Eco = 100,
            }
        )
        UEFM2IslandBase:StartNonZeroBase(1)
        UEFM2Base:AddExpansionBase('M2_UEF_Island_Base', 1)

    elseif baseType == 'Gate' then
        -- Gate Base
        UEFM2IslandBase:InitializeDifficultyTables(
            ArmyBrains[UEF],
            'M2_UEF_Island_Base',
            'M2_UEF_Island_Base_Marker',
            30,
            {
                M2_UEF_Island_Gate = 100,
                M2_UEF_Island_Mass = 100,
                M2_UEF_Island_Defense = 100,
            }
        )
        UEFM2IslandBase:StartNonZeroBase(1)
        UEFM2IslandBase:SetSupportACUCount(1)
        UEFM2IslandBase:SetSACUUpgrades({'ResourceAllocation', 'RadarJammer', 'SensorRangeEnhancer'}, true)

        UEFM2IslandBaseSACUAttacks()

    elseif baseType == 'Nuke' then
        -- Nuke Base
        UEFM2IslandBase:InitializeDifficultyTables(
            ArmyBrains[UEF],
            'M2_UEF_Island_Base',
            'M2_UEF_Island_Base_Marker',
            30,
            {
                M2_UEF_Island_Nuke = 100,
                M2_UEF_Island_Mass = 100,
                M2_UEF_Island_Defense = 100,
            }
        )
        UEFM2IslandBase:StartNonZeroBase({1, 2, 3})

        ForkThread(UEFM2IslandBaseNukeAI)

    else
        WARN('UEFM2IslandBase: "baseType" NOT DEFINED')
    end
end

-- Island Nuke Ai
function UEFM2IslandBaseNukeAI()
    local nuke = ArmyBrains[UEF]:GetListOfUnits(categories.NUKE * categories.STRATEGIC * categories.STRUCTURE * categories.TECH3, false)[1]

    if not nuke then
        return
    end

    local waitTime = {Random(27.0, 21.0), Random(23.0, 27.0), Random(19.0, 23.0)}
    LOG('*speed2: Nuke activation wait time: ' .. waitTime[Difficulty])
    WaitSeconds(waitTime[Difficulty] * 60.0)

    -- Activate Nuke
    local plat = ArmyBrains[UEF]:MakePlatoon('', '')
    ArmyBrains[UEF]:AssignUnitsToPlatoon(plat, {nuke}, 'Attack', 'NoFormation')
    plat:ForkAIThread(plat.NukeAI)
end

-- Island SACU Attacks
function UEFM2IslandBaseSACUAttacks()

end