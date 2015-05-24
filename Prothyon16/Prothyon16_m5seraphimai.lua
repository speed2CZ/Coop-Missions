local BaseManager = import('/lua/ai/opai/basemanager.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

local SPAIFileName = '/lua/scenarioplatoonai.lua'

ScenarioInfo.Player = 1

# ------
# Locals
# ------
local Seraphim = 5
local Player = ScenarioInfo.Player

# -------------
# Base Managers
# -------------
local SeraphimM5MainBase = BaseManager.CreateBaseManager()
local SeraphimM5T3Base = BaseManager.CreateBaseManager()
local SeraphimM5NavDefBase = BaseManager.CreateBaseManager()
local SeraphimM5AirDefBase = BaseManager.CreateBaseManager()
local SeraphimM5IslandMiddleBase = BaseManager.CreateBaseManager()
local SeraphimM5IslandMiddleT1NavalBase = BaseManager.CreateBaseManager()
local SeraphimM5IslandMiddleT2NavalBase = BaseManager.CreateBaseManager()

function SeraphimM5MainBaseAI()

    # ---------------------
    # Seraphim M5 Main Base
    # ---------------------
    SeraphimM5MainBase:Initialize(ArmyBrains[Seraphim], 'M5_Sera_Main_Base', 'M5_Sera_Main_Base_Marker', 90, {M5_Sera_Main_Base = 100})
    SeraphimM5MainBase:StartNonZeroBase({40, 36})
    SeraphimM5MainBase:SetActive('AirScouting', true)

    SeraphimM5T3Base:Initialize(ArmyBrains[Seraphim], 'M5_Sera_T3_Base', 'M5_Sera_T3_Base_Marker', 40, {M5_Sera_T3_Base = 100})
    SeraphimM5T3Base:StartNonZeroBase({3, 2})

    SeraphimM5NavDefBase:Initialize(ArmyBrains[Seraphim], 'M5_Sera_Main_NavDef_Base', 'M5_Sera_Main_NavDef_Base_Marker', 30, {M5_Sera_Main_NavDef_Base = 100})
    SeraphimM5NavDefBase:StartNonZeroBase({4, 3})

    SeraphimM5AirDefBase:Initialize(ArmyBrains[Seraphim], 'M5_Sera_Main_AirDef_Base', 'M5_Sera_Main_AirDef_Base_Marker', 20, {M5_Sera_Main_AirDef_Base = 100})
    SeraphimM5AirDefBase:StartNonZeroBase({3, 2})
    
    SeraphimM5MainBaseAirAttacks()
    SeraphimM5MainBaseLandAttacks()
    SeraphimM5MainBaseNavalAttacks()
end

function SeraphimM5MainBaseAirAttacks()

	local opai = nil

    # Transport Builder
    opai = SeraphimM5MainBase:AddOpAI('EngineerAttack', 'M5_Sera_MainTransportBuilder',
    {
        MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
        PlatoonData = {
            AttackChain = 'M5_Sera_Middle_Transport_Attack_Chain',
            LandingChain = 'M5_Sera_Middle_Landing_Chain',
            TransportReturn = 'M5_Sera_Main_Base_Marker',
        },
        Priority = 1000,
    })
    opai:SetChildActive('All', false)
    opai:SetChildActive('T2Transports', true)
    opai:SetChildQuantity({'T2Transports'}, 4)
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {'default_brain', 4, categories.xsa0104})   # T2 Transport

    # Transport Builder
    opai = SeraphimM5AirDefBase:AddOpAI('EngineerAttack', 'M5_Sera_MainDefTransportBuilder',
    {
        MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
        PlatoonData = {
            AttackChain = 'M5_Sera_Middle_Transport_Attack_Chain',
            LandingChain = 'M5_Sera_Middle_Landing_Chain',
            TransportReturn = 'M5_Sera_Main_AirDef_Base_Marker',
        },
        Priority = 1000,
    })
    opai:SetChildActive('All', false)
    opai:SetChildActive('T2Transports', true)
    opai:SetChildQuantity({'T2Transports'}, 1)
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {'default_brain', 1, categories.xsa0104})   # T2 Transport

	# Builds platoon of 10 Bombers 6 times
	for i = 1, 6 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackPlayer1_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_AirAttackPlayer_Chain1', 'M5_Sera_Main_AirAttackPlayer_Chain2', 'M5_Sera_Main_AirAttackPlayer_Chain3', 'M5_Sera_Main_AirAttackPlayer_Chain4', 'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
	            },
	            Priority = 100,
	        }
	    )
	    opai:SetChildQuantity('Bombers', 10)
	end

	# Builds platoon of 10 Gunships 6 times
	for i = 1, 6 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackPlayer2_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_AirAttackPlayer_Chain1', 'M5_Sera_Main_AirAttackPlayer_Chain2', 'M5_Sera_Main_AirAttackPlayer_Chain3', 'M5_Sera_Main_AirAttackPlayer_Chain4', 'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
	            },
	            Priority = 110,
	        }
	    )
	    opai:SetChildQuantity('Gunships', 10)
	end

	# Builds platoon of 20 Interceptors 4 times if Player has more than 60 mobile air
	for i = 1, 4 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackPlayer3_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_AirAttackPlayer_Chain1', 'M5_Sera_Main_AirAttackPlayer_Chain2', 'M5_Sera_Main_AirAttackPlayer_Chain3', 'M5_Sera_Main_AirAttackPlayer_Chain4', 'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
	            },
	            Priority = 100,
	        }
	    )
	    opai:SetChildQuantity('Interceptors', 20)
	    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', 60, categories.AIR * categories.MOBILE})
	end

	local Temp = {
        'M5SeraComabtFighetTemp1',
        'NoPlan',
        { 'xsa0202', 1, 10, 'Attack', 'AttackFormation' },   # T2 CombatFighter
    }
    local Builder = {
        BuilderName = 'M5SeraCombatFighterAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 4,
        Priority = 110,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        BuildConditions = {
            { '/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', 80, categories.AIR * categories.MOBILE}},
        },
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},       
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_AirAttackPlayer_Chain1', 'M5_Sera_Main_AirAttackPlayer_Chain2', 'M5_Sera_Main_AirAttackPlayer_Chain3', 'M5_Sera_Main_AirAttackPlayer_Chain4', 'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    # Builds platoon of 10 TorpedoBombers 4 times if Player has more than 10 T2 Naval Units
	for i = 1, 4 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackPlayer4_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
	            },
	            Priority = 120,
	        }
	    )
	    opai:SetChildQuantity('TorpedoBombers', 10)
	    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', 10, categories.NAVAL * categories.TECH2})
	end

	#---------------
	# Attacks on UEF
	#---------------

	# Builds platoon of 10 Bombers 2 times
	for i = 1, 2 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackUEF1_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_Air_AttackUEF_Chain1', 'M5_Sera_Main_Air_AttackUEF_Chain2', 'M5_Sera_Main_Hover_AttackUEF_Chain'},
	            },
	            Priority = 110,
	        }
	    )
	    opai:SetChildQuantity('Bombers', 10)
	end

	# Builds platoon of 10 Gunships 2 times
	for i = 1, 2 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackUEF2_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_Air_AttackUEF_Chain1', 'M5_Sera_Main_Air_AttackUEF_Chain2', 'M5_Sera_Main_Hover_AttackUEF_Chain'},
	            },
	            Priority = 120,
	        }
	    )
	    opai:SetChildQuantity('Gunships', 10)
	end

	# Builds platoon of 20 Interceptors 2 times 
	for i = 1, 2 do
	    opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackUEF3_' .. i,
	        {
	            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	            PlatoonData = {
	                PatrolChains = {'M5_Sera_Main_Air_AttackUEF_Chain1', 'M5_Sera_Main_Air_AttackUEF_Chain2', 'M5_Sera_Main_Hover_AttackUEF_Chain'},
	            },
	            Priority = 110,
	        }
	    )
	    opai:SetChildQuantity('Interceptors', 20)
	end

	local Temp = {
        'M5SeraComabtFighetTemp2',
        'NoPlan',
        { 'xsa0202', 1, 10, 'Attack', 'AttackFormation' },   # T2 CombatFighter
    }
    local Builder = {
        BuilderName = 'M5SeraCombatFighterAttackBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 120,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},       
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Air_AttackUEF_Chain1', 'M5_Sera_Main_Air_AttackUEF_Chain2', 'M5_Sera_Main_Hover_AttackUEF_Chain'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    # Builds platoon of 10 TorpedoBombers
	opai = SeraphimM5MainBase:AddOpAI('AirAttacks', 'M5_Sera_Main_AirAttackUEF4',
	   {
	       MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
	       PlatoonData = {
	           PatrolChains = {'M5_Sera_Main_Air_AttackUEF_Chain1', 'M5_Sera_Main_Air_AttackUEF_Chain2', 'M5_Sera_Main_Hover_AttackUEF_Chain'},
	       },
	       Priority = 120,
	   }
	)
	opai:SetChildQuantity('TorpedoBombers', 10)

	# Air Defense
    # Maintains 30 Interceptors
    for i = 1, 6 do
        opai = SeraphimM5AirDefBase:AddOpAI('AirAttacks', 'M5_MainAirDefense1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M5_Sera_Main_Base_Air_Def_Chain',
                },
                Priority = 110,
            }
        )
        opai:SetChildQuantity({'Interceptors'}, 5)
    end

    # Maintains 16 Gunships
    for i = 1, 4 do
        opai = SeraphimM5AirDefBase:AddOpAI('AirAttacks', 'M5_MainAirDefense2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M5_Sera_Main_Base_Air_Def_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'Gunships'}, 4)
    end

    # Maintains 20 Tropedo Bombers
    for i = 1, 4 do
        opai = SeraphimM5AirDefBase:AddOpAI('AirAttacks', 'M5_MainAirDefense3_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'RandomDefensePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M5_Sera_Main_Base_Air_Def_Chain',
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity({'TorpedoBombers'}, 5)
    end

end

function SeraphimM5MainBaseLandAttacks()

	local opai = nil

	local Temp = {
        'SeraM5HoverAttackTemp1',
        'NoPlan',
        { 'xsl0203', 1, 10, 'Attack', 'AttackFormation' },   # Hover Tank
        { 'xsl0205', 1, 4, 'Attack', 'AttackFormation' },   # Hover Flak
    }
    local Builder = {
        BuilderName = 'SeraM5HoverAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 4,
        Priority = 100,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'M5SeraEngineerAttackTemp1',
        'NoPlan',
        { 'xsl0105', 1, 1, 'Attack', 'None' },   # T1 Engies
    }
    Builder = {
        BuilderName = 'M5SeraEngineerAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 15,
        Priority = 110,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_AirDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},       
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Air_AttackUEF_Chain1', 'M5_Sera_Main_Hover_AttackUEF_Chain', 'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'M5SeraEngineerAttackTemp2',
        'NoPlan',
        { 'xsl0105', 1, 1, 'Attack', 'None' },   # T1 Engies
    }
    Builder = {
        BuilderName = 'M5SeraEngineerAttackBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 20,
        Priority = 110,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_AirDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},       
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3', 'M5_Sera_Main_AirAttackPlayer_Chain1', 'M5_Sera_Main_AirAttackPlayer_Chain2', 'M5_Sera_Main_AirAttackPlayer_Chain3', 'M5_Sera_Main_AirAttackPlayer_Chain4', },
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    # sends 12 [hover tanks] 6 times
    for i = 1, 6 do
        opai = SeraphimM5MainBase:AddOpAI('BasicLandAttack', 'M5_Sera_HoverAttack1_' ..i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
                },
                Priority = 110,
            }
        )
        opai:SetChildQuantity('AmphibiousTanks', 12)
    end

    # sends 4 [hover flak] 3 times
    for i = 1, 3 do
        opai = SeraphimM5MainBase:AddOpAI('BasicLandAttack', 'M5_Sera_HoverAttack2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
                },
                Priority = 110,
            }
        )
        opai:SetChildQuantity('AmphibiousTanks', 12)
    end

    # sends 10 [hover tanks] 4 times
    for i = 1, 3 do
        opai = SeraphimM5MainBase:AddOpAI('BasicLandAttack', 'M5_Sera_HoverUEFAttack1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_Sera_Main_Hover_AttackUEF_Chain', 'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
                },
                Priority = 110,
            }
        )
        opai:SetChildQuantity('AmphibiousTanks', 10)
    end

