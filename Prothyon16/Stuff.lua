V1 - bez transportu
V2 - bez T1 zenistu
V3 - bez T1 zakladny (zenistu)
V4 - nova zakladna

druha mise primary
druha mise vypnuty sec objective
treti mise primary


    IssueAggressiveMove 
    IssueAttack 
    IssueBuildFactory 
    IssueBuildMobile 
    IssueCapture 
    IssueClearCommands
    IssueClearFactoryCommands
    IssueDestroySelf 
    IssueDive 
    IssueFactoryAssist 
    IssueFactoryRallyPoint 
    IssueFerry 
    IssueFormAggressiveMove 
    IssueFormAttack 
    IssueFormMove 
    IssueFormPatrol 
    IssueGuard 
    IssueKillSelf 
    IssueMove 
    IssueMoveOffFactory 
    IssueNuke 
    IssueOverCharge 
    IssuePatrol 
    IssuePause 
    IssueReclaim 
    IssueRepair 
    IssueSacrifice 
    IssueScript 
    IssueSiloBuildNuke 
    IssueSiloBuildTactical 
    IssueStop 
    IssueTactical 
    IssueTeleport 
    IssueTeleportToBeacon 
    IssueTransportLoad 
    IssueTransportUnload 
    IssueTransportUnloadSpecific 
    IssueUpgrade 



buffDef = Buffs['CheatIncome']
    buffAffects = buffDef.Affects
    buffAffects.EnergyProduction.Mult = 2
    buffAffects.MassProduction.Mult = 2
       
        for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                Buff.ApplyBuff(u, 'CheatIncome')
                --Buff.ApplyBuff(u, 'CheatBuildRate')
        end

---------------------------------------------------------------------------------------------------

buffDef = Buffs['CheatIncome']
    buffAffects = buffDef.Affects
    buffAffects.EnergyProduction.Mult = 2
    buffAffects.MassProduction.Mult = 2
       
        for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                Buff.ApplyBuff(u, 'CheatIncome')
                --Buff.ApplyBuff(u, 'CheatBuildRate')
        end
 
    buffAffects.EnergyProduction.Mult = 2
    buffAffects.MassProduction.Mult = 2
       
        for _, u in GetArmyBrain(UEFAlly):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                Buff.ApplyBuff(u, 'CheatIncome')
                --Buff.ApplyBuff(u, 'CheatBuildRate')
        end
 
    buffAffects.EnergyProduction.Mult = 2
    buffAffects.MassProduction.Mult = 2
       
        for _, u in GetArmyBrain(Seraphim):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                Buff.ApplyBuff(u, 'CheatIncome')
                --Buff.ApplyBuff(u, 'CheatBuildRate')


function PlatoonAttackLocation(platoon)
    platoon:Stop()
    local data = platoon.PlatoonData
    if not data.Location then
        error('*SCENARIO PLATOON AI ERROR: PlatoonAttackLocation requires a Location to operate', 2)
    end
    local location = data.Location
    if type(location) == 'string' then
        location = ScenarioUtils.MarkerToPosition(location)
    end
    local aiBrain = platoon:GetBrain()
    local cmd = platoon:AggressiveMoveToLocation(location)
    local threat = 0
    while aiBrain:PlatoonExists(platoon) do
        if not platoon:IsCommandsActive(cmd) then
            location, threat = platoon:GetBrain():GetHighestThreatPosition(1, true)
            platoon:Stop()
            cmd = platoon:AggressiveMoveToLocation(location)
        end
        WaitSeconds(13)
    end
end

# Builds Platoon of 1 Engineer 3 times
    local Temp = {
        'EngineerAttackTemp1',
        'NoPlan',
        { 'uel0105', 1, 4, 'Attack', 'GrowthFormation' },   # T1 Engies
    }
    local Builder = {
        BuilderName = 'EngineerAttackBuilder1',
        PlatoonTemplate = Temp,
        InstanceCount = 1,
        Priority = 150,
        PlatoonType = 'Land',
        RequiresConstruction = true,
        LocationType = 'M1_WestLand_Base',
        PlatoonAIFunction = {SPAIFileName, 'RandomDefensePatrolThread'},       
        PlatoonData = {
            PatrolChain = 'M1_Land_Attack_Chain'
        },
    }
    ArmyBrains[UEF]:PBMAddPlatoon( Builder )



#-----------------------------------------------------------------------------------------------------------
 
# -----------
# Debug only!
# -----------
local SkipNIS1 = true
local SkipNIS2 = true
local SkipNIS3 = true
local SkipNIS5 = true
 
# --------------
# Taunt Managers
# --------------
local ZottooWestTM = TauntManager.CreateTauntManager('ZottooWestTM', '/maps/Prothyon16/Prothyon16_strings.lua')
 
# How long should we wait at the beginning of the NIS to allow slower machines to catch up?
local NIS1InitialDelay = 3
 
 
# --------------
# Map Options
# --------------
 
Options_set = function()
 
    LOG("----- Coop Mission: Configuring match settings...");
 
    -- check game configuration
       
    -- Cutscenes skip
    if (ScenarioInfo.Options.opt_Show_Cutscenes == nil) then
        ScenarioInfo.Options.opt_Show_Cutscenes = 1;
    end
        
    -- set all the things up
    Set_Cutscenes()
 
end
 
Set_Cutscenes = function()
    if (ScenarioInfo.Options.opt_Show_Cutscenes == 0) then
        SkipNIS1 = true
        SkipNIS2 = true
        SkipNIS3 = true
        SkipNIS5 = true
    end
    if (ScenarioInfo.Options.opt_Show_Cutscenes == 1) then
        SkipNIS1 = false
        SkipNIS2 = false
        SkipNIS3 = false
        SkipNIS5 = false
    end
