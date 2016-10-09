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
local AeonM4AirBase = BaseManager.CreateBaseManager()
local AeonM4NavalBase = BaseManager.CreateBaseManager()
local AeonM4SalvationBase = BaseManager.CreateBaseManager()

function AeonM4AirBaseAI()
    AeonM4AirBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M4AeonAirBase', 'M4_AeonAirBase', 35, {M4_AirBase = 100})
    AeonM4AirBase:StartNonZeroBase({{3, 3, 3}, {1, 1, 1}})
    --AeonM1AirBase:SetActive('LandScouting', true)
    --AeonM3AirBase:SetActive('AirScouting', true)


	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        AeonM4AirBase:AddBuildGroup('M4_AirBaseSupportFactories', 100, true)
    end)
	
    M4AeonAirBaseAttacks()
end

function M4AeonAirBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {12, 16, 20}
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraOss',
								'M1_YolonaOss',},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity('Gunships', quantity[Difficulty])
    opai:SetLockingStyle('None')

    quantity = {8, 12, 16}
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraOss',
								'M1_YolonaOss',},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity('HeavyGunships', quantity[Difficulty])
	
	quantity = {10, 15, 20} --difficulty
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraOss',
								'M1_YolonaOss',},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity({'Bombers', 'HeavyGunships', 'AirSuperiority'}, quantity[Difficulty])
	
	quantity = {10, 15, 20} --difficulty
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraOss',
								'M1_YolonaOss',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Bombers', 'HeavyGunships', 'AirSuperiority'}, quantity[Difficulty])


end

function AeonM4NavalBaseAI()
    AeonM4NavalBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M4AeonNavalBase', 'M4_AeonNavalBase', 35, {M4_NavalBase = 100})
    AeonM4NavalBase:StartNonZeroBase({{5, 5, 5}, {1, 1, 1}})
    --AeonM1AirBase:SetActive('LandScouting', true)
    --AeonM3AirBase:SetActive('AirScouting', true)


	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        AeonM4NavalBase:AddBuildGroup('M4_NavalBaseSupportFactories', 100, true)
    end)
	
    M4AeonNavalBaseAttacks()
end

function M4AeonNavalBaseAttacks()

end

function AeonM4SalvationBaseAI()
    AeonM4SalvationBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M4AeonSalvationBase', 'M4_AeonSalvationBase', 35, {M4_SalvationBase = 100})
    AeonM4SalvationBase:StartNonZeroBase({{5, 5, 5}, {1, 1, 1}})
    --AeonM1AirBase:SetActive('LandScouting', true)
    --AeonM3AirBase:SetActive('AirScouting', true)


	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        AeonM4NavalBase:AddBuildGroup('M4_Salvation', 100, true)
    end)
	
    M4AeonSalvationBaseDefensePatrols()
end

function  M4AeonSalvationBaseDefensePatrols()

end


