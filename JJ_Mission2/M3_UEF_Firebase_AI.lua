local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = import('/lua/scenarioplatoonai.lua')

local UEFFireBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M3PrisonFireBaseFunction()
	UEFFireBase:Initialize(ArmyBrains[UEF], 'PrisonBase', 'M3_Firebase_Marker', 40, {PrisonBase = 40})

	UEFFireBase:StartNonZeroBase({20, 5})
	UEFFireBase:SetActive('AirScouting', true)
    UEFFireBase:SetActive('LandScouting', false)
    UEFFireBase:SetBuild('Defenses', true)
end