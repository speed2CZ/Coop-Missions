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

--local M4AeonAI = import('/maps/SeraNukeMission/SeraNukeMission_m4AeonAI.lua')
--local M4CybranAI = import('/maps/SeraNukeMission/SeraNukeMission_m4CybranAI.lua')
--local M4UEFAI = import('/maps/SeraNukeMission/SeraNukeMission_m4UEFAI.lua')

local Objectives = import('/lua/ScenarioFramework.lua').Objectives
#local OpStrings = import('/maps/SeraNukeMission/SeraNukeMission_strings.lua')  --> make
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/Utilities.lua')

---------
-- Globals
---------
ScenarioInfo.Player1 = 1
ScenarioInfo.Seraphim = 2
ScenarioInfo.Order = 3
ScenarioInfo.UEF = 4
ScenarioInfo.Aeon = 5
ScenarioInfo.Cybran = 6
ScenarioInfo.Civilians = 7
ScenarioInfo.Player2 = 8
ScenarioInfo.Player3 = 9
ScenarioInfo.Player4 = 10
ScenarioInfo.HumanPlayers = {} --Is this needed????


ScenarioInfo.Player1Exists = false
ScenarioInfo.Player2Exists = false
ScenarioInfo.Player3Exists = false
ScenarioInfo.Player4Exists = false

--------
-- Locals
--------
local Player1 = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4
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

function Player1CommanderKilled()
	ArmyBrains[Player1]:OnDefeat()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.Player1Commander)
    end
	return
end

function OrderCommanderKilled()
	ArmyBrains[Order]:OnDefeat()
end

