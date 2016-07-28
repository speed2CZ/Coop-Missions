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

    EnableAirAttacks()
    EnableNavyAttacks()
    EnableTransportAttacks()
end

function EnableAirAttacks()

end


function EnableNavyAttacks()

end

function EnableTransportAttacks()
    -- Transport Builder
    opai = UEFNavyBase:AddOpAI('EngineerAttack', 'M2_UEF_TransportBuilder',
    {
        MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'LandAssaultWithTransports'},
        PlatoonData = {
            TransportReturn = 'M2_Navy_Base_Marker',
        },
        Priority = 1000,
    })
    opai:SetChildQuantity('T2Transports', 3)
    opai:SetLockingStyle('None')
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {'default_brain', 5, categories.uea0104})
end