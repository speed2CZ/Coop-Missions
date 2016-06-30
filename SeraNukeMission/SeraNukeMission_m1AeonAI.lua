local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

---------
-- Locals
---------
local Aeon = 5
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local AeonM1AirBase = BaseManager.CreateBaseManager()
local AeonM1LandBase = BaseManager.CreateBaseManager()

---------------------
-- Aeon M1 Air Base
---------------------
function AeonM1AirBaseAI()
    AeonM1AirBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M1AeonAirBase', 'M1AeonAirBaseMarker', 35, {M1_AirBase_1 = 100})
    AeonM1AirBase:StartNonZeroBase({{2, 2, 3}, {1, 1, 1}})
    #AeonM1AirBase:SetActive('LandScouting', true)
    AeonM1AirBase:SetActive('AirScouting', true)

    ForkThread(function()
        --WaitSeconds(100 - 30*Difficulty)
		WaitSeconds(5)
        AeonM1AirBase:AddBuildGroup('M1AeonAirBase', 90)
    end)

	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        AeonM1AirBase:AddBuildGroup('M1_AirBaseSupportFactories', 100, true)
    end)
	
    M1AeonAirBaseAttacks()
end

function M1AeonAirBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {12, 16, 20}
    opai = AeonM1AirBase:AddOpAI('AirAttacks', 'M1_NorthAirAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon',
                                'M1_AmphibiousAttack_Aeon',
								'M1_YolonaOss'},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity('Gunships', quantity[Difficulty])
    opai:SetLockingStyle('None')

    quantity = {8, 12, 16}
    opai = AeonM1AirBase:AddOpAI('AirAttacks', 'M1_NorthAirAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon',
                                'M1_AmphibiousAttack_Aeon',
								'M1_YolonaOss'},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity('HeavyGunships', quantity[Difficulty])
	
	quantity = {10, 15, 20} --difficulty
    opai = AeonM1AirBase:AddOpAI('AirAttacks', 'M1_NorthAirAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon',
                                'M1_AmphibiousAttack_Aeon',
								'M1_YolonaOss'},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity({'Bombers', 'HeavyGunships', 'AirSuperiority'}, quantity[Difficulty])
	
	quantity = {10, 15, 20} --difficulty
    opai = AeonM1AirBase:AddOpAI('AirAttacks', 'M1_NorthAirAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon',
                                'M1_AmphibiousAttack_Aeon',
								'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Bombers', 'HeavyGunships', 'AirSuperiority'}, quantity[Difficulty])


end


--------------------
-- Aeon M1 Land Base
--------------------
function AeonM1LandBaseAI()
    AeonM1LandBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M1AeonLandBase', 'M1AeonLandBaseMarker', 50, {M1_LandBase_1 = 100})
    AeonM1LandBase:StartNonZeroBase({{3, 3, 4}, {2, 2, 3}})

	AeonM1LandBase:SetActive('LandScouting', true)
	
	ForkThread(function()
        --WaitSeconds(100 - 30*Difficulty)
		WaitSeconds(5)
        AeonM1LandBase:AddBuildGroup('M1AeonLandBase', 90)
    end)
	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        AeonM1LandBase:AddBuildGroup('M1_LandBaseSupportFactories', 100, true)
    end)
	
    AeonM1LandBaseAttacks()
end

function AeonM1LandBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {5,10,15}
    opai = AeonM1LandBase:AddOpAI('BasicLandAttack', 'M1_SouthLandAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AmphibiousAttack_Aeon'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

    quantity = {5,10,15}
    opai = AeonM1LandBase:AddOpAI('BasicLandAttack', 'M1_SouthLandAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AmphibiousAttack_Aeon'},
            },
            Priority = 110,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

	quantity = {5,10,15}
     opai = AeonM1LandBase:AddOpAI('BasicLandAttack', 'M1_SouthLandAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AmphibiousAttack_Aeon'},
            },
            Priority = 120,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {5,10,15}
     opai = AeonM1LandBase:AddOpAI('BasicLandAttack', 'M1_SouthLandAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AmphibiousAttack_Aeon'},
            },
            Priority = 130,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')


end
