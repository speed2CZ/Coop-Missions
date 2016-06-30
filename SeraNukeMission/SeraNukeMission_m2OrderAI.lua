local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

---------
-- Locals
---------
local Order = 3
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local OrderBase = BaseManager.CreateBaseManager()

---------------------
---Order M2 Base
---------------------

function OrderBaseAI()
    OrderBase:InitializeDifficultyTables(ArmyBrains[Order], 'OrderBase', 'M2_OrderBase', 150, {M2_OrderBase = 150})
    OrderBase:StartNonZeroBase({{9, 8, 7}, {1, 1, 1}})
    OrderBase:SetActive('LandScouting', true)
    OrderBase:SetActive('AirScouting', true)

	
	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        OrderBase:AddBuildGroup('OrderSupportFactories', 200, true)
    end)

    OrderBaseDefensePatrols()
end

function OrderBaseDefensePatrols()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {12, 10, 8}
    opai = OrderBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',
                                'M2_OrderLandPatrol1',
								'M2_OrderLandPatrol2'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyTanks', 'LightTanks'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {12, 10, 8}
    opai = OrderBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',
                                'M2_OrderLandPatrol1',
								'M2_OrderLandPatrol2'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {10, 8, 6}
    opai = OrderBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',
                                'M2_OrderLandPatrol1',
								'M2_OrderLandPatrol2'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'MobileFlak', 'HeavyBots'}, quantity[Difficulty])
    opai:SetLockingStyle('None')

	quantity = {10, 8, 6}
    opai = OrderBase:AddOpAI('BasicLandAttack', 'M2_LandPatrol14',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',
                                'M2_OrderLandPatrol1',
								'M2_OrderLandPatrol2'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'LightTanks', 'AmphibiousTanks', 'MobileFlak'}, quantity[Difficulty])
    opai:SetLockingStyle('None')
	
	quantity = {12, 10, 8}


  
	--Defense Air Patrol
    quantity = {10, 9, 8}
    opai = OrderBase:AddOpAI('AirAttacks', 'M2_AirPatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'CombatFighters', 'Gunships'}, quantity[Difficulty])

		--Defense Air Patrol
	quantity = {8, 7, 6}
    opai = OrderBase:AddOpAI('AirAttacks', 'M2_AirPatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'HeavyGunships'}, quantity[Difficulty])
	
		--Defense Air Patrol
    quantity = {10, 9, 8}
    opai = OrderBase:AddOpAI('AirAttacks', 'M2_AirPatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M2_OrderAirPatrol',},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'CombatFighters', 'Gunships'}, quantity[Difficulty])

    # sends 12 frigate power 
    opai = OrderBase:AddNavalAI('M2_NavalDefensePatrol1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_UEFFleetAttackChain',
            },
            MaxFrigates = 15,
            MinFrigates = 15,
            Priority = 130,
        }
    )
    opai:SetChildActive('T3', false)	
	
	# sends 17 frigate power 
    opai = OrderBase:AddNavalAI('M2_NavalDefensePatrol2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_AeonFleetAttackChain',
							  'M2_UEFFleetAttackChain',
            },
            MaxFrigates = 17,
            MinFrigates = 17,
            Priority = 130,
        }
    )
    opai:SetChildActive('T3', false)
	
	
	# sends 25 frigate power 
    opai = OrderBase:AddNavalAI('M2_NavalDefensePatrol3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
            PlatoonData = {
                PatrolChain = 'M2_AeonFleetAttackChain',
							  'M2_UEFFleetAttackChain',
            },
            MaxFrigates = 25,
            MinFrigates = 25,
            Priority = 100,
        }
    )
    opai:SetChildActive('T3', true)

end

