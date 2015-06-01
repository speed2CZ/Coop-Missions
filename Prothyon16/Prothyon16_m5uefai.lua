local BaseManager = import('/lua/ai/opai/basemanager.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

local SPAIFileName = '/lua/scenarioplatoonai.lua'

ScenarioInfo.Player = 1

# ------
# Locals
# ------
local UEF = 2
local Player = ScenarioInfo.Player

# -------------
# Base Managers
# -------------
local UEFM5IslandBase = BaseManager.CreateBaseManager()

function UEFM5IslandBaseAI()

    # ------------------
    # UEF M5 Island Base
    # ------------------
    UEFM5IslandBase:Initialize(ArmyBrains[UEF], 'M5_UEF_Island_Base', 'M5_UEF_Island_Base_Marker', 100, {M5_UEF_Island_Base = 100})
    UEFM5IslandBase:StartNonZeroBase({30, 26})
    UEFM5IslandBase:SetMaximumConstructionEngineers(4)
    UEFM5IslandBase:SetActive('AirScouting', true)
    UEFM5IslandBase:SetSupportACUCount(1)

    UEFM5IslandBase:AddBuildGroup('M5_UEF_Island_Base_Defences', 90, true)

    UEFM5IslandBaseAirAttacks()
    UEFM5IslandBaseLandAttacks()
    UEFM5IslandBaseNavalAttacks()
end

function UEFM5IslandBaseAirAttacks()

	local opai = nil

    # Sends 3 x 5 Torpedo Bombers
    for i = 1, 3 do
        opai = UEFM5IslandBase:AddOpAI('AirAttacks', 'M5_IslandAirAttack1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_UEF_Island_Air_Attack_Chain1','M5_UEF_Island_Air_Attack_Chain2', 'M5_UEF_Island_Hover_Attack_Chain', 'M5_UEF_Island_Naval_Attack_Chain1', 'M5_UEF_Island_Naval_Attack_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'TorpedoBombers'}, 5)
    end

    # Sends 2 x 5 Gunships
    for i = 1, 2 do
        opai = UEFM5IslandBase:AddOpAI('AirAttacks', 'M5_IslandAirAttack2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_UEF_Island_Air_Attack_Chain1','M5_UEF_Island_Air_Attack_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'Gunships'}, 5)
    end

    # Sends 3 x 5 Interceptors
    for i = 1, 3 do
        opai = UEFM5IslandBase:AddOpAI('AirAttacks', 'M5_IslandAirAttack3_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_UEF_Island_Air_Attack_Chain1','M5_UEF_Island_Air_Attack_Chain2', 'M5_UEF_Island_Hover_Attack_Chain', 'M5_UEF_Island_Naval_Attack_Chain1', 'M5_UEF_Island_Naval_Attack_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'Interceptors'}, 5)
    end

	# Air Defense
    # Maintains 30 Interceptors
    for i = 1, 6 do
        opai = UEFM5IslandBase:AddOpAI('AirAttacks', 'M5_IslandAirDefense1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M5_UEF_Island_Air_Defense_Chain',
                },
                Priority = 110,
            }
        )
        opai:SetChildQuantity({'Interceptors'}, 5)
    end

    # Maintains 15 Gunships
    for i = 1, 3 do
        opai = UEFM5IslandBase:AddOpAI('AirAttacks', 'M5_IslandAirDefense2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M5_UEF_Island_Air_Defense_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'Gunships'}, 5)
    end

    # Maintains 16 Tropedo Bombers
    for i = 1, 4 do
        opai = UEFM5IslandBase:AddOpAI('AirAttacks', 'M5_IslandAirDefense3_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M5_UEF_Island_Air_Defense_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'TorpedoBombers'}, 4)
    end

    local Temp = {
        'M5ComabtFighetTemp1',
        'NoPlan',
        { 'dea0202', 1, 5, 'Attack', 'GrowthFormation' },   # T2 CombatFighter
    }
    local Builder = {
        BuilderName = 'M5CombatFighterAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 3,
        Priority = 110,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'M5_UEF_Island_Base',
        PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},       
        PlatoonData = {
            PatrolChain = 'M5_UEF_Island_Air_Defense_Chain',
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

end

function UEFM5IslandBaseLandAttacks()

    local opai = nil

    local Temp = {
        'UEFM5EngieTemp1',
        'NoPlan',
        { 'xel0209', 1, 2, 'Attack', 'None' },   # Sparky
    }
    local Builder = {
        BuilderName = 'UEFM5EngieBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 4,
        Priority = 120,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'M5_UEF_Island_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},     
        PlatoonData = {
            PatrolChains = {'M5_UEF_Island_Hover_Attack_Chain', 'M5_UEF_Island_Naval_Attack_Chain1', 'M5_UEF_Island_Naval_Attack_Chain2', 'M5_UEF_Island_Naval_Defense_Chain1'},
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

    Temp = {
        'UEFM5EngieTemp1',
        'NoPlan',
        { 'xel0209', 1, 2, 'Attack', 'None' },   # Sparky
    }
    Builder = {
        BuilderName = 'UEFM5EngieBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 110,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'M5_UEF_Island_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_UEF_Island_Base_EngineersChain',
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

    # sends 12 [hover tanks] 5 times
    for i = 1, 5 do
        opai = UEFM5IslandBase:AddOpAI('BasicLandAttack', 'M5_UEF_HoverAttack1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_UEF_Island_Hover_Attack_Chain', 'M5_UEF_Island_Naval_Attack_Chain1', 'M5_UEF_Island_Naval_Attack_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('AmphibiousTanks', 12)
    end


end

function UEFM5IslandBaseNavalAttacks()

    local Temp = {
        'UEFM5NavalAttackTemp1',
        'NoPlan',
        { 'ues0201', 1, 4, 'Attack', 'AttackFormation' },   # Destroyers
        { 'ues0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
        { 'xes0205', 1, 2, 'Attack', 'AttackFormation' },   # Shield Boat
    }
    local Builder = {
        BuilderName = 'UEFM5NavyAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_UEF_Island_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},     
        PlatoonData = {
            PatrolChains = {'M5_UEF_Island_Naval_Attack_Chain1', 'M5_UEF_Island_Naval_Attack_Chain2'},
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

	# Defense
    local Temp = {
        'UEFM5NavalDefenseTemp1',
        'NoPlan',
        { 'ues0201', 1, 4, 'Attack', 'GrowthFormation' },   # Destroyers
        { 'ues0202', 1, 2, 'Attack', 'GrowthFormation' },   # Cruisers
        { 'xes0205', 1, 2, 'Attack', 'GrowthFormation' },   # Shield Boat
    }
    local Builder = {
        BuilderName = 'UEFM5NavyDefenseBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 220,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_UEF_Island_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_UEF_Island_Naval_Defense_Chain1',
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

    Temp = {
        'UEFM5NavalDefenseTemp2',
        'NoPlan',
        { 'ues0201', 1, 4, 'Attack', 'GrowthFormation' },   # Destroyers
    }
    Builder = {
        BuilderName = 'UEFM5NavyDefenseBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 210,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_UEF_Island_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_UEF_Island_Naval_Defense_Chain2',
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )

end