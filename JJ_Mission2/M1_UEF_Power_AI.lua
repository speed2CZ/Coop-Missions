local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = import('/lua/scenarioplatoonai.lua')

local UEFPowerBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M1UEFPowerAIFunction()
	UEFPowerBase:Initialize(ArmyBrains[UEF], 'M1_Base', 'M1_UEF_Power_Base_Marker', 100, {M1_Base = 100})

	UEFPowerBase:StartNonZeroBase({20, 5})
	UEFPowerBase:SetActive('AirScouting', true)
    UEFPowerBase:SetActive('LandScouting', true)
    UEFPowerBase:SetBuild('Defenses', true)

    UEFM1PowerBaseAirAttacks()
end

function UEFM1PowerBaseAirAttacks()
	local opai = nil
    quantity = {4, 5, 6}
    trigger = {40, 34, 25}

   opai = UEFPowerBase:AddOpAI('AirAttacks', 'M1_PowerBaseAirAttack1',
       {
           MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
           PlatoonData = {
               PatrolChain = 'M1_Attack_Chain_2'
           },
           Priority = 150,
       }
   )
    opai:SetChildQuantity('Bombers', quantity[Difficulty])
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
        {'default_brain', 'Player', trigger[Difficulty], categories.LAND * categories.MOBILE})
end