end

function SeraphimM5MainBaseNavalAttacks()

    local Temp = {
        'SeraM5NavalAttackPlayerTemp1',
        'NoPlan',
        { 'xss0201', 1, 6, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
        { 'xss0203', 1, 8, 'Attack', 'AttackFormation' },   # T1 Sub
    }
    local Builder = {
        BuilderName = 'SeraM5NavyAttackPlayerBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalAttackPlayerTemp2',
        'NoPlan',
        { 'xss0201', 1, 2, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0103', 1, 12, 'Attack', 'AttackFormation' },   # Frigate
    }
    Builder = {
        BuilderName = 'SeraM5NavyAttackPlayerBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalAttackPlayerTemp3',
        'NoPlan',
        { 'xss0201', 1, 4, 'Attack', 'AttackFormation' },   # Destroyers
    }
    Builder = {
        BuilderName = 'SeraM5NavyAttackPlayerBuilder3',
        PlatoonTemplate = Temp,
        InstanceCount = 3,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalT3AttackPlayerTemp1',
        'NoPlan',
        { 'xss0302', 1, 1, 'Attack', 'GrowthFormation' },   # Battleship
        { 'xss0201', 1, 2, 'Attack', 'GrowthFormation' },   # Destroyers
        { 'xss0203', 1, 3, 'Attack', 'GrowthFormation' },   # T1 Sub
    }
    Builder = {
        BuilderName = 'SeraM5NavyT3AttackPlayerBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 300,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_T3_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalT3AttackPlayerTemp2',
        'NoPlan',
        { 'xss0201', 1, 5, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
        { 'xss0103', 1, 9, 'Attack', 'AttackFormation' },   # Frigate
    }
    Builder = {
        BuilderName = 'SeraM5NavyT3AttackPlayerBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_T3_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackPlayer_Chain1', 'M5_Sera_Main_Naval_AttackPlayer_Chain2', 'M5_Sera_Main_Naval_AttackPlayer_Chain3'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    #-----------
    # Attack UEF
	#-----------
    Temp = {
        'SeraM5NavalAttackUEFTemp3',
        'NoPlan',
        { 'xss0201', 1, 5, 'Attack', 'AttackFormation' },   # Destroyers
    }
    Builder = {
        BuilderName = 'SeraM5NavyAttackUEFBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 300,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalT3AttackUEFTemp1',
        'NoPlan',
        { 'xss0201', 1, 6, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
    }
    Builder = {
        BuilderName = 'SeraM5NavyT3AttackUEFBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 400,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_T3_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalT3AttackUEFTemp2',
        'NoPlan',
        { 'xss0201', 1, 4, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
    }
    Builder = {
        BuilderName = 'SeraM5NavyT3AttackUEFBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 250,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_T3_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalDefAttackUEFTemp1',
        'NoPlan',
        { 'xss0201', 1, 4, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
    }
    Builder = {
        BuilderName = 'SeraM5NavyDefAttackUEFBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 150,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_NavDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalDefAttackUEFTemp3',
        'NoPlan',
        { 'xss0201', 1, 5, 'Attack', 'AttackFormation' },   # Destroyers
    }
    Builder = {
        BuilderName = 'SeraM5NavyDefAttackUEFBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 150,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_NavDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},
        PlatoonData = {
            PatrolChains = {'M5_Sera_Main_Naval_AttackUEF_Chain1', 'M5_Sera_Main_Naval_AttackUEF_Chain2'},
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    # -------
    # Defense
    # -------
    Temp = {
        'SeraM5NavalDefenseTemp1',
        'NoPlan',
        { 'xss0201', 1, 7, 'Attack', 'GrowthFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'GrowthFormation' },   # Cruisers
    }
    Builder = {
        BuilderName = 'SeraM5NavyDefenseBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_NavDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_Sera_Main_Naval_Def_Chain2',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalDefenseTemp2',
        'NoPlan',
        { 'xss0201', 1, 7, 'Attack', 'GrowthFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'GrowthFormation' },   # Cruisers
    }
    Builder = {
        BuilderName = 'SeraM5NavyDefenseBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_NavDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_Sera_Main_Naval_Def_Chain3',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalDefenseTemp3',
        'NoPlan',
        { 'xss0302', 1, 1, 'Attack', 'GrowthFormation' },   # Battleship
    }
    Builder = {
        BuilderName = 'SeraM5NavyDefenseBuilder3',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 190,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_NavDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_Sera_Main_Naval_Def_Chain1',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalDefenseTemp4',
        'NoPlan',
        { 'xss0304', 1, 2, 'Attack', 'GrowthFormation' },   # T3 Sub Hunter
    }
    Builder = {
        BuilderName = 'SeraM5NavyDefenseBuilder4',
        PlatoonTemplate = Temp,
        InstanceCount = 2,
        Priority = 190,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Main_NavDef_Base',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},     
        PlatoonData = {
            PatrolChain = 'M5_Sera_Main_Naval_Def_Chain1',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

end

function SeraphimM5IslandMiddleBaseAI()

    # ------------------------------
    # Seraphim M5 Island Middle Base
    # ------------------------------
    SeraphimM5AirDefBase:AddBuildGroup('M5_Sera_Island_Middle_Base', 90)

    SeraphimM5IslandMiddleBase:Initialize(ArmyBrains[Seraphim], 'M5_Sera_Island_Middle_Base', 'M5_Sera_Island_Middle_Base_Marker', 60, {M5_Sera_Island_Middle_Base = 100})
    SeraphimM5IslandMiddleBase:StartNonZeroBase({20, 16})
    SeraphimM5IslandMiddleBase:SetActive('AirScouting', true)
    # SeraphimM5IslandMiddleBase:SetMaximumConstructionEngineers(4)
    # SeraphimM5IslandMiddleBase:SetPermanentAssistCount(16)

    SeraphimM5IslandMiddleT1NavalBase:Initialize(ArmyBrains[Seraphim], 'M5_Sera_Island_Middle_Base_T1_Naval', 'M5_Sera_Island_Middle_Base_T1_Naval_Marker', 40, {M5_Sera_Island_Middle_Base_T1_Naval = 100})
    SeraphimM5IslandMiddleT1NavalBase:StartNonZeroBase({8, 7})

    SeraphimM5IslandMiddleT2NavalBase:Initialize(ArmyBrains[Seraphim], 'M5_Sera_Island_Middle_Base_T2_Naval', 'M5_Sera_Island_Middle_Base_T2_Naval_Marker', 30, {M5_Sera_Island_Middle_Base_T2_Naval = 100})
    SeraphimM5IslandMiddleT2NavalBase:StartEmptyBase({4, 3})

    SeraphimM5IslandMiddleBase:AddBuildGroup('M5_Sera_Island_Middle_BaseUnfinished', 95)
    SeraphimM5IslandMiddleBase:AddBuildGroup('M5_Sera_Island_Middle_Base_T1_Naval', 90)
    SeraphimM5IslandMiddleBase:AddBuildGroup('M5_Sera_Island_Middle_Base_T2_Naval', 86)
    
    SeraphimM5IslandMiddleBaseAirAttacks()
    SeraphimM5IslandMiddleBaseLandAttacks()
    SeraphimM5IslandMiddleBaseNavalAttacks()
end

function SeraphimM5IslandMiddleBaseAirAttacks()

    local opai = nil

    # Builds platoon of 8 Bombers 2 times
    for i = 1, 2 do
        opai = SeraphimM5IslandMiddleBase:AddOpAI('AirAttacks', 'M5_Sera_Middle_AirAttackUEF1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_Sera_Middle_Air_AttackUEF_Chain1', 'M5_Sera_Middle_Air_AttackUEF_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('Bombers', 8)
    end

    # Builds platoon of 10 Gunships 2 times
    for i = 1, 2 do
        opai = SeraphimM5IslandMiddleBase:AddOpAI('AirAttacks', 'M5_Sera_Middle_AirAttackUEF2_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_Sera_Middle_Air_AttackUEF_Chain1', 'M5_Sera_Middle_Air_AttackUEF_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('Gunships', 10)
    end

    # Builds platoon of 10 TorpedoBombers
    opai = SeraphimM5IslandMiddleBase:AddOpAI('AirAttacks', 'M5_Sera_Middle_AirAttackUEF3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M5_Sera_Middle_Air_AttackUEF_Chain1', 'M5_Sera_Middle_Air_AttackUEF_Chain2'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity('TorpedoBombers', 10)

    # Builds platoon of 12 Gunships 2 times
    for i = 1, 2 do
        opai = SeraphimM5IslandMiddleBase:AddOpAI('AirAttacks', 'M5_Sera_Middle_AirAttackUEF4_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
                PlatoonData = {
                    PatrolChains = {'M5_Sera_Middle_Air_AttackUEF_Chain1', 'M5_Sera_Middle_Air_AttackUEF_Chain2'},
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity('Interceptors', 12)
    end

end

function SeraphimM5IslandMiddleBaseLandAttacks()

    local opai = nil
    
    # Transport Builder
    local opai = SeraphimM5IslandMiddleBase:AddOpAI('EngineerAttack', 'M5_Sera__MiddleTransportBuilder',
    {
        MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
        PlatoonData = {
            AttackChain = 'M5_Sera_Middle_Transport_Attack_Chain',
            LandingChain = 'M5_Sera_Middle_Landing_Chain',
            TransportReturn = 'M5_Sera_Middle_Transport_Marker',
        },
        Priority = 1000,
    })
    opai:SetChildActive('All', false)
    opai:SetChildActive('T2Transports', true)
    opai:SetChildQuantity({'T2Transports'}, 4)
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {'default_brain', 4, categories.xsa0104})   # T2 Transport

    for i = 1, 2 do
        opai = SeraphimM5IslandMiddleBase:AddOpAI('BasicLandAttack', 'M5_Sera_Middle_TransportAttack1_' .. i,
        {
            MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
            PlatoonData = {
                AttackChain = 'M5_Sera_Middle_Transport_Attack_Chain',
                LandingChain = 'M5_Sera_Middle_Landing_Chain',
                TransportReturn = 'M5_Sera_Middle_Transport_Marker',
            },
            Priority = 100,
        })
        opai:SetChildQuantity('AmphibiousTanks', 16)
    end

    for i = 1, 2 do
        opai = SeraphimM5IslandMiddleBase:AddOpAI('BasicLandAttack', 'M5_Sera_Middle_TransportAttack2_' .. i,
        {
            MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
            PlatoonData = {
                AttackChain = 'M5_Sera_Middle_Transport_Attack_Chain',
                LandingChain = 'M5_Sera_Middle_Landing_Chain',
                TransportReturn = 'M5_Sera_Middle_Transport_Marker',
            },
            Priority = 100,
        })
        opai:SetChildQuantity('LightArtillery', 16)
    end

end

function SeraphimM5IslandMiddleBaseNavalAttacks()

    local Temp = {
        'SeraM5NavalT2MiddleAttackTemp1',
        'NoPlan',
        { 'xss0201', 1, 4, 'Attack', 'AttackFormation' },   # Destroyers
        { 'xss0202', 1, 2, 'Attack', 'AttackFormation' },   # Cruisers
    }
    local Builder = {
        BuilderName = 'SeraM5NavyT2MiddleAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 200,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Island_Middle_Base_T2_Naval',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
        PlatoonData = {
            PatrolChain = 'M5_Sera_Middle_Naval_Attack_Chain',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalT2MiddleAttackTemp2',
        'NoPlan',
        { 'xss0201', 1, 4, 'Attack', 'AttackFormation' },   # Destroyers
    }
    Builder = {
        BuilderName = 'SeraM5NavyT2MiddleAttackBuilder2',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 250,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Island_Middle_Base_T2_Naval',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
        PlatoonData = {
            PatrolChain = 'M5_Sera_Middle_Naval_Attack_Chain',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

    Temp = {
        'SeraM5NavalT1MiddleAttackTemp1',
        'NoPlan',
        { 'xss0103', 1, 8, 'Attack', 'AttackFormation' },   # Frigate
        { 'xss0203', 1, 4, 'Attack', 'AttackFormation' },   # T1 Sub
    }
    Builder = {
        BuilderName = 'SeraM5NavyT1MiddleAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 3,
        Priority = 250,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        LocationType = 'M5_Sera_Island_Middle_Base_T1_Naval',
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
        PlatoonData = {
            PatrolChain = 'M5_Sera_Middle_Naval_Attack_Chain',
        },
    }
    ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )

end