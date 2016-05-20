--[[
Don't edit or remove this comment block! It is used by the editor to store information since i'm too lazy to write a good LUA parser... -Haz
SETTINGS
RestrictedEnhancements=
RestrictedCategories=
END
--]]

local BaseManager = import('/lua/ai/opai/basemanager.lua')
local Buff = import('/lua/sim/Buff.lua')
local Cinematics = import('/lua/cinematics.lua')
local EffectUtilities = import('/lua/effectutilities.lua')
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local TauntManager = import('/lua/TauntManager.lua')
local OpStrings = import('/maps/JJ_Training/JJ_Training_strings.lua')
local JJAI = import('/maps/JJ_Training/JJ_AI.lua')

# -------
# Globals
# -------
ScenarioInfo.Player = 2
ScenarioInfo.ObjComplete = 0

# Army IDs
local Player = ScenarioInfo.Player
local JJ = 1
local Enemy = 3

# -------
# Other Scenario Functions
# -------
function PlayerLose()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = false
# player destroyed
        local unit = ScenarioInfo.PlayerCDR
        ScenarioFramework.CDRDeathNISCamera( unit )
        
    end
end

function PlayerWin()
    ForkThread(function()
        if(not ScenarioInfo.OpEnded) then
            ScenarioFramework.Dialogue(Strings.EndGameComplete, KillGame)
        end
    end)
end

function KillGame()
    ForkThread(
        function()
            WaitSeconds(2)
            ScenarioFramework.EndOperationSafety()
            local endDialog = import('/lua/SimDialogue.lua').Create(LOC("<LOC X1TU_0000>Congratulations, Colonel. Training exercise completed."), {LOC("<LOC _OK>")})
            endDialog.OnButtonPressed = function(self, info)
                ScenarioFramework.ExitGame()
            end
        end
    )
end

function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()
    #Weather.CreateWeather()
end

function OnStart(self)
    for i = 3, table.getn(ArmyBrains) do
        SetIgnorePlayableRect(i, true)
        SetArmyShowScore(i, false)
    end

    ScenarioFramework.StartOperationJessZoom('TUT_PAN', TutorialMissionSetup)
end

function TutorialMissionSetup()
    ScenarioInfo.MissionNumber = 0
    
	# restrict zooming
    ChangeCameraZoom(.5)

	SpawnCommanders()
end

function SpawnCommanders()
	ScenarioInfo.PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'Commander')
    ScenarioInfo.PlayerCDR:PlayCommanderWarpInEffect()
    ScenarioInfo.PlayerCDR:SetCustomName(LOC '{i CDR_Player}')
    ScenarioFramework.PauseUnitDeath(ScenarioInfo.PlayerCDR)
    ScenarioFramework.CreateUnitDeathTrigger(PlayerLose, ScenarioInfo.PlayerCDR)
    ScenarioInfo.PlayerCDR:SetCanTakeDamage(false)
    ScenarioInfo.PlayerCDR:SetCanBeKilled(false)
	
	ScenarioInfo.JJ = ScenarioUtils.CreateArmyUnit('JJ', 'Ally')
    ScenarioInfo.JJ:PlayCommanderWarpInEffect()
    ScenarioInfo.JJ:SetCustomName('Colonel JJ')
    ScenarioInfo.JJ:SetCanTakeDamage(false)
    ScenarioInfo.JJ:SetCanBeKilled(false)
	
	ScenarioFramework.Dialogue(OpStrings.intro1, TutorialBuildLandFactory)
	
end

function TutorialBuildLandFactory()
	ScenarioInfo.MissionNumber = 1 
	ScenarioFramework.Dialogue(OpStrings.OB1, TutorialBuildLandFactory_Main)
	JJAI.JJMainBaseAI()
end

function TutorialBuildLandFactory_Main()
    ScenarioInfo.OBJ1 = Objectives.CategoriesInArea(
        'primary',
        'incomplete', 
        OpStrings.OBJ1A,          # title
        OpStrings.OBJ1B,    # description
        'Build',                                # action
        {
			MarkArea = true,
            MarkUnits = false,
            ShowFaction = 'UEF',
            Requirements =
            {
                {Area = 'FACTORY', Category = categories.FACTORY, CompareOp = '>=', Value = 1, ArmyIndex = Player},
            },
        }
    )
	
    ScenarioInfo.OBJ1:AddResultCallback(
        function()
            ScenarioFramework.Dialogue(OpStrings.BuildLandFactoryComplete, BuildPower)
        end
    )
end

function BuildPower()
	ScenarioInfo.MissionNumber = 2
	BuildPowerMain()
end

function BuildPowerMain() 
	ScenarioInfo.OBJ2 = Objectives.CategoriesInArea(
		'primary',
		'incomplete',
		OpStrings.OBJ2A,
		OpStrings.OBJ2B,
		'Build',
		{
            MarkUnits = false,
            MarkArea = true,
            ShowFaction = 'UEF',
            Requirements =
            {
                {Area = 'POWER1', Category = categories.POWERGENERATOR, CompareOp = '>=', Value = 1, ArmyIndex = Player},
				{Area = 'POWER2', Category = categories.POWERGENERATOR, CompareOp = '>=', Value = 2, ArmyIndex = Player}, 
            },
		}
	)
	
	ScenarioInfo.OBJ2:AddResultCallback(
        function()
            ScenarioFramework.Dialogue(OpStrings.BuildPowerComplete, BuildMorePower)
        end
    )
end

function BuildMorePower()
	ScenarioInfo.MissionNumber = 3
	ScenarioFramework.Dialogue(OpStrings.BuildMorePower, BuildMorePowerMain)
end

function BuildMorePowerMain()
	ScenarioInfo.OBJ3 = Objectives.CategoriesInArea(
		'primary',
		'incomplete',
		OpStrings.OBJ3A,
		OpStrings.OBJ3B,
		'Build',
		{
            MarkUnits = false,
            MarkArea = true,
            ShowFaction = 'UEF',
            Requirements =
            {
                {Area = 'POWER3', Category = categories.POWERGENERATOR, CompareOp = '>=', Value = 1, ArmyIndex = Player},
            },
		}
	)
	
	ScenarioInfo.OBJ3:AddResultCallback(
        function()
            ScenarioFramework.Dialogue(OpStrings.BuildMorePowerComplete, nil, true)
			ScenarioInfo.ObjComplete = ScenarioInfo.ObjComplete + 1
        end
    )
	
	ScenarioInfo.OBJ4 = Objectives.ArmyStatCompare(
        'primary',                    # type
        'incomplete',                   # status
        OpStrings.OBJ4A,  # title
        OpStrings.OBJ4B,  # description
        'Build',
        {                               # target
            Army = Player,
            StatName = 'Units_Active',
            CompareOp = '>=',
            Value = 4,
            Category = categories.uel0105 * categories.TECH1,
            ShowProgress = true,
        }
    )
	
	ScenarioInfo.OBJ4:AddResultCallback(
        function()
            ScenarioFramework.Dialogue(OpStrings.BuildEngineersComplete, nil, true)
			ScenarioInfo.ObjComplete = ScenarioInfo.ObjComplete + 1
        end
    )
	
	if ScenarioInfo.ObjComplete >= 2 then
		ScenarioFramework.Dialogue(OpStrings.EngineersAndPowerDone, BuildMassExtractors)
	end
end

function BuildMassExtractors()

end







