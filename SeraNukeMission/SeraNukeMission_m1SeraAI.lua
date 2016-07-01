local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

---------
-- Locals
---------
local Seraphim = 2
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local SeraphimBase = BaseManager.CreateBaseManager()


---------------------
-- Seraphim M1 Base
---------------------
function SeraphimBaseAI()
    SeraphimBase:InitializeDifficultyTables(ArmyBrains[Seraphim], 'SeraphimBase', 'SeraphimBaseMarker', 200, {M1_SeraphimBase = 210})
    SeraphimBase:StartNonZeroBase({{8, 7, 6}, {1, 1, 1}})
    SeraphimBase:SetActive('LandScouting', true)
    SeraphimBase:SetActive('AirScouting', true)

    --ForkThread(function()
    --    WaitSeconds(1)
    --    SeraphimBase:AddBuildGroup('SeraphimBase', 90)
    --end)
	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        SeraphimBase:AddBuildGroup('SeraphimSupportFactories', 200, true)
    end)
	
	
    M1SeraphimBaseDefensePatrols()
end

function M1SeraphimBaseDefensePatrols()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {12, 10, 8}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth',
                                'M1_SeraLandPatrolEast'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyTanks', 'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {12, 10, 8}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth',
                                'M1_SeraLandPatrolEast'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'MobileMissiles', 'LightArtillery'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {10, 8, 8}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'MobileFlak', 'LightBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

	quantity = {10, 8, 8}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'MobileFlak', 'LightBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	
	quantity = {12, 10, 8}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol5',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyTanks', 'LightTanks'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

  
	--Defense Air Patrol
    quantity = {14, 12, 10}
    opai = SeraphimBase:AddOpAI('AirAttacks', 'M1_AirPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Gunships', 'Interceptors'}, quantity[Difficulty])

		--Defense Air Patrol
	quantity = {14, 12, 10}
    opai = SeraphimBase:AddOpAI('AirAttacks', 'M1_AirPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Gunships', 'Interceptors'}, quantity[Difficulty])
	
			--Defense Air Patrol
	quantity = {14, 12, 10}
    opai = SeraphimBase:AddOpAI('AirAttacks', 'M1_AirPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth',
                                'M1_SeraLandPatrolEast'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Gunships', 'Interceptors'}, quantity[Difficulty])
	
	--[[
	local Temp = {
       'TestSealPatrolSouth',
       'NoPlan',
       { 'xss0201', 1, 3, 'Attack', 'GrowthFormation' },   # Destroyers
       { 'xss0202', 1, 3, 'Attack', 'GrowthFormation' },   # Cruisers
       { 'xss0203', 1, 6, 'Attack', 'GrowthFormation' },   # Shield Boat
   }
   Builder = {
       BuilderName = 'NavyAttackBuilder1',
       PlatoonTemplate = Temp,
       InstanceCount = 1,
       Priority = 400,
       PlatoonType = 'Sea',
       RequiresConstruction = true,
       LocationType = ('M1_SeraphimBase_D' .. Difficulty),
       BuildConditions = {

       },
       PlatoonAIFunction = {SPAIFileName, 'PatrolChainPickerThread'},     
       PlatoonData = {
           PatrolChains = {'M1_SeraSeaPatrolSouth'}
       },
   }
   ArmyBrains[Seraphim]:PBMAddPlatoon( Builder )
	]]--
	
	
				--Defense Sea Patrol South
    opai = SeraphimBase:AddNavalAI('M1_SeraSeaPatrolSouth1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M1_SeraSeaPatrolSouth',
            },
            EnabledTypes = {'Destroyer', 'Cruiser', 'Submarine','Frigate','Battleship'},
            MaxFrigates = 10,
            MinFrigates = 5,
            Priority = 110,
            --DisableTypes = {['T2Submarine'] = true}
        }
    )
    opai:SetChildActive('T3', false)
	
	
					--Defense Sea Patrol South
	opai = SeraphimBase:AddNavalAI('M1_SeraSeaPatrolSouth2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M1_SeraSeaPatrolSouth',
            },
            EnabledTypes = {'Destroyer', 'Cruiser', 'Submarine'},
            MaxFrigates = 15,
            MinFrigates = 5,
            Priority = 109,
        }
    )
    opai:SetChildActive('T3', false)
	


end

M2SeraphimAttacks = function()

	quantity = {8, 7, 6}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M2_LandAttackl',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PlatoonAttackClosestUnit'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyTanks'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

	--Defense Sea Patrol South
	opai = SeraphimBase:AddNavalAI('M2_SeraSeaAttack',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PlatoonAttackClosestUnit'},
            PlatoonData = {
                PatrolChain = 'M1_SeraSeaPatrolSouth',
            },
            EnabledTypes = {'Destroyer', 'Cruiser', 'Submarine','Battleship'},
            MaxFrigates = 30,
            MinFrigates = 20,
            Priority = 108,

            --DisableTypes = {['T2Submarine'] = true}
        }
    )
end

M3SeraphimAttacks = function()
						--Defense Sea Patrol South
	opai = SeraphimBase:AddNavalAI('M3_SeraSeaAttack',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PlatoonAttackClosestUnit'},
            PlatoonData = {
                PatrolChain = 'M1_SeraSeaPatrolSouth',
            },
            EnabledTypes = {'Destroyer', 'Cruiser', 'Submarine','Battleship'},
            MaxFrigates = 50,
            MinFrigates = 40,
            Priority = 108,

            --DisableTypes = {['T2Submarine'] = true}
        }
    )
end
