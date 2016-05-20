local BaseManager = import('/lua/ai/opai/basemanager.lua')

local SPAIFileName = '/lua/scenarioplatoonai.lua'

# ------
# Locals
# ------
local JJ = 1

# -------------
# Base Managers
# -------------
local JJMAINBASE = BaseManager.CreateBaseManager()


function JJMainBaseAI()
	JJMAINBASE:Initialize(ArmyBrains[JJ], 'JJ_Main_Base', 'JJ_Base_Marker', 40, {Buildings = 100})
	JJMAINBASE:StartEmptyBase({6, 2})
	JJMAINBASE:SetActive('AirScouting', true)
    JJMAINBASE:SetActive('LandScouting', false)
    JJMAINBASE:SetBuild('Defenses', true)

    JJMAINBASE:AddBuildGroup('JJ_Main_Base', 90, false)
end
