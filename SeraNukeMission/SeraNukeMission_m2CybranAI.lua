local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

---------
-- Locals
---------
local Cybran = 6
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local CybranIslandBase = BaseManager.CreateBaseManager()

---------------------
---Order M2 Base
---------------------

function CybranIslandBaseAI()
    CybranIslandBase:InitializeDifficultyTables(ArmyBrains[Cybran], 'CybranIslandBase', 'M2_SouthIsland', 150, {M2_OrderBase = 150})
    CybranIslandBase:StartNonZeroBase({{9, 8, 7}, {1, 1, 1}})
    CybranIslandBase:SetActive('LandScouting', false)
    CybranIslandBase:SetActive('AirScouting', true)

	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        CybranIslandBase:AddBuildGroup('M2_IslandSupportFactories', 200, true)
    end)

    CybranIslandBaseAttacks()
end

function CybranIslandBaseDefensePatrols()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {10,15,20}
    opai = CybranIslandBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase', 'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'AmphibiousTanks'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
    quantity = {10,15,20}
    opai = CybranIslandBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase', 'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'AmphibiousTanks'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {10, 8, 6}
    opai = OrderBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase', 'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')


  

    quantity = {10, 9, 8}
    opai = CybranIslandBase:AddOpAI('AirAttacks', 'M2_AirPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase', 'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'CombatFighters', 'Gunships'}, quantity[Difficulty])


	quantity = {8, 7, 6}
    opai = CybranIslandBase:AddOpAI('AirAttacks', 'M2_AirPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase', 'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships'}, quantity[Difficulty])
	

end

