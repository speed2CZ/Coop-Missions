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

local M3AeonAI = import('/maps/SeraNukeMission/SeraNukeMission_m3AeonAI.lua') 
local M3CybranAI = import('/maps/SeraNukeMission/SeraNukeMission_m3CybranAI.lua')  
local M3UEFAI = import('/maps/SeraNukeMission/SeraNukeMission_m3UEFAI.lua')
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


ScenarioInfo.PlayerExists = false
ScenarioInfo.Coop1Exists = false
ScenarioInfo.Coop2Exists = false
ScenarioInfo.Coop3Exists = false

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

function PlayerCommanderKilled()
	ArmyBrains[Player]:OnDefeat()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.PlayerCommander)
    end
	return
end

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

function M1CoalitionAttacks()
	--Stop recurring attacks from previous phase
	if ScenarioInfo.M1RecurringAttacks then 
		for k,v in ScenarioInfo.M1RecurringAttacks do
			KillThread(v)
		end
	end
    local platoon
	ScenarioInfo.M1RecurringAttacks = {}
	
	-- Aeon Air Raid, lasts 4 minutes
	ScenarioInfo.M1RecurringAttacks.AeonAirRaid = ForkThread(function()
		for i = 1, (Difficulty * 2) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_AirRaid_Aeon')
			WaitSeconds(4*60/Difficulty)
		end
	end)
	
	--Aeon GC Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_GC_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_GC_Move')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
    
	-- UEF Fleet Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackFleet_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M1_AttackFleet_UEF1')
	
	-- UEF Riptide Attack vs Player and vs Seraphim, lasts 3 minutes
	ScenarioInfo.M1RecurringAttacks.UEFRipTides = ForkThread(
	function()
		for i = 1, Difficulty do
			for i = 1, Difficulty do
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackPlayer_D' .. Difficulty, 'GrowthFormation')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
		
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackSera_D' .. Difficulty, 'GrowthFormation')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
				WaitSeconds(15)
			end
			WaitSeconds(60*3/Difficulty)
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
    local ArmyTable = ListArmies()
    for army, color in colors do
        if ArmyTable[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end
	if ArmyTable[ScenarioInfo.Player] then
		ScenarioInfo.PlayerExists = true
	end
	if ArmyTable[ScenarioInfo.Coop1] then
		ScenarioInfo.Coop1Exists = true
	end
	if ArmyTable[ScenarioInfo.Coop2] then
		ScenarioInfo.Coop2Exists = true
	end
	if ArmyTable[ScenarioInfo.Coop3] then
		ScenarioInfo.Coop2Exists = true
	end
    -- Unit Cap
    --ScenarioFramework.SetSharedUnitCap(1000)

    -- Disable friendly AI sharing resources to players
    GetArmyBrain(Seraphim):SetResourceSharing(false)
	GetArmyBrain(Order):SetResourceSharing(false)
	
	--UEF Support base in M3 location to provide power for M1 fleet
	ScenarioUtils.CreateArmyGroup('UEF','M1_SupportBase')
	
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
    -- Seraphim Base, run by AI if coop1 not present, else given to player
    ------------
	
	if not ScenarioInfo.Coop1Exists then
		M1SeraAI.SeraphimBaseAI() 
		ArmyBrains[Seraphim]:PBMSetCheckInterval(6)
	else
	end
	
	------------
    -- Seraphim Defense Patrols
    ------------
    local DefenseForceSouth = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseForceSouth_D' .. Difficulty, 'GrowthFormation')
	local DefenseForceEast = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseForceEast_D' .. Difficulty, 'GrowthFormation')
	local DefenseFleet1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'DefenseFleet1_D' .. Difficulty, 'GrowthFormation')
	local DefenseFleet2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'DefenseFleet2_D' .. Difficulty, 'GrowthFormation')
	
	--If there's no coop1, set patrols
	if not ScenarioInfo.Coop1Exists then
		ScenarioFramework.PlatoonPatrolChain(DefenseForceSouth, 'M1_SeraLandPatrolSouth')
		ScenarioFramework.PlatoonPatrolChain(DefenseForceEast, 'M1_SeraLandPatrolEast')
		ScenarioFramework.PlatoonPatrolChain(DefenseFleet1, 'M1_SeraSeaPatrolSouth')	
		ScenarioFramework.PlatoonPatrolChain(DefenseFleet2, 'M1_SeraSeaPatrolWest')
	else  --else, just give them to coop1
		for index, unit in DefenseForceSouth:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Coop1])
		end
		for index, unit in DefenseForceEast:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Coop1])
		end
		for index, unit in DefenseFleet1:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Coop1])
		end
		for index, unit in DefenseFleet2:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Coop1])
		end
	end
	
	--If there is no coop1, spawn the Commander
	if not ScenarioInfo.Coop1Exists then
		ScenarioInfo.SeraphimCommander  = ScenarioFramework.SpawnCommander('Seraphim', 'Commander', false, 'Ithanyis', false, SeraphimCommanderKilled,
		{'BlastAttack','DamageStabilization','RateOfFire'})
		---So it doesnt wander away from the main base and get killed building T1 PD
		ScenarioInfo.SeraphimCommander:AddBuildRestriction( categories.SERAPHIM * ( categories.DEFENSE + categories.SHIELD) )
	end
	
    -- Resources for Coalition AI, slightly delayed cause army didn't recieve it for some reason
    ForkThread(function()
        WaitSeconds(2)
        ArmyBrains[Aeon]:GiveStorage('ENERGY', 100000)
		ArmyBrains[Aeon]:GiveStorage('MASS', 20000)
        ArmyBrains[Aeon]:GiveResource('MASS', 20000)
        ArmyBrains[Aeon]:GiveResource('ENERGY', 100000)
		ArmyBrains[Cybran]:GiveStorage('ENERGY', 100000)
		ArmyBrains[Cybran]:GiveStorage('MASS', 20000)
        ArmyBrains[Cybran]:GiveResource('MASS', 20000)
        ArmyBrains[Cybran]:GiveResource('ENERGY', 100000)
		ArmyBrains[UEF]:GiveStorage('ENERGY', 100000)
		ArmyBrains[UEF]:GiveStorage('MASS', 20000)
        ArmyBrains[UEF]:GiveResource('MASS', 20000)
        ArmyBrains[UEF]:GiveResource('ENERGY', 100000)
    end)

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
	M1CoalitionAttacks()

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
            categories.xal0305 + -- Aeon Sniper Bot
            categories.xaa0202 + -- Aeon Mid Range fighter (Swift Wind)
            categories.xal0203 + -- Aeon Assault Tank (Blaze)
            categories.xab1401 + -- Aeon Quantum Resource Generator
            categories.xas0204 + -- Aeon Submarine Hunter
            categories.xaa0306 + -- Aeon Torpedo Bomber
            categories.xas0306 + -- Aeon Missile Ship
            categories.xab3301 + -- Aeon Quantum Optics Device
            categories.xab2307 + -- Aeon Rapid Fire Artillery
            categories.xaa0305 + -- Aeon AA Gunship
            categories.xrl0302 + -- Cybran Mobile Bomb
            categories.xra0105 + -- Cybran Light Gunship
            categories.xrs0204 + -- Cybran Sub Killer
            categories.xrs0205 + -- Cybran Counter-Intelligence Boat
            categories.xrb2308 + -- Cybran Torpedo Ambushing System
            categories.xrb0104 + -- Cybran Engineering Station 1
            categories.xrb0204 + -- Cybran Engineering Station 2
            categories.xrb0304 + -- Cybran Engineering Station 3
            categories.xrb3301 + -- Cybran Perimeter Monitoring System
            categories.xra0305 + -- Cybran Heavy Gunship
            categories.xrl0305 + -- Cybran Brick
            categories.xrl0403 + -- Cybran Amphibious Mega Bot
			categories.url0402 + -- Cybran Monkeylord
            categories.url0401 + -- Cybran Scathis
            categories.ura0401 + -- Cybran Soul Ripper
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
			categories.ueb2401 + -- UEF Mavor
            categories.ues0401 + -- UEF Atlantis
            categories.xeb2402 + -- UEF Sub-Orbital Defense System
            --categories.xsl0305 + -- Seraph Sniper Bot
            --categories.xsa0402 + -- Seraph Exp Bomber
            categories.xss0304 + -- Seraph Sub Hunter
            categories.xsb0304  -- Seraph Gate
            --categories.xsl0301 -- Seraph sACU
            --categories.xsb2401   -- Seraph exp Nuke (need this)
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
    if not SkipNIS1 then
	    Cinematics.EnterNISMode()
		
		ForkThread(function()
		    -- Vision for NIS location
			local VisMarkerPlayer	= ScenarioFramework.CreateVisibleAreaLocation(150, 'M1_CybranAmphibiousAttack3', 20, ArmyBrains[Player])
			ScenarioInfo.NISGatePlayer = ScenarioUtils.CreateArmyGroup('Player', 'M1_NISGate')[1]
			ScenarioInfo.NISGroupPlayer = ScenarioUtils.CreateArmyGroup('UEF', 'M1_NISAirRaid')	

			IssueAttack(ScenarioInfo.NISGroupPlayer ,ScenarioInfo.NISGatePlayer)
			
			WaitSeconds(8)
			ScenarioInfo.PlayerCommander = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true, PlayerCommanderKilled)
			
			--WaitSeconds(1)
			IssueGuard({ScenarioInfo.PlayerCommander}, ScenarioInfo.YolonaOss)
		end)
		
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M1_CybranAmphibiousAttack3'), 4)
		
		-- spawn coop players too
		if ScenarioInfo.Coop1Exists or ScenarioInfo.Coop2Exists or ScenarioInfo.Coop3Exists then
			ForkThread(function()
				WaitSeconds(10)
				local VisMarkerPlayer	= ScenarioFramework.CreateVisibleAreaLocation(100, 'M1NISCoop', 10, ArmyBrains[Player])
				Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('NISCoopGate'), 4)
				local ArmyTable = ListArmies()
				ScenarioInfo.NISGateCoop = ScenarioUtils.CreateArmyGroup('Seraphim', 'CoopGate')[1]
				ScenarioInfo.NISGroupCoop = ScenarioUtils.CreateArmyGroup('UEF', 'M1_NISAirRaid')		
				IssueAttack(ScenarioInfo.NISGroupCoop ,ScenarioInfo.NISGateCoop)
				if ScenarioInfo.Coop1Exists then
					ScenarioInfo.Coop1Commander = ScenarioFramework.SpawnCommander('Coop1', 'Commander', 'Warp', true, true, Coop1CommanderKilled)
					WaitSeconds(1)
					IssueMove({ScenarioInfo.Coop1Commander},ScenarioUtils.MarkerToPosition('Coop1Move'))
					WaitSeconds(1)
				end
				if ScenarioInfo.Coop2Exists then
					ScenarioInfo.Coop2Commander = ScenarioFramework.SpawnCommander('Coop2', 'Commander', 'Warp', true, true, Coop2CommanderKilled)
					WaitSeconds(1)
					IssueMove({ScenarioInfo.Coop1Commander},ScenarioUtils.MarkerToPosition('Coop1Move'))
					WaitSeconds(1)
				end				
				if ScenarioInfo.Coop3Exists then
					ScenarioInfo.Coop3Commander = ScenarioFramework.SpawnCommander('Coop3', 'Commander', 'Warp', true, true, Coop3CommanderKilled)
					WaitSeconds(1)
					IssueMove({ScenarioInfo.Coop3Commander},ScenarioUtils.MarkerToPosition('Coop1Move'))
					WaitSeconds(1)
				end	
				for k, v in ScenarioInfo.NISGroupCoop do
					if not v:IsDead() then
						v:Kill()
					end
				end
				ScenarioInfo.NISGateCoop:Kill()
			end)
		else
			WaitSeconds(16)
		end

		--VisMarker:Destroy()
		for k, v in ScenarioInfo.NISGroupPlayer do
			if not v:IsDead() then
				v:Kill()
			end
		end
		ScenarioInfo.NISGatePlayer:Kill()
		Cinematics.ExitNISMode()
	else
		ScenarioInfo.PlayerCommander = ScenarioFramework.SpawnCommander('Player', 'Commander', 'Warp', true, true, PlayerCommanderKilled)
	end
    IntroMission1()
