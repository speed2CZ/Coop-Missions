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
    SeraphimBase:InitializeDifficultyTables(ArmyBrains[Seraphim], 'SeraphimBase', 'SeraphimBaseMarker', 150, {M1_SeraphimBase = 100})
    SeraphimBase:StartNonZeroBase({{8, 7, 5}, {1, 1, 1}})
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

    SeraphimBaseDefensePatrols()
end

function SeraphimBaseDefensePatrols()
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
    opai:SetChildQuantity({'SiegeBots', 'HeavyTanks', 'LightTanks'}, quantity[Difficulty])
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
	
	quantity = {10, 8, 6}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth',
                                'M1_SeraLandPatrolEast'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'MobileFlak', 'LightBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

	quantity = {10, 8, 6}
    opai = SeraphimBase:AddOpAI('BasicLandAttack', 'M1_LandPatrol4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraLandPatrolSouth',
                                'M1_SeraLandPatrolEast'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'MobileFlak', 'LightBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	

  
	--Defense Air Patrol
    quantity = {8, 7, 6}
    opai = SeraphimBase:AddOpAI('AirAttacks', 'M1_AirPatrol1',
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

		--Defense Air Patrol
	quantity = {8, 7, 6}
    opai = SeraphimBase:AddOpAI('AirAttacks', 'M1_AirPatrol2',
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
	

end