function SeraphimCommanderKilled()
	ArmyBrains[Seraphim]:OnDefeat()
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
	
	-- UEF Riptide Attack vs Player1 and vs Seraphim, lasts 3 minutes
	ScenarioInfo.M1RecurringAttacks.UEFRipTides = ForkThread(
	function()
		for i = 1, Difficulty do
			for i = 1, Difficulty do
				platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_AttackPlayer1_D' .. Difficulty, 'GrowthFormation')
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
    --ScenarioFramework.SetSeraphimColor(Player1)
    ScenarioFramework.SetSeraphimColor(Seraphim)
    ScenarioFramework.SetArmyColor(Player1, 220, 200, 20)
	ScenarioFramework.SetAeonEvilColor(Order)
    ScenarioFramework.SetUEFPlayerColor(UEF)
    ScenarioFramework.SetAeonPlayerColor(Aeon)
    ScenarioFramework.SetCybranPlayerColor(Cybran)
    ScenarioFramework.SetUEFAlly2Color(Civilians)
    local colors = {
        ['Player2'] = {255, 200, 0}, 
        ['Player3'] = {189, 116, 16}, 
        ['Player4'] = {89, 133, 39}
    }
    local ArmyTable = ListArmies()
    for army, color in colors do
        if ArmyTable[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end
	if ArmyTable[ScenarioInfo.Player1].Human then
		ScenarioInfo.Player1Exists = true
	end
	if ArmyTable[ScenarioInfo.Player2].Human then
		ScenarioInfo.Player2Exists = true
	end
	if ArmyTable[ScenarioInfo.Player3].Human then
		ScenarioInfo.Player3Exists = true
	end
	if ArmyTable[ScenarioInfo.Player4].Human then
		ScenarioInfo.Player4Exists = true
		ScenarioInfo.Player4Base = ScenarioUtils.CreateArmyGroup('Player4','Base')
		----create mex positions for this base that are not normally there
		for k, unit in EntityCategoryFilterDown(categories.uab1302, ScenarioInfo.Player4Base) do
			posx = unit:GetPosition()[1]
			posy = unit:GetPosition()[3]
			GenerateResourcesMarker(posx, posy)		
		end

	end
    -- Unit Cap
    --ScenarioFramework.SetSharedUnitCap(1000)

    -- Disable friendly AI sharing resources to Player1s
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
    -- Seraphim Base, run by AI if Player2 not present, else given to Player1
    ------------
	
	if not ScenarioInfo.Player2Exists then
		M1SeraAI.SeraphimBaseAI() 
		ArmyBrains[Seraphim]:PBMSetCheckInterval(6)
	else
		local Player2Base = {}
		Player2Base.Core = ScenarioUtils.CreateArmyGroup('Seraphim', 'CoreBase')
		Player2Base.InnerDefenseRing = ScenarioUtils.CreateArmyGroup('Seraphim', 'InnerDefenseRing' )
		Player2Base.SupportFactories = ScenarioUtils.CreateArmyGroup('Seraphim', 'SeraphimSupportFactories')	
		if Difficulty<3 then
			Player2Base.OuterDefenseRing = ScenarioUtils.CreateArmyGroup('Seraphim', 'OuterDefenseRing' )
		end
		for index, group in Player2Base do
			for i, unit in group do
				ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Player2])
			end
		end
	end
	
	------------
    -- Seraphim Defense Patrols
    ------------
    local DefenseForceSouth = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseForceSouth_D' .. Difficulty, 'GrowthFormation')
	local DefenseForceEast = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseForceEast_D' .. Difficulty, 'GrowthFormation')
	local DefenseFleet1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'DefenseFleet1_D' .. Difficulty, 'GrowthFormation')
	local DefenseFleet2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'DefenseFleet2_D' .. Difficulty, 'GrowthFormation')
	local DefenseAirPatrol = ScenarioUtils.CreateArmyGroupAsPlatoon('Seraphim', 'M1_DefenseAirPatrol_D' .. Difficulty, 'GrowthFormation')
	
	--If there's no Player2, set patrols
	if not ScenarioInfo.Player2Exists then
		ScenarioFramework.PlatoonPatrolChain(DefenseForceSouth, 'M1_SeraLandPatrolSouth')
		ScenarioFramework.PlatoonPatrolChain(DefenseForceEast, 'M1_SeraLandPatrolEast')
		ScenarioFramework.PlatoonPatrolChain(DefenseFleet1, 'M1_SeraSeaPatrolSouth')	
		ScenarioFramework.PlatoonPatrolChain(DefenseFleet2, 'M1_SeraSeaPatrolWest')
		ScenarioFramework.PlatoonPatrolChain(DefenseAirPatrol, 'M1_SeraLandPatrolSouth')
	else  --else, just give them to Player2
		for index, unit in DefenseForceSouth:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Player2])
		end
		for index, unit in DefenseForceEast:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Player2])
		end
		for index, unit in DefenseFleet1:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Player2])
		end
		for index, unit in DefenseFleet2:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Player2])
		end
		for index, unit in DefenseAirPatrol:GetPlatoonUnits() do
			ScenarioFramework.GiveUnitToArmy(unit, ArmyTable[ScenarioInfo.Player2])
		end
	end
	
	--If there is no Player2, spawn the Commander
	if not ScenarioInfo.Player2Exists then
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
    -- Player1 Base and Fleet
    ------------
	local Player1Base = ScenarioUtils.CreateArmyGroup('Player1', 'Base')
	local DefenseFleet = ScenarioUtils.CreateArmyGroupAsPlatoon('Player1', 'DefenseFleet','GrowthFormation')
	for k, v in EntityCategoryFilterDown(categories.xss0201, DefenseFleet:GetPlatoonUnits()) do
        IssueDive({v})
    end
	for k, v in EntityCategoryFilterDown(categories.xsb2401, Player1Base) do
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
    for _, Player in ScenarioInfo.HumanPlayers do
        ScenarioFramework.AddRestriction(Player,
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
			local VisMarkerPlayer1	= ScenarioFramework.CreateVisibleAreaLocation(150, 'M1_CybranAmphibiousAttack3', 20, ArmyBrains[Player1])
			ScenarioInfo.NISGatePlayer1 = ScenarioUtils.CreateArmyGroup('Player1', 'M1_NISGate')[1]
			ScenarioInfo.NISGroupPlayer1 = ScenarioUtils.CreateArmyGroup('UEF', 'M1_NISAirRaid')	

			IssueAttack(ScenarioInfo.NISGroupPlayer1 ,ScenarioInfo.NISGatePlayer1)
			
			WaitSeconds(8)
			ScenarioInfo.Player1Commander = ScenarioFramework.SpawnCommander('Player1', 'Commander', 'Gate', true, true, Player1CommanderKilled)
			
			--WaitSeconds(1)
			IssueGuard({ScenarioInfo.Player1Commander}, ScenarioInfo.YolonaOss)
		end)
		
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M1_CybranAmphibiousAttack3'), 4)
		
		-- spawn coop Player1s too
		if ScenarioInfo.Player2Exists or ScenarioInfo.Player3Exists or ScenarioInfo.Player4Exists then
			WaitSeconds(10)
			ForkThread(M1CoopNIS)
			WaitSeconds(20)
		else
			WaitSeconds(16)
		end

		--VisMarker:Destroy()
		for k, v in ScenarioInfo.NISGroupPlayer1 do
			if not v:IsDead() then
				v:Kill()
			end
		end
		ScenarioInfo.NISGatePlayer1:Kill()
		Cinematics.ExitNISMode()
	else
		ScenarioInfo.Player1Commander = ScenarioFramework.SpawnCommander('Player1', 'Commander', 'Warp', true, true, Player1CommanderKilled)
	end
    IntroMission1()
