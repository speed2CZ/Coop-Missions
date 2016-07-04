local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/scenarioplatoonai.lua'

---------
-- Locals
---------
local Aeon = 5
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local AeonM3AirBase = BaseManager.CreateBaseManager()

--CZAR construction and attacks
function CZARFactory()
	ArmyBrains[Aeon]:PBMAddBuildLocation('M1_AeonAirBase', 150, 'AeonCZAR')
	local Carrier = ScenarioInfo.M3AeonCZAR
	local location
    --for num, loc in ArmyBrains[Aeon].PBM.Locations do
     --   if loc.LocationType == 'AeonCZAR' then
     --       location = loc
            AeonCZARAttacks()
     --       break
     --   end
    --end
	
	while (Carrier and not Carrier:IsDead()) do
        if  table.getn(Carrier:GetCargo()) > 0 and Carrier:IsIdleState() then
            IssueClearCommands({Carrier})
            IssueTransportUnload({Carrier}, Carrier:GetPosition())
        end
        WaitSeconds(1)
    end	
	
end

function AeonM3AirBaseAI()
    AeonM3AirBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M3AeonAirBase', 'M3_AeonAirBase', 35, {M3_AirBase = 100})
    AeonM3AirBase:StartNonZeroBase({{3, 3, 3}, {1, 1, 1}})
    --AeonM1AirBase:SetActive('LandScouting', true)
    --AeonM3AirBase:SetActive('AirScouting', true)


	ForkThread(function()
        -- Spawn support factories bit later, since sometimes they can't build anything
        WaitSeconds(1)
        AeonM3AirBase:AddBuildGroup('M3_AirBaseSupportFactories', 100, true)
    end)
	
    M3AeonAirBaseAttacks()
end

function M3AeonAirBaseAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    quantity = {12, 16, 20}
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase',
								'M1_YolonaOss'},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity('Gunships', quantity[Difficulty])
    opai:SetLockingStyle('None')

    quantity = {8, 12, 16}
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase',
								'M1_YolonaOss'},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity('HeavyGunships', quantity[Difficulty])
	
	quantity = {10, 15, 20} --difficulty
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase',
								'M1_YolonaOss'},
        },
		Priority = 100,
		}
    )
    opai:SetChildQuantity({'Bombers', 'HeavyGunships', 'AirSuperiority'}, quantity[Difficulty])
	
	quantity = {10, 15, 20} --difficulty
    opai = AeonM3AirBase:AddOpAI('AirAttacks', 'M3_NorthAirAttack4',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = {'M1_SeraphimBase',
								'M1_YolonaOss'},
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity({'Bombers', 'HeavyGunships', 'AirSuperiority'}, quantity[Difficulty])


end


-- Platoons built by CZAR
function AeonCZARAttacks()
	local torpBomberNum = {6, 8, 10}
    local swiftWindNum = {6, 8, 10}
    local gunshipNum = {6, 8, 10}

    local Temp = {
        'M3AeonCZARAttack',
        'NoPlan',
        { 'uaa0204', 1, torpBomberNum[Difficulty], 'Attack', 'AttackFormation' }, -- T2 Torp Bomber
        { 'xaa0202', 1, swiftWindNum[Difficulty], 'Attack', 'AttackFormation' }, -- Swift Wind
        { 'uaa0203', 1, gunshipNum[Difficulty], 'Attack', 'AttackFormation' }, -- T2 Gunship
        { 'uaa0101', 1, 3, 'Attack', 'AttackFormation' }, -- T1 Scout
    }
    local Builder = {
        BuilderName = 'M3AeonCZARAttack1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 100,
        PlatoonType = 'Air',
        RequiresConstruction = true,
        LocationType = 'AeonCZAR',
        PlatoonAIFunction = {SPAIFileName, 'Patrol'},
        PlatoonData = {
            PatrolChain = 'M1_YolonaOss',
        },      
    }
    ArmyBrains[Aeon]:PBMAddPlatoon( Builder )

end