end

function Coop1CommanderKilled()

end

function Coop2CommanderKilled()

end

function Coop3CommanderKilled()

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

function M2CoalitionAttacks()
	--Stop recurring attacks from M2 if already in progress
	if ScenarioInfo.M2RecurringAttacks then
		for k,v in ScenarioInfo.M2RecurringAttacks do
			KillThread(v)
		end
	end

	--Cybran Island base either gets a t3 heavy artillery now, or a scathis soon.  Unless difficulty is easy, then niether
	if Difficulty > 1 and not ScenarioInfo.SeraphimCommander:IsDead() then
		ScenarioInfo.M2RecurringAttacks.Scathis = ForkThread(function()
			WaitSeconds(10*60/Difficulty) --5 min for medium, 200 seconds for hard
			local platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Scathis','GrowthFormation')	
			ScenarioFramework.PlatoonMoveChain(platoon, 'M2_ScathisMoveChain')
		end)
	elseif Difficulty > 1 and not ScenarioInfo.M2DontMakeHeavyArtillery then
		ScenarioUtils.CreateArmyGroup('Cybran','M2_HeavyArtillery')
	end
	ScenarioInfo.M2DontMakeHeavyArtillery = true
	
	------------
    -- UEF and Aeon Fleet Attacks
    ------------
	
	--Just one attack
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.uas0401, platoon:GetPlatoonUnits()) do
        --IssueDive({v})
    end
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
	
	--Just one attack
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_AttackFleetNorth_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')	
	
	------------
    -- Experimental Attacks
    ------------

	--Aeon GC Attack   --lasts 10 minutes. 1 wave for easy, 2 for med, 3 for hard
	ScenarioInfo.M2RecurringAttacks.AeonGCs = ForkThread(function()
		WaitSeconds(40)
		for i = 1, Difficulty do
			for i = 1, 2 do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_GC_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M2_GC_Move')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
			WaitSeconds(10)
			end
		WaitSeconds(60*10/Difficulty)
		end
	end
	)
	
	--Cybran Monkey Attack --lasts 10 minutes. 1 wave for easy, 2 for med, 3 for hard
	ScenarioInfo.M2RecurringAttacks.CybranSpiders = ForkThread(function()
		WaitSeconds(20)
		for i = 1, (Difficulty) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Experimentals_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
			WaitSeconds(60*10/Difficulty)
		end
	end)
	
	--UEF Fatboy Attack, two attacks at the same time, but happens only once
	ForkThread(function()
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_FatBoys_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M2_FatBoyMove1')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
	
	WaitSeconds(10)
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_FatBoys_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonMoveChain(platoon, 'M2_FatBoyMove2')
	ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
	end)
	
	------------
    -- Air Raids
    ------------
	
	-- Aeon Air Raid --Lasts 10 minutes, 2 attacks easy, 4 medium, 6 hard
	ScenarioInfo.M2RecurringAttacks.AeonAirRaid = ForkThread(function()
		for i = 1, (2*Difficulty) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M1_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M1_AirRaid_Aeon')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
			WaitSeconds(10*60/(2*Difficulty))
		end
	end)
	
	-- Cybran Air Raid --Lasts a little over 10 minutes, 2 attacks easy, 4 medium, 6 hard
	ScenarioInfo.M2RecurringAttacks.CybranAirRaid = ForkThread(function()
		WaitSeconds(30)
		local WaveCount
		if Difficulty > 1 then
			local WaveCount = 2
		else
			local WaveCount = 1
		end
		for i = 1, (2*Difficulty) do

			for i=1, WaveCount do
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_AirRaid_D' .. Difficulty, 'GrowthFormation')
				ScenarioFramework.PlatoonAttackChain(platoon, 'M1_CybranAmphibiousAttack')
				ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
				WaitSeconds(5)
			end
			WaitSeconds(10*60/(2*Difficulty))
		end
	end)
	
	-- UEF Air Raid ----Lasts 10 minutes, 3 attacks easy, 6 medium, 9 hard
	ScenarioInfo.M2RecurringAttacks.UEFAirRaid = ForkThread(function()
		for i = 1, (Difficulty * 3) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M1_YolonaOss')
			WaitSeconds(10*60/(3*Difficulty))
		end
	end)
	
	
	------------
	--Cybran Stealth Battleship Attack -- Just one
	------------
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_SeraFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
	
	
end

