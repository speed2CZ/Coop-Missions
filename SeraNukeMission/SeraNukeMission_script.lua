-- ****************************************************************************
-- **
-- **  File     : /maps/SeraNukeMission/SeraNukeMission_script.lua
-- **  Author(s): FunkOff
-- **
-- **  Summary  : Main mission flow script for SeraNukeMission
-- **
-- ****************************************************************************
local Cinematics = import('/lua/cinematics.lua')
#local CustomFunctions = import('/maps/SeraNukeMission/SeraNukeMission_CustomFunctions.lua') --> make
local M1AeonAI = import('/maps/SeraNukeMission/SeraNukeMission_m1AeonAI.lua')  
local M1SeraAI = import('/maps/SeraNukeMission/SeraNukeMission_m1SeraAI.lua')  
local M2OrderAI = import('/maps/SeraNukeMission/SeraNukeMission_m2OrderAI.lua')  
local M2CybranAI = import('/maps/SeraNukeMission/SeraNukeMission_m2CybranAI.lua') 
local M2UEFAI = import('/maps/SeraNukeMission/SeraNukeMission_m2UEFAI.lua') 
#local M2CybranAI = import('/maps/SeraNukeMission/SeraNukeMission_m2CybranAI.lua')  --> make
#local M3AeonAI = import('/maps/SeraNukeMission/SeraNukeMission_m3aeonai.lua')  --> make
#local M3CybranAI = import('/maps/SeraNukeMission/SeraNukeMission_m3cybranai.lua')  --> make
#local M3UEFAI = import('/maps/SeraNukeMission/SeraNukeMission_m3uefai.lua')  --> make
local Objectives = import('/lua/ScenarioFramework.lua').Objectives
#local OpStrings = import('/maps/SeraNukeMission/SeraNukeMission_strings.lua')  --> make
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/Utilities.lua')

---------
-- Globals
---------
ScenarioInfo.Player = 1
ScenarioInfo.Seraphim = 2
ScenarioInfo.Order = 3
ScenarioInfo.UEF = 4
ScenarioInfo.Aeon = 5
ScenarioInfo.Cybran = 6
ScenarioInfo.Civilians = 7
ScenarioInfo.Coop1 = 8
ScenarioInfo.Coop2 = 9
ScenarioInfo.Coop3 = 10
ScenarioInfo.HumanPlayers = {} --Is this needed????

--------
-- Locals
--------
local Player = ScenarioInfo.Player
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3
local Aeon = ScenarioInfo.Aeon
local Cybran = ScenarioInfo.Cybran
local Order = ScenarioInfo.Order
local Seraphim = ScenarioInfo.Seraphim
local UEF = ScenarioInfo.UEF
local Civilians = ScenarioInfo.Civilians

local AssignedObjectives = {}
local Difficulty = ScenarioInfo.Options.Difficulty

-- How long should we wait at the beginning of the NIS to allow slower machines to catch up?
local NIS1InitialDelay = 3

--------------
-- Debug only!
--------------
local Debug = false
local SkipNIS1 = false
local SkipNIS2 = false
local SkipNIS3 = false
local SkipNIS4 = false


function OrderCommanderKilled()
	ArmyBrains[Order]:OnDefeat()
		--for i,v in ArmyBrains[Seraphim]:GetListOfUnits(categories.ALLUNITS, false) do
		--	v:Kill()
		--end
	return
end

function SeraphimCommanderKilled()
	ArmyBrains[Seraphim]:OnDefeat()
		--WaitSeconds(5)
		--for i,v in ArmyBrains[Seraphim]:GetListOfUnits(categories.ALLUNITS, false) do
		--	v:Kill()
		--end
	return
