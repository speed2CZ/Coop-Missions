local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

local UEFNavyBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M2NavyBaseFunction()
	UEFNavyBase:Initialize(ArmyBrains[UEF], 'M2_Navy_Base_1', 'M2_Navy_Base_Marker', 200, {M2_Navy_Base_1 = 100})

	UEFNavyBase:StartNonZeroBase({20, 5})
	UEFNavyBase:SetActive('AirScouting', true)

    EnableLandAttacks()
    EnableAirAttacks()
    EnableNavyAttacks()
    EnableTransportAttacks()
end

function EnableLandAttacks()
	local opai = nil
	local trigger = {}

	quantity = {3, 4, 5}
	opai = UEFNavyBase:AddOpAI('BasicLandAttack', 'M2_BasicHoverAttack_1',
		{
	      	MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
	      	PlatoonData = {
	          PatrolChain = 'M1_Attack_Chain_2',
	      	},
	    	Priority = 140,
		}
	)
	opai:SetChildQuantity('AmphibiousTanks', quantity[Difficulty])
end

function EnableAirAttacks()
	-- Attack Player Economy
	  quantity = {3, 4, 5}
	  opai = UEFNavyBase:AddOpAI('AirAttacks', 'M2_AirAttack_Economy',
	    {
	      MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
	      PlatoonData = {
	        CategoryList = { categories.MASSEXTRACTION },
	      },
	      Priority = 150,
	      }
	  )
	  opai:SetChildQuantity('Gunships', quantity[Difficulty])
	  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
	  {'default_brain', 'Player', 1, categories.MASSEXTRACTION })
end


function EnableNavyAttacks()
    local opai = nil
	local trigger = {}

	-- Send a patrol to stop player's navy progress
    opai = UEFNavyBase:AddNavalAI('M2_GuardCoast',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
           		PatrolChain = 'M2_Navy_Patrol_Player_Navy',
            },
            Overrides = {
                CORE_TO_SUBS = 1,
            },
            MaxFrigates = 3,
            MinFrigates = 3,
            Priority = 300,
        }
    )
    opai:SetChildActive('T2', false)
    opai:SetChildActive('T3', false)

    -- If Player has a naval factory...
    opai = UEFNavyBase:AddNavalAI('M2_NavyAttack_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
           		PatrolChain = 'M2_Navy_Patrol_Player_Navy',
            },
            DisableTypes = {['Submarine'] = true},
            MaxFrigates = 5,
            MinFrigates = 5,
            Priority = 300,
        }
    )
    opai:SetChildActive('T2', false)
    opai:SetChildActive('T3', false)
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua',
        'BrainGreaterThanOrEqualNumCategory', {'default_brain', 'Player', 1, categories.NAVAL * categories.FACTORY})

end

function EnableTransportAttacks()
    local opai = nil
	local trigger = {}

    -- Transport Builder
    opai = UEFNavyBase:AddOpAI('EngineerAttack', 'M2_Navy_TransportBuilder',
    {
        MasterPlatoonFunction = {SPAIFileName, 'LandAssaultWithTransports'},
        PlatoonData = {
            AttackChain = 'M1_Attack_Chain_2',
            LandingChain = 'M2_UEFTransDrop_Chain',
            TransportReturn = 'M2_Navy_Base_Marker',
        },
        Priority = 1000,
    })
    opai:SetChildActive('All', false)
    opai:SetChildActive('T2Transports', true)
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {'default_brain', 3, categories.uea0104})

    -- Drops
    for i = 1, 3 do
        opai = UEFNavyBase:AddOpAI('BasicLandAttack', 'M2_UEFLandAttack1' .. i,
        {
            MasterPlatoonFunction = {SPAIFileName, 'LandAssaultWithTransports'},
            PlatoonData = {
                AttackChain = 'M1_Attack_Chain_2',
                LandingChain = 'M2_UEFTransDrop_Chain',
                TransportReturn = 'M2_Navy_Base_Marker',
            },
            Priority = 110,
        })
        opai:SetChildQuantity('LightTanks', 6)
        opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
            'HaveGreaterThanUnitsWithCategory', {'default_brain', 1, categories.uea0104})
    end

    -- T2 Drops
end

------------------
-- Land Factories
------------------

function DisableBase()
    if(UEFNavyBase) then
        UEFNavyBase:BaseActive(false)
    end
end