end
 
# -------
# Startup
# -------
function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()
    ScenarioFramework.fillCoop()
 
    # Sets Army Colors
    ScenarioFramework.SetUEFPlayerColor(Player)
    ScenarioFramework.SetUEFAllyColor(UEF)
    ScenarioFramework.SetCoalitionColor(UEFAlly)
    ScenarioFramework.SetCoalitionColor(Objective)
    ScenarioFramework.SetSeraphimColor(Seraphim)
 
    # Unit cap
    SetArmyUnitCap(UEF, 1000)
    SetArmyUnitCap(Seraphim, 2000)
 
    # Spawn Player initial base
    ScenarioUtils.CreateArmyGroup('Player', 'Starting Base')
    ScenarioInfo.Gate = ScenarioUtils.CreateArmyUnit('Player', 'Gate')
    ScenarioInfo.Gate:SetReclaimable(false)
 
    # ----------
    # M1 UEF AI
    # ----------
    M1UEFAI.UEFM1WestBaseAI()
    M1UEFAI.UEFM1EastBaseAI()
    ArmyBrains[UEF]:GiveResource('MASS', 4000)
    ArmyBrains[UEF]:GiveResource('ENERGY', 6000)
 
    # Walls
    ScenarioInfo.M1_Walls = ScenarioUtils.CreateArmyGroup('UEF', 'M1_Walls')
 
    -----------------
    # Initial Patrols
    -----------------
    local units = ScenarioUtils.CreateArmyGroupAsPlatoonCoopBalanced('UEF', 'EastBaseAirDef', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_East_Base_Air_Defence_Chain')))
    end
 
    units = ScenarioUtils.CreateArmyGroupAsPlatoonCoopBalanced('UEF', 'EastBaseLandDef', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolChain({v}, 'M1_East_Defence_Chain1')
    end
 
    units = ScenarioUtils.CreateArmyGroupAsPlatoonCoopBalanced('UEF', 'WestBaseAirDef', 'GrowthFormation')
    for k, v in units:GetPlatoonUnits() do
        ScenarioFramework.GroupPatrolRoute({v}, ScenarioPlatoonAI.GetRandomPatrolRoute(ScenarioUtils.ChainToPositions('M1_WestBase_Air_Def_Chain')))
    end
 
    # ------------------------
    # Cheat Economy/Buildpower
    # ------------------------
    buffDef = Buffs['CheatIncome']
    buffAffects = buffDef.Affects
    buffAffects.EnergyProduction.Mult = 1
    buffAffects.MassProduction.Mult = 1.5
       
        for _, u in GetArmyBrain(UEF):GetPlatoonUniquelyNamed('ArmyPool'):GetPlatoonUnits() do
                Buff.ApplyBuff(u, 'CheatIncome')
                --Buff.ApplyBuff(u, 'CheatBuildRate')
        end
 
    # --------------------
    # Objective Structures
    # --------------------
    ScenarioInfo.M1_Eco_Unlock_Center = ScenarioUtils.CreateArmyUnit('Objective', 'M1_Eco_Unlock Center')
    ScenarioInfo.M1_Eco_Unlock_Center:SetDoNotTarget(true)
    ScenarioInfo.M1_Eco_Unlock_Center:SetCanTakeDamage(false)
    ScenarioInfo.M1_Eco_Unlock_Center:SetCanBeKilled(false)
    ScenarioInfo.M1_Eco_Unlock_Center:SetReclaimable(false)
    ScenarioInfo.M1_Eco_Unlock_Center:SetCustomName("T2 Economy Unlock Center")
 
    ScenarioInfo.M1_T2_Land_Unlock_Center = ScenarioUtils.CreateArmyUnit('Objective', 'M1_T2_Land_Unlock_Center')
    ScenarioInfo.M1_T2_Land_Unlock_Center:SetDoNotTarget(true)
    ScenarioInfo.M1_T2_Land_Unlock_Center:SetCanTakeDamage(false)
    ScenarioInfo.M1_T2_Land_Unlock_Center:SetCanBeKilled(false)
    ScenarioInfo.M1_T2_Land_Unlock_Center:SetReclaimable(false)
    ScenarioInfo.M1_T2_Land_Unlock_Center:SetCustomName("T2 Land Unlock Center")
 
    # Other Structures
    ScenarioInfo.M1_Other_Buildings = ScenarioUtils.CreateArmyGroup('Objective', 'M1_Other_Buildings')
    for k,v in ScenarioInfo.M1_Other_Buildings do
        v:SetCapturable(false)
    end
       
    # --------------------
    # Check the Options
    # --------------------
    Options_set()
end

Prothyon16_options.lua

options =
{
    {
        default = 1,
        label = "Show Cut-scenes",
        help = "Show the camera shenanigans",
        key = 'opt_Show_Cutscenes',
        pref = 'opt_Show_Cutscenes',
        values = {
            {text = "Enabled",help = "", key = 1, },
            {text = "Disabled",help = "", key = 0, },
        },
    },
};




function getCDRsInWater()
    local submergedCDRs = {}
    for _, p in ScenarioInfo.HumanPlayers do
        local units = ArmyBrains[p]:GetListOfUnits(categories.COMMAND, false)
        if(units[1] and not units[1]:IsDead() and units[1]:GetCurrentLayer() == 'Seabed') then
            table.insert(submergedCDRs, units[1])
        end
    end
    return submergedCDRs
end
 
function CDRInWater()
    return table.getn(getCDRsInWater()) > 0
end
 
function attackCDRInWater(platoon)
    submergedCDRs = getCDRsInWater()
    if table.getn(submergedCDRs) == 0 then
        return false
    end
    -- attack random one
    platoon:AttackTarget(submergedCDRs[math.random(1, table.getn(submergedCDRs))]
end