end
----------
-- Startup
----------
function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()

    -- Sets Army Colors
    --ScenarioFramework.SetSeraphimColor(Player)
    ScenarioFramework.SetSeraphimColor(Seraphim)
    ScenarioFramework.SetArmyColor(Player, 220, 200, 20)
	ScenarioFramework.SetAeonEvilColor(Order)
    ScenarioFramework.SetUEFPlayerColor(UEF)
    ScenarioFramework.SetAeonPlayerColor(Aeon)
    ScenarioFramework.SetCybranPlayerColor(Cybran)
    ScenarioFramework.SetUEFAlly2Color(Civilians)
    local colors = {
        ['Coop1'] = {255, 200, 0}, 
        ['Coop2'] = {189, 116, 16}, 
        ['Coop3'] = {89, 133, 39}
    }
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end

    -- Unit Cap
    --ScenarioFramework.SetSharedUnitCap(1000)

    -- Disable friendly AI sharing resources to players
    GetArmyBrain(Seraphim):SetResourceSharing(false)
	GetArmyBrain(Order):SetResourceSharing(false)
	
    ------------
    -- Aeon Air and Land Bases
    ------------

    M1AeonAI.AeonM1AirBaseAI() 
	M1AeonAI.AeonM1LandBaseAI() 
    ArmyBrains[Aeon]:PBMSetCheckInterval(5)
	local AeonM1SMD = ScenarioUtils.CreateArmyGroup('Aeon','M1_SMD')
	for i,SMD in AeonM1SMD do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	
	------------
    -- Seraphim Base
    ------------

	M1SeraAI.SeraphimBaseAI() 
	ArmyBrains[Seraphim]:PBMSetCheckInterval(6)
	
	------------
    -- Seraphim Defense Patrols
    ------------
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseForceSouth_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_SeraLandPatrolSouth')
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseForceEast_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_SeraLandPatrolEast')
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'DefenseFleet1_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.xss0201, platoon:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_SeraSeaPatrolSouth')
	

	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'DefenseFleet2_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.xss0201, platoon:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_SeraSeaPatrolWest')
	
	--ScenarioInfo.SeraphimCommander = ScenarioUtils.CreateArmyGroup('Seraphim', 'Commander')[1]
	ScenarioInfo.SeraphimCommander  = ScenarioFramework.SpawnCommander('Seraphim', 'Commander', false, 'Ithanyis', false, SeraphimCommanderKilled,
		{'BlastAttack','DamageStabilization','RateOfFire'})
	---So it doesnt wander away from the main base and get killed building T1 PD
	ScenarioInfo.SeraphimCommander:AddBuildRestriction( categories.SERAPHIM * ( categories.DEFENSE + categories.SHIELD) )
	
	
    -- Resources for Aeon AI, slightly delayed cause army didn't recieve it for some reason
    ForkThread(function()
        WaitSeconds(2)
        ArmyBrains[Aeon]:GiveStorage('ENERGY', 100000)
		ArmyBrains[Aeon]:GiveStorage('MASS', 20000)
        ArmyBrains[Aeon]:GiveResource('MASS', 20000)
        ArmyBrains[Aeon]:GiveResource('ENERGY', 100000)
    end)
	
	

    -- Walls
    #ScenarioUtils.CreateArmyGroup('UEF', 'M1_UEF_Walls')
    #ScenarioUtils.CreateArmyGroup('Civilians', 'Walls')
	
	
	------------
    -- Player Base and Fleet
    ------------
	local PlayerBase = ScenarioUtils.CreateArmyGroup('Player', 'Base')
	local DefenseFleet = ScenarioUtils.CreateArmyGroupAsPlatoon('Player', 'DefenseFleet','GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.xss0201, DefenseFleet:GetPlatoonUnits()) do
        IssueDive({v})
    end
	for k, v in EntityCategoryFilterDown(categories.xsb2401, PlayerBase) do
        ScenarioInfo.YolonaOss = v
    end
	

    ------------------
    -- Initial Attacks
    ------------------
    local platoon

	
	-- Aeon Air Raid
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_AirRaid_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_AirRaid_Aeon')
	
	--Aeon GC Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_GC_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_GC_Move')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
    
	-- UEF Fleet Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackFleet_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_AttackFleet_UEF1')
	
	--UEF Support base in M3 to provide power
	ScenarioUtils.CreateArmyGroup('UEF','M1_SupportBase')
	
	-- UEF Riptide Attack vs Player and vs Seraphim
	ForkThread(
		function()
			for i = 1, Difficulty do
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackPlayer_D' .. Difficulty, 'GrowthFormation')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
		
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackSera_D' .. Difficulty, 'GrowthFormation')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
				WaitSeconds(15)
			end
		end)


	
	--Cybran Spider Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_Experimentals_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
	
	--Cybran Wagners
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_WagnerAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M3_CybranAmphibiousMove')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
	
	#ScenarioFramework.CreatePlatoonDeathTrigger(M1SendTitans2, platoon)

    -- First objective area
    ScenarioFramework.SetPlayableArea('AREA_1', false)
end

function OnStart(self)
    --------------------
    -- Build Restrictions
    --------------------
    for _, player in ScenarioInfo.HumanPlayers do
        ScenarioFramework.AddRestriction(player,
            categories.xeb2306 + -- UEF Heavy Point Defense
            categories.xel0305 + -- UEF Percival
            categories.xel0306 + -- UEF Mobile Missile Platform
            categories.xes0102 + -- UEF Torpedo Boat
            categories.xes0205 + -- UEF Shield Boat
            categories.xes0307 + -- UEF Battlecruiser
            categories.xeb0104 + -- UEF Engineering Station 1
            categories.xeb0204 + -- UEF Engineering Station 2
            categories.xea0306 + -- UEF Heavy Air Transport
            categories.xeb2402 + -- UEF Sub-Orbital Defense System
			categories.xss0304 + -- Seraph T3 sub
            categories.xsl0401 + -- Seraph Exp Bot
            categories.xsa0402 + -- Seraph Exp Bomb
            categories.xsb0304 + -- Seraph Gate
            categories.xsl0301  -- Seraph sACU
        )
    end

    -- Initialize camera
    #if not SkipNIS1 then
    #    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Cam_1_1'))
    #end
    ForkThread(IntroMission1NIS)
end


------------
-- Mission 1
------------
function IntroMission1NIS()
    #if not SkipNIS1 then

    #else
        #DropReinforcements('Seraphim', 'Player', 'NIS_Bots_Player_D' .. Difficulty, 'NIS_Drop_Player', 'NIS_Transport_Death')
        ScenarioInfo.PlayerCDR = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true)

        -- spawn coop players too
        ScenarioInfo.CoopCDR = {}
        local tblArmy = ListArmies()
        coop = 1
        for iArmy, strArmy in pairs(tblArmy) do
            if iArmy >= ScenarioInfo.Coop1 then
                ScenarioInfo.CoopCDR[coop] = ScenarioFramework.SpawnCommander(strArmy, 'Commander', 'Warp', true, true)
                #DropReinforcements('Seraphim', strArmy, 'NIS_Bots_' .. strArmy ..'_D' .. Difficulty, 'NIS_Drop_' .. strArmy, 'NIS_Transport_Death')
                coop = coop + 1
                WaitSeconds(0.5)
            end
        end
    #end
    IntroMission1()
