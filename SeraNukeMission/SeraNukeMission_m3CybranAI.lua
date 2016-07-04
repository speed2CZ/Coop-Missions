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
local CybranM3HeavyArtilleryBase = BaseManager.CreateBaseManager()

---------------------
---Cybra M3 Heavy Artillery Base
---------------------

function CybranM3HeavyArtilleryBaseAI()
    CybranM3HeavyArtilleryBase:InitializeDifficultyTables(ArmyBrains[Cybran], 'CybranHeavyArtilleryBase', 'M3_CybranHeavyArtilleryBase', 200, {M3_HeavyArtilleryBase = 150})
    CybranM3HeavyArtilleryBase:StartNonZeroBase({{3, 4, 5}, {1, 1, 1}})
    CybranM3HeavyArtilleryBase:SetActive('LandScouting', false)
    CybranM3HeavyArtilleryBase:SetActive('AirScouting', true)

	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        CybranM3HeavyArtilleryBase:AddBuildGroup('M3_HeavyArtilleryBaseSupportFactories', 200, true)
    end)

    CybranM3HeavyArtilleryBaseAttacks()
end

function CybranM3HeavyArtilleryBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {10,15,20}
    opai = CybranM3HeavyArtilleryBase:AddOpAI('BasicLandAttack', 'M3_LandPatrol1',
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
    opai = CybranM3HeavyArtilleryBase:AddOpAI('BasicLandAttack', 'M3_LandPatrol2',
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
    opai = CybranM3HeavyArtilleryBase:AddOpAI('BasicLandAttack', 'M3_LandPatrol3',
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
    opai = CybranM3HeavyArtilleryBase:AddOpAI('AirAttacks', 'M3_AirPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase', 'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Interceptors', 'Gunships'}, quantity[Difficulty])


	quantity = {8, 7, 6}
    opai = CybranM3HeavyArtilleryBase:AddOpAI('AirAttacks', 'M3_AirPatrol2',
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