end

function M1CoopNIS()
	local VisMarkerPlayer1	= ScenarioFramework.CreateVisibleAreaLocation(100, 'M1NISCoop', 20, ArmyBrains[Player1])
	ScenarioInfo.NISGroupCoop = ScenarioUtils.CreateArmyGroup('UEF', 'M1_NISAirRaidCoop')		
	ScenarioInfo.NISGateCoop = ScenarioUtils.CreateArmyGroup('Seraphim', 'M1_CoopGate')[1]
	IssueAttack(ScenarioInfo.NISGroupCoop ,ScenarioInfo.NISGateCoop)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M1NISCoop'), 4)
	if ScenarioInfo.Player2Exists then
		ScenarioInfo.Player2Commander = ScenarioFramework.SpawnCommander('Player2', 'Commander', 'Gate', true, true, Player2CommanderKilled)
		ScenarioInfo.SeraphimCommander = ScenarioInfo.Player2Commander
		IssueMove({ScenarioInfo.Player2Commander},ScenarioUtils.MarkerToPosition('Player2Move'))
		WaitSeconds(2)
	else
		WaitSeconds(2)
	end
	if ScenarioInfo.Player3Exists then
		ScenarioInfo.Player3Commander = ScenarioFramework.SpawnCommander('Player3', 'Commander', 'Gate', true, true, Player3CommanderKilled)
		WaitSeconds(1)
		IssueMove({ScenarioInfo.Player3Commander},ScenarioUtils.MarkerToPosition('Player3Move'))
		WaitSeconds(2)
	else
		WaitSeconds(3)
	end				
	if ScenarioInfo.Player4Exists then
		ScenarioInfo.Player4Commander = ScenarioFramework.SpawnCommander('Player4', 'Commander', 'Gate', true, true, Player4CommanderKilled)
		WaitSeconds(1)
		IssueMove({ScenarioInfo.Player4Commander},ScenarioUtils.MarkerToPosition('Player4Move'))
		WaitSeconds(3)
	else
		WaitSeconds(3)
	end	
	
	for k, v in ScenarioInfo.NISGroupCoop do
		if not v:IsDead() then
			IssueAggressiveMove({v},ScenarioUtils.MarkerToPosition('Player2Move'))
		end
	end
	---]]
	--WaitSeconds(2)
	ScenarioInfo.NISGateCoop:Kill()

end

function Player2CommanderKilled()
	ArmyBrains[Player2]:OnDefeat()
end

function Player3CommanderKilled()
	ArmyBrains[Player3]:OnDefeat()
end

function Player4CommanderKilled()
	ArmyBrains[Player4]:OnDefeat()
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
                Player1LoseYolonaOss()
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
    ScenarioInfo.M1S1:AddResultCallback()
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
	
	--UEF Fatboy Attack, two attacks at the same time, but happens only once this wave
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
		local WaveCount = 1
		if Difficulty > 1 then
			local WaveCount = 2
		else
			local WaveCount = 1
		end
		for i = 1, (2*Difficulty) do

			for i = 1, WaveCount do
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

        local VisMarkerM2 = ScenarioFramework.CreateVisibleAreaLocation(200, 'M2_UEFAirBase', 0, ArmyBrains[Player1])

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
	-- Add Seraphim Tech 3 navy attack to base build if we have an ai there
	----
	if not ScenarioInfo.Player2Exists then
		M1SeraAI.M2SeraphimAttacks()
	end
	
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
                --Player1Lose()
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

function M3CoalitionAttacks() --We will save time by also calling this in M4
	M3CybranFleetAttack()
	M3AeonFleetAttack()
	M3CybranMegaliths()
	M3AeonGCs()
	M3CybranMonkeyAttack()
	M3UEFFatboyAttack()
	M3UEFAirRaid()
	M3CybranAirRaid()
	if ScenarioInfo.MissionNumber == 3 then --These attacks only occur on M3
		M3AeonCZAR()
		M3_CybranSubAttack()	
		M3_UEFSubAttack()
	end
end

function M3CybranFleetAttack()
    platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M3_FleetAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M3_CybranFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
end

function M3AeonFleetAttack()
	platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'M3_FleetAttack_D' .. Difficulty, 'GrowthFormation')
    ScenarioFramework.PlatoonPatrolChain(platoon, 'M2_AeonFleetAttack')
	ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
end