end


function IntroMission1()
    ScenarioInfo.MissionNumber = 1

    if Debug then
        Utilities.UserConRequest('SallyShears')
        -- Utilities.UserConRequest('ren_IgnoreDecalLOD')
        -- Utilities.UserConRequest('ren_ShadowLOD' 500) -- 250
    end

    StartMission1()
end


function StartMission1()

    ----------------------------------------
    --Primary Objective 1 - Protect the Yolona Oss
    ----------------------------------------
    ScenarioInfo.M1P1 = Objectives.Protect(
        'primary',
        'incomplete',
		'Defend the Yolona Oss',
		'Use the Yolona Oss to crush the coalition.',
        {
            Units = {ScenarioInfo.YolonaOss},
        }
    )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result)
            if(result == false) then
                PlayerLoseYolonaOss()
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P1)

	
	------------------------------------------
    -- Secondary Objective 1 - Protect the Seraphim Ally
    ------------------------------------------
	ScenarioInfo.M1S1 = Objectives.Protect(
        'secondary',
        'incomplete',
		'Protect the Seraphim Commander',
		'Protect the Seraphim Commander against coalition retaliation.',
        {
            Units = {ScenarioInfo.SeraphimCommander},
        }
    )
    ScenarioInfo.M1S1:AddResultCallback(
        function(result)
            if(result == false) then
                --PlayerLose()
				--ArmyBrains[Seraphim]:OnDefeat()

            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1S1)
	
    ------------------------------------------
    -- Primary Objective 2 - Destroy Aeon Base
    ------------------------------------------
    ScenarioInfo.M1P2 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy Aeon Forward Bases',    -- title
        'Disrupt Coalition counter attacks.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M1_Aeon_AirBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Aeon,
                },
                {   
                    Area = 'M1_Aeon_LandBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Aeon,
                },
            },
        }
   )
    ScenarioInfo.M1P2:AddResultCallback(
        function(result)
            if(result) then
                if ScenarioInfo.MissionNumber == 1 then
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, IntroMission2, true)
                    IntroMission2()
                else
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1P2)
    --ScenarioFramework.CreateTimerTrigger(M1P1Reminder1, 600)

    -- Expand map even if objective isn't finished yet
    local M1MapExpandDelay = {7*60, 6*60, 5*60}
    ScenarioFramework.CreateTimerTrigger(IntroMission2, M1MapExpandDelay[Difficulty])


    --table.insert(AssignedObjectives, ScenarioInfo.M1S1)
        --ScenarioFramework.CreateTimerTrigger(M1S1Reminder1, 600)
    

    -----------
    -- Triggers
    -----------
    -- Send group of percies if players ACUs are close to the UEF bases
    --ScenarioInfo.M1Percies1Locked = false
    --ScenarioInfo.M1Percies2Locked = false

    --ScenarioFramework.CreateUnitToMarkerDistanceTrigger(M1SendPercies1, ScenarioInfo.PlayerCDR, 'M1_South_Base_Marker', 40)
    --ScenarioFramework.CreateUnitToMarkerDistanceTrigger(M1SendPercies2, ScenarioInfo.PlayerCDR, 'M1_North_Base_Marker', 40)

    --for k, ACU in ScenarioInfo.CoopCDR or {} do
    --    ScenarioFramework.CreateUnitToMarkerDistanceTrigger(M1SendPercies1, ACU, 'M1_South_Base_Marker', 40)
    --    ScenarioFramework.CreateUnitToMarkerDistanceTrigger(M1SendPercies2, ACU, 'M1_North_Base_Marker', 40)
    --end

    -- Uprade another mex if more than 9 factories
    --ScenarioFramework.CreateArmyStatTrigger(UpgradeMex, ArmyBrains[UEF], 'UpgradeMex', 
    --    {{StatType = 'Units_Active', CompareType = 'GreaterThanOrEqual', Value = 9, Category = categories.FACTORY}})

