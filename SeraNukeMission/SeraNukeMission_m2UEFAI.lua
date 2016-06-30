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
local UEFM2AirBase = BaseManager.CreateBaseManager()

---------------------
---UEF M2 AirBase
---------------------
--(self, brain, baseName, markerName, radius, levelTable)
function UEFM2AirBaseAI()						--brain	      -- name of base --Marker   ---radius?    --army group and priority
    UEFM2AirBase:InitializeDifficultyTables(ArmyBrains[UEF], 'UEFM2AirBase', 'M2_UEFAirBase', 150, {M2_AirBase = 150})
    UEFM2AirBase:StartNonZeroBase({{4, 5, 6}, {1, 1, 1}})
    UEFM2AirBase:SetActive('AirScouting', true)

	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        UEFM2AirBase:AddBuildGroup('M2_AirBaseSupportFactories', 200, true)
    end)

    UEFM2AirBaseAttacks()
end

function UEFM2AirBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

	--Air Attack against Order
    quantity = {15, 20, 25}
    opai = UEFM2AirBase:AddOpAI('AirAttacks', 'M2_UEFAirAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderBase',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships', 'Gunships'}, quantity[Difficulty])
  
	--Air Attack against Player
    quantity = {10, 12, 14}
    opai = UEFM2AirBase:AddOpAI('AirAttacks', 'M2_UEFAirAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_YolonaOss',}
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships', 'Gunships'}, quantity[Difficulty])

		--Air Attack against Order
	quantity = {10, 12, 14}
    opai = UEFM2AirBase:AddOpAI('AirAttacks', 'M2_UEFAirAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships'}, quantity[Difficulty])
	
	--Air Attack against Order
	quantity = {6, 8, 10}
    opai = UEFM2AirBase:AddOpAI('AirAttacks', 'M2_UEFAirAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'StratBombers'}, quantity[Difficulty])
	

end