function M3_CybranSubAttack()
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
						IssueNuke({self}, ScenarioUtils.MarkerToPosition('M1_YolonaOss')) --If the Order is dead, shoot the Player1 instead
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
			if self:IsDead() then
				return
			end
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

function M3CybranMonkeyAttack()
	ScenarioInfo.M3RecurringAttacks.CybranSpiders = ForkThread(function()
		for i=1, ((Difficulty + 1)) do
			WaitSeconds(120)
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M2_Experimentals_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousMove')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M1_SeraphimBase')
			ScenarioFramework.PlatoonMoveChain(platoon, 'M1_CybranAmphibiousAttack')
			WaitSeconds(240/Difficulty)
		end
	end)
end

function M3UEFFatboyAttack()
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
end

function M3UEFAirRaid()
	ScenarioInfo.M3RecurringAttacks.UEFAirRaids = ForkThread(function()
		for i = 1, (5 * Difficulty) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M3_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_OrderBase')
			ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
			WaitSeconds(5)
			WaitSeconds(120/Difficulty)
		end
	end)
end

function M3CybranAirRaid()
	ScenarioInfo.M3RecurringAttacks.CybranAirRaids = ForkThread(function()
		for i = 1, (5 * Difficulty) do
			platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('Cybran', 'M3_AirRaid_D' .. Difficulty, 'GrowthFormation')
			ScenarioFramework.PlatoonAttackChain(platoon, 'M2_CybranIslandBase')
			ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_YolonaOss')
			WaitSeconds(5)
			WaitSeconds(120/Difficulty)
		end
	end)
end

function M3SeraphimSelens()
	local Selens = ScenarioUtils.CreateArmyGroup('Seraphim', 'M3_Selens')
	SetFireState(Selens, 'HoldFire') --This no longer works for some reason
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
		--M3SeraphimSelens() --removed because "SetFireState" breaks script
	end
	
	------------
	-- Various attacks
    ------------
	ForkThread(M3CoalitionAttacks)

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
	
	---NIS	
	ForkThread(IntroMission3NIS)
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
                    Category = categories.FACTORY, --* (categories.SORTSTRATEGIC + categories.ARTILLERY),
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
                    Category = categories.FACTORY, --* (categories.SORTSTRATEGIC + categories.ARTILLERY),
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
                if ScenarioInfo.MissionNumber == 3 then
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, IntroMission2, true)
                    ---IntroMission4() --For later
					EndDialogue()
                else
                    -- ScenarioFramework.Dialogue(OpStrings.M1_Bases_Destroyed, nil, true)
                end
            end
        end
    )
    table.insert(AssignedObjectives, ScenarioInfo.M2P3)
	
	--[[  This is broken... it hangs the game, maybe
	------------
	--If the Order and Seraphim have surviving fleets, let's have them start looking for enemies to kill
	-----------
	
	if ScenarioInfo.M2SeraphimFleet:GetBrain():PlatoonExists(ScenarioInfo.M2SeraphimFleet) then
		ForkThread(ScenarioPlatoonAI.PlatoonAttackClosestUnit,ScenarioInfo.M2SeraphimFleet,)
	end
	if  ScenarioInfo.M2OrderEastFleet:GetBrain():PlatoonExists( ScenarioInfo.M2OrderEastFleet) then
		ForkThread(ScenarioPlatoonAI.PlatoonAttackClosestUnit,ScenarioInfo.M2OrderEastFleet)
	end	
	if  ScenarioInfo.M2OrderWestFleet:GetBrain():PlatoonExists( ScenarioInfo.M2OrderWestFleet) then
		ForkThread(ScenarioPlatoonAI.PlatoonAttackClosestUnit,ScenarioInfo.M2OrderWestFleet)	
	end	
	--]]
end

------------
-- Mission 3
------------
function IntroMission3NIS()
    if not SkipNIS1 then
	    Cinematics.EnterNISMode()
		
		ForkThread(function()
		    -- Vision for NIS location
			local VisMarkerPlayer1	= ScenarioFramework.CreateVisibleAreaLocation(200, 'M3NISDuke', 10, ArmyBrains[Player1])
			local VisMarkerPlayer2	= ScenarioFramework.CreateVisibleAreaLocation(200, 'M3NISDisruptor', 20, ArmyBrains[Player1])						
			WaitSeconds(8)
		
		end)
		
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M3NISDuke'), 5)
		WaitSeconds(5)
		Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('M3NISDisruptor'), 5)
		WaitSeconds(5)
		
		Cinematics.ExitNISMode()
	else
		return
	end
    ---IntroMission3()
end

