local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = import('/lua/scenarioplatoonai.lua')

local UEFMainBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M5UEFMainBaseFunction()
	UEFMainBase:Initialize(ArmyBrains[UEF], 'M5_Base', 'M5_UEF_Base', 300, {M5_Base = 100})

	UEFMainBase:StartNonZeroBase({20, 10})
	UEFMainBase:SetActive('AirScouting', true)
    UEFMainBase:SetActive('LandScouting', false)
    UEFMainBase:SetBuild('Defenses', true)
end