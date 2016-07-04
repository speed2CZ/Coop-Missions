local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

---------
-- Locals
---------
local UEF = 4
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local UEFM3AirBase = BaseManager.CreateBaseManager()
local UEFM3IslandBase = BaseManager.CreateBaseManager()
local UEFM3HeavyArtilleryBase = BaseManager.CreateBaseManager()

---------------------
---UEF M3 AirBase
---------------------
--(self, brain, baseName, markerName, radius, levelTable)
function UEFM3AirBaseAI()						--brain	      -- name of base --Marker   ---radius?    --army group and priority
    UEFM3AirBase:InitializeDifficultyTables(ArmyBrains[UEF], 'UEFM3AirBase', 'M3_UEFAirBase', 150, {M3_AirBase = 150})
    UEFM3AirBase:StartNonZeroBase({{4, 5, 6}, {1, 1, 1}})
    --UEFM3AirBase:SetActive('AirScouting', true)

	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        UEFM3AirBase:AddBuildGroup('M3_AirBaseSupportFactories', 200, true)
    end)

    UEFM3AirBaseAttacks()
end

function UEFM3AirBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

	--Air Attack against Order
    quantity = {20, 25, 30}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFAirAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Gunships'}, quantity[Difficulty])
  
	--Air Attack against Player
    quantity = {20, 25, 30}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFAirAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Gunships'}, quantity[Difficulty])

		--Air Attack against Order
	quantity = {10, 12, 14}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFAirAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships'}, quantity[Difficulty])
	
	--Air Attack against Order
	quantity = {6, 8, 10}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFAirAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'StratBombers'}, quantity[Difficulty])
	

end

function UEFM3HeavyArtilleryBaseAI()						--brain	      -- name of base --Marker   ---radius?    --army group and priority
    UEFM3HeavyArtilleryBase:InitializeDifficultyTables(ArmyBrains[UEF], 'UEFM3HeavyArtilleryBase', 'M3_UEFHeavyArtilleryBase', 150, {M3_HeavyArtilleryBase = 150})
    UEFM3HeavyArtilleryBase:StartNonZeroBase({{4, 5, 6}, {1, 1, 1}})
    UEFM3HeavyArtilleryBase:SetActive('AirScouting', true)

    UEFM3HeavyArtilleryBaseDefensePatrols()
end

function UEFM3HeavyArtilleryBaseDefensePatrols()
    local opai = nil
    local quantity = {}
    local trigger = {}

	--Gunship Defense
    quantity = {10, 12, 15}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFDefenseAirPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M3_UEFHeavyArtilleryBaseDefensePatrol1',
								'M3_UEFHeavyArtilleryBaseDefensePatrol2',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships', 'Gunships'}, quantity[Difficulty])
  
		--ASF Defense
    quantity = {10, 12, 15}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFDefenseAirPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M3_UEFHeavyArtilleryBaseDefensePatrol1',
								'M3_UEFHeavyArtilleryBaseDefensePatrol2',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'AirSuperiority'}, quantity[Difficulty])
	
		--Gunship Defense
    quantity = {10, 12, 15}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFDefenseAirPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M3_UEFHeavyArtilleryBaseDefensePatrol1',
								'M3_UEFHeavyArtilleryBaseDefensePatrol2',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships', 'Gunships'}, quantity[Difficulty])
  
		--ASF Defense
    quantity = {10, 12, 15}
    opai = UEFM3AirBase:AddOpAI('AirAttacks', 'M3_UEFDefenseAirPatrol4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M3_UEFHeavyArtilleryBaseDefensePatrol1',
								'M3_UEFHeavyArtilleryBaseDefensePatrol2',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'AirSuperiority'}, quantity[Difficulty])
end


function UEFM3IslandBaseAI()						--brain	      -- name of base --Marker   ---radius?    --army group and priority
    UEFM3IslandBase:InitializeDifficultyTables(ArmyBrains[UEF], 'UEFM3IslandBase', 'M3_UEFIslandBase', 150, {M3_IslandBase = 150})
    UEFM3IslandBase:StartNonZeroBase({{4, 5, 6}, {1, 1, 1}})
    UEFM3IslandBase:SetActive('AirScouting', true)

	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        UEFM3IslandBase:AddBuildGroup('M3_IslandBaseSupportFactories', 200, true)
    end)

    UEFM3IslandBaseAttacks()
end

function UEFM3IslandBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

	--Percival Attack
    quantity = {10, 15, 20}
    opai = UEFM3IslandBase:AddOpAI('BasicLandAttack', 'M3_PercivalAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
  
    quantity = {10, 15, 20}
    opai = UEFM3IslandBase:AddOpAI('BasicLandAttack', 'M3_PercivalAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	    quantity = {10, 15, 20}
    opai = UEFM3IslandBase:AddOpAI('BasicLandAttack', 'M3_PercivalAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
    quantity = {10, 15, 20}
    opai = UEFM3IslandBase:AddOpAI('BasicLandAttack', 'M3_PercivalAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
end