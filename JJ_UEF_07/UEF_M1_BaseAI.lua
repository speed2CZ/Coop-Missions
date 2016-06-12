local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = import('/lua/scenarioplatoonai.lua')

local UEFM1Base = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function UEFM1BaseFunction(Army)

	UEFM1Base:Initialize(ArmyBrains[Army], 'M1_Base', 'UEF_M1_Base', 250,
		{
			LandFac_1 = 1000,
			Gens_1 = 990,
			Mex_1 = 980,
			Gens_2 = 970,
			LandFac_2 = 960,
			Mex_2 = 950,
			Hydro = 940,
			Radar = 930,
			AirFac_1 = 920,
			Mex_3 = 910, 
		} 
	)

	UEFM1Base:StartEmptyBase({15, 7})
	UEFM1Base:SetActive('AirScouting', true)
    UEFM1Base:SetActive('LandScouting', false)
    UEFM1Base:SetBuild('Defenses', true)
end