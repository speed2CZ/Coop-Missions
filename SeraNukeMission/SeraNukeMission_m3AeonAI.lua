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
--local AeonM1AirBase = BaseManager.CreateBaseManager()

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