function Mission2NIS()
    if not SkipNIS3 then
        Cinematics.EnterNISMode()

        local VisMarkerM2 = ScenarioFramework.CreateVisibleAreaLocation(200, 'M2_UEFAirBase', 0, ArmyBrains[Player])

        Cinematics.CameraMoveToMarker('M2NISTempest', 4)
        WaitSeconds(10)

        VisMarkerM2:Destroy()
        Cinematics.ExitNISMode()
    end
end

function IntroMission2()



    if ScenarioInfo.MissionNumber == 2 or ScenarioInfo.MissionNumber == 3 then
        return
    end
    ScenarioInfo.MissionNumber = 2
	
	ScenarioFramework.SetPlayableArea('AREA_2', false)
	
	--Stop recurring attacks from previous phase
	for k,v in ScenarioInfo.M1RecurringAttacks do
		KillThread(v)
	end
	
	ScenarioInfo.M2RecurringAttacks = {}
	M2CoalitionAttacks()
	------------
    -- Order Base
    ------------
	M2OrderAI.OrderBaseAI()
    ArmyBrains[Order]:PBMSetCheckInterval(5)
	ScenarioInfo.OrderCommander  = ScenarioFramework.SpawnCommander('Order', 'Commander', false, 'Veronica', false, OrderCommanderKilled,
		{'Shield','T3Engineering'})
		--So it doesnt wander away from the main base and get killed building T1 torp defenses
	ScenarioInfo.OrderCommander:AddBuildRestriction( categories.AEON * ( categories.DEFENSE) )

	------------
    -- Order Fleet Attacks, East and West
    ------------
    ScenarioInfo.M2OrderEastFleet = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefenseFleetEast_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(ScenarioInfo.M2OrderEastFleet, 'M2_AeonFleetAttack')
	--ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_UEFFleetAttackChain')
	--ForkThread(function()
	--	ScenarioPlatoonAI.PlatoonAttackClosestUnit(platoon)
	--end
	--)
	
    ScenarioInfo.M2OrderWestFleet = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefenseFleetWest_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(ScenarioInfo.M2OrderWestFleet, 'M2_UEFFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(ScenarioInfo.M2OrderWestFleet, 'M2_AeonFleetAttack')
	
	------------
    -- Order Land and Air Patrols
    ------------
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_DefensePatrol_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_OrderLandPatrol1')
	
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M2_AirPatrol_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_OrderAirPatrol')
	
	------------
    -- Cybran Island Base
    ------------
	M2CybranAI.CybranIslandBaseAI()
    ArmyBrains[Cybran]:PBMSetCheckInterval(5)
	local M2CybranSMDs = ScenarioUtils.CreateArmyGroup('Cybran','M2_SMD')
	for i,SMD in M2CybranSMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
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
    -- Seraphim Fleet Attacks
    ------------
	
	if not ScenarioInfo.SeraphimCommander:IsDead() then 
		ScenarioInfo.M2SeraphimFleet = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M2_FleetAttack_D' .. Difficulty, 'GrowthFormation')
		for k, v in EntityCategoryFilterDown(categories.xss0201, ScenarioInfo.M2SeraphimFleet:GetPlatoonUnits()) do
			IssueDive({v})
		end
		ScenarioFramework.PlatoonPatrolChain(ScenarioInfo.M2SeraphimFleet, 'M2_SeraFleetAttack')
		ScenarioFramework.PlatoonPatrolChain(ScenarioInfo.M2SeraphimFleet, 'M2_CybranIslandBase')
	else
	end
	
	------
	-- Add Seraphim Tech 3 navy attack to base build
	----
	M1SeraAI.M2SeraphimAttacks()
	
	ForkThread(Mission2NIS)
	
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
                    Area = 'M2_UEFAirBase',
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
                if ScenarioInfo.MissionNumber == 2 then
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

function 	M3CybranFleetAttack()
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M3_FleetAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_CybranFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
end

function M3AeonFleetAttack()
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M3_FleetAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
end

function 	M3_CybranSubAttack()
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M3_SubAttack_D' .. Difficulty, 'GrowthFormation')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M3_CybranSubAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
end

function M3_UEFSubAttack()
	ScenarioInfo.M3UEFNukeSubs = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_NukeSubs_D' .. Difficulty, 'GrowthFormation')
	ScenarioFramework.PlatoonMoveChain(ScenarioInfo.M3UEFNukeSubs, 'M3_UEFSubAttack')	
	local counter = 0
	for _, submarine in EntityCategoryFilterDown(categories.ues0304, ScenarioInfo.M3UEFNukeSubs:GetPlatoonUnits()) do
		counter = counter + 1
		submarine.target = counter
		submarine.NukeThread = submarine:ForkThread(function(self)
			WaitSeconds(5)
		    while not self:IsDead() and self:IsUnitState('Moving') do
                WaitSeconds(5)
            end
			for i = 1, 3 do
				if self and not self:IsDead() then
					self:GiveNukeSiloAmmo(1)
					if not ScenarioInfo.OrderCommander:IsDead() then
						IssueNuke({self}, ScenarioUtils.MarkerToPosition('M3_UEFNuke' .. i ..(self.target)))
					else
						IssueNuke({self}, ScenarioUtils.MarkerToPosition('M1_YolonaOss')) --If the Order is dead, shoot the player instead
					end
					WaitSeconds(10)
				end
			end
		end)
	end
	
	ScenarioInfo.M3UEFAtlantis = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_AtlantisAttack_D' .. Difficulty, 'GrowthFormation')
	ScenarioFramework.PlatoonMoveChain(ScenarioInfo.M3UEFAtlantis, 'M3_UEFAtlantisAttack')
	for _, Atlantis in ScenarioInfo.M3UEFAtlantis:GetPlatoonUnits() do
		Atlantis.AttackThread = Atlantis:ForkThread(function(self)
			WaitSeconds(5)
			while not self:IsDead() and self:IsUnitState('Moving') do
				WaitSeconds(5)
			end
			--IssueDive({self})
			WaitSeconds(10)
			while self and not self:IsDead() do
				local cargoUnits = ScenarioUtils.CreateArmyGroup('UEF', 'M3_AtlantisSquadron')
				for _, unit in cargoUnits do
					IssueStop({unit})
					self:AddUnitToStorage(unit)
				end
				IssueClearCommands({self})
				IssueTransportUnload({self}, self:GetPosition())
				for _, unit in cargoUnits do
					while (not unit:IsDead() and unit:IsUnitState('Attached')) do
						WaitSeconds(2)
					end

				end
				IssueClearCommands(cargoUnits)
				IssuePatrol(cargoUnits, ScenarioUtils.MarkerToPosition('M2_OrderBase'))
				IssuePatrol(cargoUnits, ScenarioUtils.MarkerToPosition('M1_YolonaOss'))
				WaitSeconds(60 + (30/Difficulty))
			end
		end)
	end
end

function M3SeraphimSelens()
	local Selens = ScenarioUtils.CreateArmyGroup('Seraphim', 'M3_Selens')
	SetFireState(Selens, 'HoldFire')
end

function M3CybranMegaliths()
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M3_Megaliths_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
end

function M3AeonGCs()
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M3_GC_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
end

function M3AeonCZAR()
	ScenarioInfo.M3AeonCZAR = ScenarioUtils.CreateArmyUnit('Aeon', 'M3_CZAR')
	for i = 1, Difficulty do
		local CZAREscort = 	ScenarioUtils.CreateArmyGroup('Aeon', 'M3_CZAREscort')
		IssueGuard(CZAREscort, ScenarioInfo.M3AeonCZAR)
	end
    IssueMove({ScenarioInfo.M3AeonCZAR}, ScenarioUtils.MarkerToPosition('M1_AeonAirBase'))
	ScenarioInfo.M3AeonCZAR:ForkThread(function(self)
		while self and not self:IsDead() do
			while not self:IsDead() and self:IsUnitState('Moving') do
				WaitSeconds(5)
			end
			WaitSeconds(10)
			while self and not self:IsDead() do
				IssueClearCommands(self)
				local cargoUnits = ScenarioUtils.CreateArmyGroup('Aeon', 'M3_CZARSquadron')
				for _, unit in cargoUnits do
					IssueStop({unit})
					self:AddUnitToStorage(unit)
				end
				IssueClearCommands({self})
				IssueTransportUnload({self}, self:GetPosition())
				for _, unit in cargoUnits do
					while (not unit:IsDead() and unit:IsUnitState('Attached')) do
						WaitSeconds(2)
					end

				end
				IssueClearCommands(cargoUnits)
				IssuePatrol(cargoUnits, ScenarioUtils.MarkerToPosition('M1_YolonaOss'))
				WaitSeconds(30 + (120/Difficulty))
			end
		end	
	end)
end

function IntroMission3()
    if ScenarioInfo.MissionNumber == 3 or ScenarioInfo.MissionNumber == 4 then
        return
    end
    ScenarioInfo.MissionNumber = 3
	
	ScenarioFramework.SetPlayableArea('AREA_3', false)
	
	--Stop recurring attacks from M2
	for k,v in ScenarioInfo.M2RecurringAttacks do
		KillThread(v)
	end
	
	ScenarioInfo.M3RecurringAttacks = {}
	
	------------
    -- Seraphim and Order Experimental Attacks and Seraphim Selens
    ------------
	if not ScenarioInfo.OrderCommander:IsDead() then 
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'M3_GC_D' .. Difficulty, 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_UEFIslandBase')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_UEFHeavyArtilleryBase')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_UEFAirBase')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_SECityDefense')
	end
	
	if not ScenarioInfo.SeraphimCommander:IsDead() then 
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M3_Ythotha_D' .. Difficulty, 'GrowthFormation')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_AeonAirBase')	
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_SWCityDefense')
		ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_NECityDefense')
		
		M3SeraphimSelens()
	end
	
	------------
    -- Cybran and Aeon Fleet Attacks
    ------------
	
	M3CybranFleetAttack()

	M3AeonFleetAttack()
	
	------------
    -- UEF and Cybran Submarine Attacks
    ------------
	M3_CybranSubAttack()

	M3_UEFSubAttack()
	
	------------
    -- UEF, Cybran, and Aeon Experimental Attacks
    ------------
	
	--Megaliths
	M3CybranMegaliths()

	---GCs
	M3AeonGCs()
	
	--Cybran Monkey Attack
	ScenarioInfo.M3RecurringAttacks.CybranSpiders = ForkThread(function()
	for i=1, (Difficulty + 1) do
		WaitSeconds(120)
		platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Experimentals_D' .. Difficulty, 'GrowthFormation')
		ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
		ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
		ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
		WaitSeconds(240/Difficulty)
	end
	end)
	
	--UEF Fatboy Attack
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M2_FatBoys_D' .. Difficulty, 'GrowthFormation')
	ScenarioFramework.PlatoonMoveChain(platoon, 'M3_UEFIslandBase')
	platoon:ForkThread(function(platoon)
		WaitSeconds(5*60)
		if platoon:GetBrain():PlatoonExists(platoon) then
			ScenarioFramework.PlatoonMoveChain(platoon, 'M2_FatBoyMove1')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_YolonaOss')
		else
		end
	end)
	
	------------
    -- Cybran, UEF, and Aeon Air Raids
    ------------
	--Cybran Air Raid, lasts 10 minutes
	ScenarioInfo.M3RecurringAttacks.CybranAirRaids = ForkThread(function()
		for i = 1, (5 * Difficulty) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M3_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_CybranIslandBase')
			ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
			WaitSeconds(5)
			WaitSeconds(120/Difficulty)
		end
	end)
	
	-- Aeon Air Raid
	M3AeonCZAR()
	
	--UEF Air Raid, lasts 10 minutes
	ScenarioInfo.M3RecurringAttacks.CybranAirRaids = ForkThread(function()
		for i = 1, (5 * Difficulty) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
			ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
			WaitSeconds(5)
			WaitSeconds(120/Difficulty)
		end
	end)
	
	------------
    -- Civilian City and Defenses
    ------------
	
	ScenarioInfo.M3CivilianCity = ScenarioUtils.CreateArmyGroup('Civilians', 'M3_City' )
	ScenarioInfo.M3CivilianDefenseLine = ScenarioUtils.CreateArmyGroup('Civilians', 'M3_DefenseLine' )

	------------
    -- UEF Air Base, Island Base, and Heavy Artillery Base
    ------------
	
	local UEFM3SMDs = ScenarioUtils.CreateArmyGroup('UEF','M3_SMD')
	for i,SMD in UEFM3SMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	
	M3UEFAI.UEFM3AirBaseAI()
	M3UEFAI.UEFM3IslandBaseAI()
	M3UEFAI.UEFM3HeavyArtilleryBaseAI()
    ArmyBrains[UEF]:PBMSetCheckInterval(5)
	
	------------
    -- Aeon Air Base
    ------------
	M3AeonAI.AeonM3AirBaseAI()
	ScenarioUtils.CreateArmyGroup('Aeon','M3_Paragon')
	local AeonM3SMDs = ScenarioUtils.CreateArmyGroup('Aeon','M3_SMD')
	for i,SMD in AeonM3SMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	------------
    -- Cybran Heavy Artillery Base
    ------------
	M3CybranAI.CybranM3HeavyArtilleryBaseAI()
	local CybranM3SMDs = ScenarioUtils.CreateArmyGroup('Cybran','M3_SMD')
	for i,SMD in CybranM3SMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	
	------------------------------------------
    -- Secondary Objective 3 - Destroy New Sanctuary and the Coalition Bases
    ------------------------------------------
    ScenarioInfo.M3S3 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy New Sanctuary',    -- title
        'Crush the human city and leave no building standing.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
                {   
                    Area = 'M3_NewSanctuary',
                    Category = categories.CIVILIAN,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Civilians,
                },
            },
        }
   )
    ScenarioInfo.M3S3:AddResultCallback(
        function(result)
            if(result) then
                if ScenarioInfo.MissionNumber == 2 then
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, IntroMission2, true)
                    --IntroMission4() --> congradulate
                else
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P3)

	
	------------------------------------------
    -- Primary Objective 4 - Destroy New Sanctuary and the Coalition Bases
    ------------------------------------------
    ScenarioInfo.M3P4 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Destroy the Coalitions bases',    -- title
        'Disrupt Coalition counter attacks.',  -- description
        'kill',                         -- action
        {                               -- target
            MarkUnits = true,
            Requirements = {
				{   
                    Area = 'M3_UEFAirBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
                {   
                    Area = 'M3_UEFHeavyArtilleryBase',
                    Category = categories.FACTORY * (categories.SORTSTRATEGIC + categories.ARTILLERY),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
				{   
                    Area = 'M3_UEFIslandBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = UEF,
                },
                {   
                    Area = 'M3_AeonAirBase',
                    Category = categories.FACTORY,
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Aeon,
                },
				{   
                    Area = 'M3_CybranHeavyArtilleryBase',
                    Category = categories.FACTORY * (categories.SORTSTRATEGIC + categories.ARTILLERY),
                    CompareOp = '<=',
                    Value = 0,
                    ArmyIndex = Cybran,
                },
            },
        }
   )
    ScenarioInfo.M3P4:AddResultCallback(
        function(result)
            if(result) then
                if ScenarioInfo.MissionNumber == 2 then
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, IntroMission2, true)
                    IntroMission4()
                else
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P3)
end

IntroMission4 = function()
    if ScenarioInfo.MissionNumber == 4 then
        return
    end
    ScenarioInfo.MissionNumber = 4
	
	ScenarioFramework.SetPlayableArea('AREA_4', false)
	
	---Spawn Cybran, Aeon and UEF bases with Nukes, Mavor, and Salvation.  Spawn the commanders.  Spawn lots of attacks.  Set objective to kill the commanders.

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
            --KillGame() --how make this work lol
			
        end
        )
end

