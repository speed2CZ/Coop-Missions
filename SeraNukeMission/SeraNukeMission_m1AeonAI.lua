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
        WaitSeconds(100 - 30*Difficulty)
        AeonM1AirBase:AddBuildGroup('M1AeonAirBase', 90)
    end)

    M1AeonAirBaseAttacks()
end

function M1AeonAirBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {6, 10, 15}
    opai = AeonM1AirBase:AddOpAI('AirAttacks', 'M1_NorthAirAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon',
                                'M1_AttackFleet_UEF'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity('Gunships', quantity[Difficulty])
    opai:SetLockingStyle('None')

    quantity = {2, 3, 4}
    trigger = {11, 8, 5}
    opai = AeonM1AirBase:AddOpAI('AirAttacks', 'M1_NorthAirAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon',
                                'M1_AttackFleet_UEF'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity('HeavyGunships', quantity[Difficulty])
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.AIR * categories.MOBILE})
end


--------------------
-- Aeon M1 Land Base
--------------------
function AeonM1LandBaseAI()
    AeonM1LandBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M1_South_Base', 'M1AeonLandBaseMarker', 35, {M1_LandBase_1 = 100})
    AeonM1LandBase:StartNonZeroBase({{3, 3, 4}, {2, 2, 3}})

	AeonM1LandBase:SetActive('LandScouting', true)
	
	ForkThread(function()
        WaitSeconds(100 - 30*Difficulty)
        AeonM1AirBase:AddBuildGroup('M1AeonAirBase', 90)
    end)
	
    AeonM1LandBaseAttacks()
end

function AeonM1LandBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {20, 30, 40}
    trigger = {41, 33, 25}
    opai = AeonM1LandBase:AddOpAI('BasicLandAttack', 'M1_SouthLandAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.ALLUNITS - categories.WALL})

    quantity = {20, 30, 40}
    trigger = {60, 50, 40}
    opai = AeonM1LandBase:AddOpAI('BasicLandAttack', 'M1_SouthLandAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_AirRaid_Aeon'},
            },
            Priority = 110,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.ALLUNITS - categories.WALL})

    quantity = {6, 6, 8}
    trigger = {36, 28, 22}

end
