local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = import('/lua/scenarioplatoonai.lua')

local UEFNavyBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M2NavyBaseFunction()
	UEFNavyBase:Initialize(ArmyBrains[UEF], 'M2_Navy_Base_1', 'M2_Navy_Base_Marker', 100, {M2_Navy_Base_1 = 100})

	UEFNavyBase:StartNonZeroBase({20, 5})
	UEFNavyBase:SetActive('AirScouting', true)
    UEFNavyBase:SetActive('LandScouting', false)
    UEFNavyBase:SetBuild('Defenses', true)
end