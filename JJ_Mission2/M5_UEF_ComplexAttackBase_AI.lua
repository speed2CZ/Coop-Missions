local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = import('/lua/scenarioplatoonai.lua')

local UEFOffMapComplexBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M5ComplexAttackerFunction()
	UEFOffMapComplexBase:Initialize(ArmyBrains[UEF], 'M5_ComplexAttackers', 'M5_ComplextAttackBase_Marker', 100, {M5_ComplexAttackers = 100})

	UEFOffMapComplexBase:StartNonZeroBase({5, 3})
	UEFOffMapComplexBase:SetActive('AirScouting', true)
    UEFOffMapComplexBase:SetActive('LandScouting', false)
    UEFOffMapComplexBase:SetBuild('Defenses', true)
end