end

function IntroMission2()

    if ScenarioInfo.MissionNumber == 2 or ScenarioInfo.MissionNumber == 3 then
        return
    end
    ScenarioInfo.MissionNumber = 2
	
	ScenarioFramework.SetPlayableArea('AREA_2', false)
	------------
    -- Order Base
    ------------
	M2OrderAI.OrderBaseAI()
    ArmyBrains[Order]:PBMSetCheckInterval(5)
	
	--ScenarioInfo.OrderCommander = ScenarioUtils.CreateArmyGroup('Order', 'Commander')
	ScenarioInfo.OrderCommander  = ScenarioFramework.SpawnCommander('Order', 'Commander', false, 'Veronica', false, OrderCommanderKilled,
		{'Shield','T3Engineering'})
		--So it doesnt wander away from the main base and get killed building T1 torp defenses
	ScenarioInfo.OrderCommander:AddBuildRestriction( categories.AEON * ( categories.DEFENSE + categories.SHIELD) )
	
	------------
    -- Cybran Island Base
    ------------
	M2CybranAI.CybranIslandBaseAI()
    ArmyBrains[Cybran]:PBMSetCheckInterval(5)
	local M2CybranSMDs = ScenarioUtils.CreateArmyGroup('Cybran','M2_SMD')
	for i,SMD in M2CybranSMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end

	if Difficulty > 1 and not ScenarioInfo.SeraphimCommander:IsDead() then
		ForkThread(function()
			WaitSeconds(120*Difficulty)
			local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Scathis','GrowthFormation')	
			ScenarioFramework.PlatoonMoveChain(platoon, 'M2_ScathisMoveChain')
		end)
	elseif Difficulty > 1 then
		ScenarioUtils.CreateArmyGroup('Cybran','M2_HeavyArtillery')
	end
	
	------------
    -- UEF Air Base
    ------------
	M2UEFAI.UEFM2AirBaseAI()
    ArmyBrains[UEF]:PBMSetCheckInterval(5)

	
	local UEFM2SMD = ScenarioUtils.CreateArmyGroup('UEF','M2_SMD')
	for i,SMD in UEFM2SMD do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end

	
	
	
	------------
    -- Order Fleet Attacks, East and West
    ------------
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefenseFleetEast_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        --IssueDive({v}) Not needed, starts surfaced
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttackChain')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttackChain')
	

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefenseFleetWest_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        --IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttackChain')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttackChain')
	
	------------
    -- Order Land and Air Patrols
    ------------
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefensePatrol_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_OrderLandPatrol1')
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_AirPatrol_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_OrderAirPatrol')
	
	

	------------
    -- UEF and Aeon Fleet Attacks
    ------------
	
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        --IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttackChain')
	
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_AttackFleetNorth_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttackChain')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
	
	------------
    -- Experimental Attacks
    ------------

	--Aeon GC Attack
	ForkThread(function()
		WaitSeconds(Difficulty*20)
		for i = 1, Difficulty do
			for i = 1, 2 do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_GC_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M2_GC_Move')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
			WaitSeconds(10)
			end
		WaitSeconds(60*5)
		end
	end
	)
	
	--Cybran Monkey Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Experimentals_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
	
	--UEF Fatboy Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_FatBoys_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M2_FatBoyMove1')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_FatBoys_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M2_FatBoyMove2')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
	
	------------
    -- Air Raids
    ------------
	
	-- Aeon Air Raid
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_AirRaid_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonAttackChain(platoon, 'M1_AirRaid_Aeon')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
	
	-- Cybran Air Raid
	ForkThread(function()
		WaitSeconds(2*60)
		for i = 1, (3 * Difficulty) do
			for i=1, Difficulty do
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_AirRaid_D' .. Difficulty, 'GrowthFormation')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_CybranAmphibiousAttack')
				ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
				WaitSeconds(5)
			end
			WaitSeconds(60)
		end
	end
	)
	
	-- UEF Air Raid
	ForkThread(function()
		for i = 1, (Difficulty * 3) do
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_AirRaid_D' .. Difficulty, 'GrowthFormation')
		ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
		ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
		WaitSeconds(60/Difficulty)
		end
	end
	)
	------------
    -- Cybran and Seraphim Fleet Attacks
    ------------
	
	if not ScenarioInfo.SeraphimCommander:IsDead() then 
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
		for k, v in EntityCategoryFilterDown(categories.xss0201, platoon:GetPlatoonUnits()) do
			IssueDive({v})
		end
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_SeraFleetAttackChain')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_CybranIslandBaseChain')
	else
	end
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_SeraFleetAttackChain')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')

		

	------------------------------------------
    -- Secondary Objective 2 - Protect the Order Ally
    ------------------------------------------
	ScenarioInfo.M1S2 = Objectives.Protect(
        'secondary',
        'incomplete',
		'Protect the Order Commander',
		'Protect the Order Commander against coalition retaliation.',
        {
            Units = {ScenarioInfo.OrderCommander},
        }
    )
    ScenarioInfo.M1S2:AddResultCallback(
        function(result)
            if(result == false) then
                --PlayerLose()
				--ArmyBrains[Order]:OnDefeat()

            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1S1)
	
	
	------------------------------------------
    -- Primary Objective 3 - Destroy UEF Air Base and Cybran Island Base
    ------------------------------------------
    ScenarioInfo.M2P3 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy UEF and Cybran Forward Bases',    -- title
        'Distrupt Coalition counter attacks.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M2_UEF_AirBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
                {   
                    Area = 'M2_Cybran_IslandBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Cybran,
                },
            },
        }
   )
    ScenarioInfo.M2P3:AddResultCallback(
        function(result)
            if(result) then
                if ScenarioInfo.MissionNumber == 1 then
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, IntroMission2, true)
                    IntroMission3()
                else
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P3)


	
	 -- Expand map even if objective isn't finished yet
	 -- Expand map even if objective isn't finished yet
    local M2MapExpandDelay = {10*60, 9*60, 8*60}
    ScenarioFramework.CreateTimerTrigger(IntroMission3, M2MapExpandDelay[Difficulty])
	
end

function IntroMission3()
    if ScenarioInfo.MissionNumber == 3 or ScenarioInfo.MissionNumber == 4 then
        return
    end
    ScenarioInfo.MissionNumber = 3
	
	ScenarioFramework.SetPlayableArea('AREA_3', false)
end

PlayerLoseYolonaOss = function()

    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.YolonaOss)
    end
    ScenarioFramework.EndOperationSafety()
    ScenarioInfo.OpComplete = false
    for k, v in AssignedObjectives do
        if(v and v.Active) then
            v:ManualResult(false)
        end
    end
    ScenarioFramework.FlushDialogueQueue()
        --ScenarioFramework.Dialogue(OpStrings.X03_M02_109, nil, true) --Replace with taunts from coalition commanders
        --ScenarioFramework.Dialogue(OpStrings.X03_M02_115, nil, true) --
    ForkThread(
        function()
            WaitSeconds(3)
            UnlockInput()
            KillGame() --how make this work lol
			
        end
        )
end

