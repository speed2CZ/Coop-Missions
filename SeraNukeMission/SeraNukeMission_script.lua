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
local M1AeonAI = import('/maps/SeraNukeMission/SeraNukeMission_m1AeonAI.lua')  --> make
local M1SeraAI = import('/maps/SeraNukeMission/SeraNukeMission_m1SeraAI.lua')  --> make
local M2OrderAI = import('/maps/SeraNukeMission/SeraNukeMission_m2OrderAI.lua')  --> make
#local M2UEFAI = import('/maps/SeraNukeMission/SeraNukeMission_m2uefai.lua')  --> make
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
	
	ScenarioInfo.SeraphimCommander = ScenarioUtils.CreateArmyGroup('Seraphim', 'Commander')
	
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
	ScenarioFramework.PlatoonAttackChain(platoon, 'SeraphimBaseMarker')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
    
	-- UEF Fleet Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackFleet_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_AttackFleet_UEF1')
	
	
	-- UEF Riptide Attack vs Player and vs Seraphim
	ForkThread(function()
	for  for i = 1, Difficulty do
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackPlayer_D' .. Difficulty, 'GrowthFormation')
		ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
		
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackSera_D' .. Difficulty, 'GrowthFormation')
		ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
		WaitSeconds(15)
	end


	
	--Cybran Spider Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_Experimentals_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
	ScenarioFramework.PlatoonAttackChain(platoon, 'SeraphimBaseMarker')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
	
	--Cybran Wagners
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M1_WagnerAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M3_CybranAmphibiousMove')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_CybranAmphibiousAttack')
	
	#ScenarioFramework.CreatePlatoonDeathTrigger(M1SendTitans2, platoon)

    #for i = 1, 3 do
        #platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Engineer' .. i, 'GrowthFormation')
        #ScenarioFramework.PlatoonAttackChain(platoon, 'M1_Reclaim_Chain_' .. i)
    #end

    -- Wrecks
    #ScenarioUtils.CreateArmyGroup('UEF', 'M1_Wrecks', true)

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
                PlayerLose()
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
            Units = {ScenarioInfo.SeraphimCommander[1]},
        }
    )
    ScenarioInfo.M1S1:AddResultCallback(
        function(result)
            if(result == false) then
                --PlayerLose()
				--ArmyBrains[Seraphim]:OnDefeat()
				for i,v in ArmyBrains[Seraphim]:GetListOfUnits(categories.ALLUNITS, false) do
					v:Kill()
				end
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
        'Destroy Aeon Forward Base',    -- title
        'Defend ally against Coalition attacks.',  -- description
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
    local M1MapExpandDelay = {6*60, 6*60, 5.5*60}
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

	------------
    -- Order Base
    ------------
	M2OrderAI.OrderM2BaseAI()
    ArmyBrains[Order]:PBMSetCheckInterval(5)
	
	------------
    -- Order Fleet Attacks, East and West
    ------------
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefenseFleetEast_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttackChain')
	

    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefenseFleetWest_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttackChain')
	

	------------
    -- UEF and Aeon Fleet Attacks
    ------------
	
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttackChain')
	
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_M2_AttackFleetNorth_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttackChain')
	
	------------
    -- Experimental Attacks
    ------------

	--Aeon GC Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_GC_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M2_GC_Move')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOsss')
	
	--Cybran Monkey Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Experimentals_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
	ScenarioFramework.PlatoonAttackChain(platoon, 'SeraphimBaseMarker')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
	
	------------
    -- Air Raids
    ------------
	
	-- Aeon Air Raid
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_AirRaid_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonAttackChain(platoon, 'M1_AirRaid_Aeon')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
	
	-- Cybran Air Raid
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_AirRaid_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonAttackChain(platoon, 'M1_CybranAmphibiousAttack')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
	
	
	------------
    -- Cybran and Seraphim Fleet Attacks
    ------------
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.xss0201, platoon:GetPlatoonUnits()) do
        IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_SeraFleetAttackChain')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_CybranIslandBaseChain')
	
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
            Units = {ScenarioInfo.OrderCommander[1]},
        }
    )
    ScenarioInfo.M1S2:AddResultCallback(
        function(result)
            if(result == false) then
                --PlayerLose()
				--ArmyBrains[Order]:OnDefeat()
				for i,v in ArmyBrains[Order]:GetListOfUnits(categories.ALLUNITS, false) do
					v:Kill()
				end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M1S1)
	
	
end

