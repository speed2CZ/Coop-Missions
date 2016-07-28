local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

local UEFPowerBase = BaseManager.CreateBaseManager()

local Difficulty = ScenarioInfo.Options.Difficulty

local UEF = 2

function M1UEFPowerAIFunction()
	UEFPowerBase:Initialize(ArmyBrains[UEF], 'M1_Base', 'M1_UEF_Power_Base_Marker', 100, {M1_Base = 100})

	UEFPowerBase:StartNonZeroBase({10, 5})
	UEFPowerBase:SetActive('AirScouting', true)
  UEFPowerBase:SetActive('LandScouting', true)
  UEFPowerBase:SetBuild('Defenses', true)

  UEFM1PowerBaseAirAttacks()
  UEFM1PowerBaseLandAttacks()
  UEFRebuildPatrols()
end

function UEFM1PowerBaseAirAttacks()
	local opai = nil
  quantity = {4, 5, 6}
  trigger = {40, 32, 25}

  -- Initial Bomber Attacks

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

  -- Counter that enemy air with interceptors!

  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', trigger[Difficulty], categories.LAND * categories.MOBILE})

  quantity = {6, 8, 10}
  opai = UEFPowerBase:AddOpAI('AirAttacks', 'M1_PowerBaseAirAttack2',
    {
      MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
      PlatoonData = {
          PatrolChain = 'M1_Attack_Chain_2'
      },
      Priority = 140,
      }
  )
  opai:SetChildQuantity('Interceptors', quantity[Difficulty])
  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', 1, categories.AIR * categories.FACTORY})

  -- If Player has a Tech 2 Air Factory, we should attack with Gunships!
  quantity = {4, 5, 6}
  opai = UEFPowerBase:AddOpAI('AirAttacks', 'M1_PowerBaseAirAttack3',
    {
      MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
      PlatoonData = {
          PatrolChain = 'M1_Attack_Chain_2'
      },
      Priority = 140,
      }
  )
  opai:SetChildQuantity('Gunships', quantity[Difficulty])
  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', 1, categories.AIR * categories.FACTORY * categories.TECH2})

  -- If Player decided to build Navy, I will use Torpedo Bombers.
  quantity = {5, 7, 9}
  opai = UEFPowerBase:AddOpAI('AirAttacks', 'M1_PowerBaseAirAttack4',
    {
      MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
      PlatoonData = {
        CategoryList = { categories.NAVAL * categories.FACTORY },
      },
      Priority = 150,
      }
  )
  opai:SetChildQuantity('TorpedoBombers', quantity[Difficulty])
  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', 1, categories.NAVAL * categories.FACTORY})
end

function UEFM1PowerBaseLandAttacks()
    local opai = nil
    quantity = {4, 5, 6}
    opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M1_Attack_Chain_2'
            },
            Priority = 150,
        }
    )
    opai:SetChildQuantity('LightTanks', quantity[Difficulty])

    -- Initial Economy Attack.

    quantity = {2, 3, 4}
    opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M1_Attack_Chain_3'
            },
            Priority = 145,
        }
    )
    opai:SetChildQuantity('LightArtillery', quantity[Difficulty])

    -- Player has 6 Light Tanks? I'll counter it with more!

    quantity = {8, 10, 12}
    opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M1_Attack_Chain_2'
            },
            Priority = 140,
        }
    )
    opai:SetChildQuantity('LightTanks', quantity[Difficulty])
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
    {'default_brain', 'Player', 6, categories.uel0201})

    -- Let's hurt their economy. Our Enemy has 6 T1 Mex's. Let's stop that.

    quantity = {2, 4, 6}
    opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M1_Attack_Chain_1'
            },
            Priority = 135,
        }
    )
    opai:SetChildQuantity('LightBots', quantity[Difficulty])
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
    {'default_brain', 'Player', 6, categories.ueb1103})

    -- Player has T1 PD, I want to counter that with artillery.

    quantity = {4, 6, 8}
    opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack5',
        {
            MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
            PlatoonData = {
                CategoryList = { categories.ueb2101 },
            },
            Priority = 130,
        }
    )
    opai:SetChildQuantity('LightArtillery', quantity[Difficulty])
    opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
    {'default_brain', 'Player', 1, categories.ueb2101})

    -- Builds Platoon of 4 Engineers

    opai = UEFPowerBase:AddOpAI('EngineerAttack', 'M1_Power_Reclaim_Engineers',
      {
          MasterPlatoonFunction = {SPAIFileName, 'SplitPatrolThread'},
          PlatoonData = {
             PatrolChains = {'M1_Attack_Chain_2'},
          },
          Priority = 150,
      }
    )
    opai:SetChildQuantity('T1Engineers', 4)

    -- Let's move on to T2.

    quantity = {4, 5, 6}
    opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack6',
      {
        MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
        PlatoonData = {
            PatrolChain = 'M1_Attack_Chain_2'
        },
        Priority = 120,
      }
  )
  opai:SetChildQuantity('HeavyTanks', quantity[Difficulty])
  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', 1, categories.LAND * categories.FACTORY * categories.TECH2})

  -- Play has Tech 2 PD, we should counter it.

  quantity = {2, 3, 4}
  opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_LandAttack7',
    {
      MasterPlatoonFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
        PlatoonData = {
          CategoryList = { categories.ueb2301 },
        },
      Priority = 150,
    }
  )
  opai:SetChildQuantity('MobileMissiles', quantity[Difficulty])
  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', 1, categories.ueb2301})
end

function UEFRebuildPatrols()
  local opai = nil
  quantity = {5, 6, 7}
  opai = UEFPowerBase:AddOpAI('BasicLandAttack', 'M1_T3PatrolGroup',
    {
      MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
      PlatoonData = {
          PatrolChains = {'M1_Maintain_Patrol_1', 'M1_Maintain_Patrol_2'},
      },
      Priority = 150,
    }
  )
  opai:SetChildQuantity('SiegeBots', quantity[Difficulty])
  opai:AddBuildCondition('/lua/editor/otherarmyunitcountbuildconditions.lua', 'BrainGreaterThanOrEqualNumCategory',
  {'default_brain', 'Player', 1, categories.LAND * categories.FACTORY * categories.TECH3})

  quantity = {4, 6, 8}
  opai = UEFPowerBase:AddOpAI('AirAttacks', 'M1_T2GunshipPatrol',
    {
      MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
      PlatoonData = {
          PatrolChains = {'M1_Maintain_Patrol_1', 'M1_Maintain_Patrol_2'},
      },
      Priority = 150,
    }
  )
  opai:SetChildQuantity('Gunships', quantity[Difficulty])
end