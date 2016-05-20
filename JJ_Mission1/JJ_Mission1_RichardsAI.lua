-- Richards AI for M3 specific, the player will have to assist me here.
-- Mainly base construction

local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

local UEF = 8

local RichardsMainBase = BaseManager.CreateBaseManager()

function RichardsM3AI(Army)

	RichardsMainBase:Initialize(ArmyBrains[Army], 'Base', 'M2_Rhiza_Base_Marker', 100,
		{
			FirstMex = 1000,
			FirstEco = 990,
			FirstFactories = 980,
			SecondEco = 970,
			SecondMex = 960,
			FirstDef = 950,
			ThirdEco = 940,
			QuantumGate = 930,
			LandFactories = 920,
			SecondDef = 910, 
		} 
	)

	RichardsMainBase:StartEmptyBase({50, 35})
	RichardsMainBase:SetActive('AirScouting', true)
    RichardsMainBase:SetActive('LandScouting', false)
    RichardsMainBase:SetBuild('Defenses', true)
end