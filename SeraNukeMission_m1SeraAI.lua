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
    SeraphimBase:StartNonZeroBase({{5, 4, 4}, {1, 1, 1}})
    SeraphimBase:SetActive('LandScouting', true)
    SeraphimBase:SetActive('AirScouting', true)

    ForkThread(function()
        WaitSeconds(1)
        SeraphimBase:AddBuildGroup('SeraphimBase', 90)
    end)
	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        SeraphimBase:AddBuildGroup('SeraphimSupportFactories', 100, true)
    end)

    SeraphimBaseDefensePatrols()
end

function SeraphimBaseDefensePatrols()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {12, 10, 10}
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
    opai:SetChildQuantity({'HeavyTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {12, 10, 10}
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
    opai:SetChildQuantity({'HeavyTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {12, 10, 10}
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
    opai:SetChildQuantity({'HeavyTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

    quantity = {12, 10, 10}
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
    opai:SetChildQuantity({'Interceptors', 'Gunships', 'FighterBomber'}, quantity[Difficulty])

end

