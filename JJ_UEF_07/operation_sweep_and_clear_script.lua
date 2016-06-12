local Objectives = import('/lua/ScenarioFramework.lua').Objectives
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Utilities = import('/lua/utilities.lua')
local Cinematics = import('/lua/cinematics.lua')
local OpStrings = import('/maps/JJ_UEF_07/operation_sweep_and_clear_strings.lua')
local M1SmithAI = import('/maps/JJ_UEF_07/UEF_M1_BaseAI.lua')

ScenarioInfo.Player = 1
ScenarioInfo.UEF = 2
ScenarioInfo.Order = 3
ScenarioInfo.NeutralOrder = 4
ScenarioInfo.Coop1 = 5
ScenarioInfo.Coop2 = 6
ScenarioInfo.Coop3 = 7

local Player = ScenarioInfo.Player
local UEF = ScenarioInfo.UEF
local Order = ScenarioInfo.Order
local NeutralOrder = ScenarioInfo.NeutralOrder
local Coop1 = ScenarioInfo.Coop1
local Coop2 = ScenarioInfo.Coop2
local Coop3 = ScenarioInfo.Coop3

function OnPopulate()
	ScenarioUtils.InitializeScenarioArmies()

	SetArmyColor('Player', 41, 41, 225)
	SetArmyColor('UEF', 71, 114, 148)
	SetArmyColor('Order', 159, 216, 2)
	SetArmyColor('NeutralOrder', 159, 216, 2)

	local colors = {
	    ['Coop1'] = {80, 80, 240}, 
	    ['Coop2'] = {80, 80, 240}, 
	    ['Coop3'] = {80, 80, 240}
	}
	local tblArmy = ListArmies()
	for army, color in colors do
	   if tblArmy[ScenarioInfo[army]] then
	       ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
	   end
	end

	SetArmyUnitCap(Player, 1000)
	SetArmyUnitCap(UEF, 1000)
	SetArmyUnitCap(Order, 1000)
end
   
function OnStart(self)
	-- Create UEF CDR Unit --
	ScenarioInfo.UEFCommander = ScenarioUtils.CreateArmyUnit('UEF', 'CDR')
	ScenarioInfo.UEFCommander:CreateEnhancement('T3Engineering')
	ScenarioInfo.UEFCommander:CreateEnhancement('ResourceAllocation')
	ScenarioInfo.UEFCommander:CreateEnhancement('Shield')
	ScenarioInfo.UEFCommander:SetCustomName('CDR Smith')

	ScenarioFramework.SetPlayableArea('M1_Play_Area', false)

	-- Create Neutral Order Ambush Force -- 
	ScenarioInfo.OrderAmbush = ScenarioUtils.CreateArmyGroup('NeutralOrder', 'AmbushGroup')

	ForkThread(IntroNIS)
end

----------
-- End Game
----------
function PlayerWin()
end

function PlayerLose(deadCommander)
end

function KillGameWin()
end

----------
-- Functions
----------
function IntroNIS()
	local PlayerCDR = ScenarioUtils.CreateArmyUnit('Player', 'CDR')
	PlayerCDR:CreateEnhancement('HeavyAntiMatterCannon')
	PlayerCDR:SetCustomName('CDR Madox')
    IssueMove({ScenarioInfo.UEFCommander}, ScenarioUtils.MarkerToPosition('Player_CDR_Intro_Dest'))
    IssueMove({PlayerCDR}, ScenarioUtils.MarkerToPosition('UEF_CDR_Intro_Dest'))

	Cinematics.EnterNISMode()
	Cinematics.CameraTrackEntity(PlayerCDR, 40, 2)
	ScenarioFramework.Dialogue(OpStrings.SC_NISIntro, nil, true)
	WaitSeconds(30)
	Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('NIS1_Cam'), 1)
	Cinematics.ExitNISMode()

	for k, v in ScenarioInfo.OrderAmbush do
    	if(v and not v:IsDead()) then
           	ScenarioFramework.GiveUnitToArmy(v, Order)
        end
    end

	--spawn coop players too
	ScenarioInfo.CoopCDR = {}
	local tblArmy = ListArmies()
	coop = 1
	for iArmy, strArmy in pairs(tblArmy) do
	if iArmy >= ScenarioInfo.Coop1 then
	factionIdx = GetArmyBrain(strArmy):GetFactionIndex()
	if (factionIdx == 1) then
			ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'CDR')
		elseif (factionIdx == 2) then
			ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'CDR')
		else
			ScenarioInfo.CoopCDR[coop] = ScenarioUtils.CreateArmyUnit(strArmy, 'CDR')
		end
			ScenarioInfo.CoopCDR[coop]:PlayCommanderWarpInEffect()
			coop = coop + 1
			HumanPlayerCounter = coop
			WaitSeconds(0.5)
			SetArmyUnitCap(coop, 1000)
		end
	end

	for index, coopACU in ScenarioInfo.CoopCDR do
		ScenarioFramework.PauseUnitDeath(coopACU)
		ScenarioFramework.CreateUnitDeathTrigger(PlayerLose, coopACU)
	end

	ScenarioInfo.OrderM1Base = ScenarioUtils.CreateArmyGroup('Order', 'M1_Firebase')
	M1SmithAI.UEFM1BaseFunction(UEF)
	ForkThread(M1)
end

function M1()
	ScenarioInfo.M1P1 = Objectives.Basic(
        'primary',                      # type
        'incomplete',                   # complete
        'Thwart the Order Attack',  # title
        'The Order are attacking your position. Hold them off.',  # description
        Objectives.GetActionIcon('kill'),   # action
        {
        }    
    )

    ScenarioInfo.M1S1 = Objectives.Protect(
        'secondary',                    # type
        'incomplete',                   # complete
        'Assit Colonel Smith',  # title
        'Smith is constructing a base. Protect his ACU at all costs.',  # description
        {                               # target
            Units = {ScenarioInfo.UEFCommander},
        }
    )

    -- attacking --
    ScenarioFramework.Dialogue(OpStrings.M1_1, nil, true)
    local transport = ScenarioUtils.CreateArmyUnit('Order', 'Order_Transport')
    local units = ScenarioUtils.CreateArmyGroupAsPlatoon('Order', 'Transport_Units', 'AttackFormation')

    ScenarioFramework.AttachUnitsToTransports(units:GetPlatoonUnits(), {transport})
	WaitSeconds(0.5)
	IssueTransportUnload({transport}, ScenarioUtils.MarkerToPosition('M1_Order_Drop'))

	IssueMove({transport}, ScenarioUtils.MarkerToPosition('Order_Base'))

	units.PlatoonData = {}
	units.PlatoonData.PatrolChain = ('M1_Order_Patrol_1')
	ScenarioPlatoonAI.PatrolThread(units)

	ScenarioFramework.CreateTimerTrigger(M1OrderAttacks, 50)
end

function M1OrderAttacks()

end