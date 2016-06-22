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
#local M2OrderAI = import('/maps/SeraNukeMission/SeraNukeMission_m2orderai.lua')  --> make
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
ScenarioInfo.HumanPlayers = {}

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
    ScenarioFramework.SetSeraphimColor(Player)
    ScenarioFramework.SetSeraphimColor(Seraphim)
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
    -- Aeon Firebase
    ------------
	#ScenarioUtils.CreateArmyGroup('Aeon', 'M1_AirBase_1')
    #ScenarioUtils.CreateArmyGroup('Aeon', 'M1_LandBase_1')
    M1AeonAI.AeonM1AirBaseAI() 
	M1AeonAI.AeonM1LandBaseAI() 
    #M1UEFAI.UEFM1SouthBaseAI()
    #M1UEFAI.UEFM1ExpansionBases()
    ArmyBrains[Aeon]:PBMSetCheckInterval(5)
    #ScenarioUtils.CreateArmyGroup('Aeon', 'M1_Mass')

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
	ScenarioUtils.CreateArmyGroup('Player', 'Base')
	ScenarioUtils.CreateArmyGroup('Player', 'DefenseFleet')
	
	------------
    -- Seraphim Base and Fleet
    ------------
	
	ScenarioUtils.CreateArmyGroup('Seraphim', 'Base')
	ScenarioUtils.CreateArmyGroup('Seraphim', 'DefenseFleet')
	
    ------------------
    -- Initial Attacks
    ------------------
    local platoon
    #for i = 1, 2 do
        #platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Initial_Tanks_North_' .. i, 'GrowthFormation')
        #ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_North_Land_Attack_Chain_' .. i)
    #end

    #for i = 1, 2 do
        #platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Initial_Tanks_South_' .. i, 'GrowthFormation')
        #ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_South_Land_Attack_Chain_' .. i)
    #end

    #platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Titans_1_D' .. Difficulty, 'GrowthFormation')
    #ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_Titan_Chain_1')
    #ScenarioFramework.CreatePlatoonDeathTrigger(M1SendTitans1, platoon)

    #platoon = ScenarioUtils.CreateArmyGroupAsPlatoon('UEF', 'M1_Titans_2_D' .. Difficulty, 'GrowthFormation')
    #ScenarioFramework.PlatoonPatrolChain(platoon, 'M1_Titan_Chain_2')
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
    ------------------------------------------
    -- Primary Objective 1 - Destroy Aeon Base
    ------------------------------------------
    ScenarioInfo.M1P1 = Objectives.CategoriesInArea(
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
    ScenarioInfo.M1P1:AddResultCallback(
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
    table.insert(AssignedObjectives, ScenarioInfo.M1P1)
    --ScenarioFramework.CreateTimerTrigger(M1P1Reminder1, 600)

    -- Expand map even if objective isn't finished yet
    local M1MapExpandDelay = {20*60, 15*60, 10*60}
    ScenarioFramework.CreateTimerTrigger(IntroMission2, M1MapExpandDelay[Difficulty])


    table.insert(AssignedObjectives, ScenarioInfo.M1S1)
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

end