IntroMission4 = function()

    if ScenarioInfo.MissionNumber == 4 then
        return
    end
    ScenarioInfo.MissionNumber = 4
	
	ScenarioFramework.SetPlayableArea('AREA_4', false)
	
	---UEF, Cybran, and Aeon Sea, Air, and Experimental Attacks
	ForkThread(M3CoalitionAttacks()) 
	
	------------
    -- Aeon Air Base, Naval Base, and Salvation Base
    ------------
	M4AeonAI.AeonM4AirBaseAI()
	M4AeonAI.AeonM4NavalBaseAI()
	M4AeonAI.AeonM4SalvationBaseAI()

	local AeonM4DefenseLine = ScenarioUtils.CreateArmyGroup('Aeon','M4_DefenseLine')	
	local AeonM4SMDs = ScenarioUtils.CreateArmyGroup('Aeon','M4_SMD')
	for i,SMD in AeonM3SMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	--ACU
    ScenarioInfo.AeonCommander = ScenarioFramework.SpawnCommander('Aeon', 'Commander', false, 'Rhealis', true, M4AeonCommanderKilled, 
        {'AdvancedEngineering','T3Engineering','Shield','ShieldHeavy','EnhancedSensors'})
	
	------------
    -- UEF Air Base, Naval Base, and Mavor Base
    ------------
	M4UEFAI.UEFM4AirBaseAI()
	M4UEFAI.UEFM4NavalBaseAI()
	M4UEFAI.UEFM4SalvationBaseAI()
	
	local UEFM4DefenseLine = ScenarioUtils.CreateArmyGroup('UEF','M4_DefenseLine')	
	local UEFM4SMDs = ScenarioUtils.CreateArmyGroup('UEF','M4_SMD')
	for i,SMD in AeonM3SMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	---ACU
	ScenarioInfo.UEFCommander = ScenarioFramework.SpawnCommander('UEF', 'Commander', false, 'Henry', true, M4UEFCommanderKilled, 
        {'AdvancedEngineering','T3Engineering','Shield','ShieldGeneratorField','ResourceAllocation'})
	
	
	------------
    -- Cybran Air Base, Naval Base, and Mavor Base
    ------------
	M4CybranAI.CybranM4AirBaseAI()
	M4CybranAI.CybranM4NavalBaseAI()
	M4CybranAI.CybranM4SalvationBaseAI()
	
	local CybranM4DefenseLine = ScenarioUtils.CreateArmyGroup('Cybran','M4_DefenseLine')	
	local CybranM4SMDs = ScenarioUtils.CreateArmyGroup('Cybran','M4_SMD')
	for i,SMD in AeonM3SMDs do
		SMD:GiveTacticalSiloAmmo(Difficulty - 1)
	end
	
	---ACU
	ScenarioInfo.CybranCommander = ScenarioFramework.SpawnCommander('Cybran', 'Commander', false, 'Speed2', true, M4CybranCommanderKilled, 
        {'AdvancedEngineering','T3Engineering','StealthGenerator','CloakingGenerator','MicrowaveLaserGenerator'})


	---	Set objective to kill the commanders.
    ScenarioInfo.M3P4 = Objectives.CategoriesInArea(
        'primary',                      -- type
        'incomplete',                   -- complete
        'Kill the Coalition Commanders',    -- title
        'Defeat the Coalition commanders.',  -- description
        'kill',                         -- action
        {
            Units = {ScenarioInfo.UEFCommander,
					ScenarioInfo.CybranCommander,
					ScenarioInfo.AeonCommander},
        }
   )
end

function M4UEFCommanderKilled()
	ArmyBrains[UEF]:OnDefeat()
end

function M4CybranCommanderKilled()
	ArmyBrains[Cybran]:OnDefeat()
end

function M4AeonCommanderKilled()
	ArmyBrains[Aeon]:OnDefeat()
end

Player1LoseYolonaOss = function()

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
            WaitSeconds(5)
            KillGame() --how make this work lol
			
        end
        )
end

function KillGame()
    UnlockInput()
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, false)
end

function EndDialogue()
    local dialogue = CreateDialogue('If you read this you managed to complete all objectives sucessfully. Rest of the mission is still under development. Thank you for testing, speed2', {'Continue', 'Quit'})
    dialogue.OnButtonPressed = function(self, info)
		dialogue:Destroy()
		if info.buttonID == 2 then
			PlayerWin()
		end
	end
end

function PlayerWin()
    if(not ScenarioInfo.OpEnded) then
        ScenarioFramework.EndOperationSafety()
        ScenarioInfo.OpComplete = true

        ForkThread(KillGame)
    end
end
