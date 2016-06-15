local BaseManager = import('/lua/ai/opai/basemanager.lua')
local SPAIFileName = '/lua/ScenarioPlatoonAI.lua'

---------
-- Locals
---------
local Cybran = 4
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local CybranM2Base = BaseManager.CreateBaseManager()

--------------------
-- Cybran M2 North Base
--------------------
function CybranM2BaseAI()
    CybranM2NorthBase:InitializeDifficultyTables(ArmyBrains[Cybran], 'M2_Cybran_Base', 'M2_Cybran_Base_Marker', 160, {M2_Cybran_Base = 100})
    CybranM2NorthBase:StartNonZeroBase({{18, 21, 24}, {14, 17, 20}})
    CybranM2NorthBase:SetMaximumConstructionEngineers(4)
    
    CybranM2NorthBase:SetActive('AirScouting', true)

    -- Spawn support factories a bit later, else they sometimes bug out and can't build higher tech units.
    ForkThread(function()
        WaitSeconds(1)
        CybranM2NorthBase:AddBuildGroupDifficulty('M2_Cybran_Base_Support_Factories', 100, true)
    end)

    CybranM2BaseAirAttacks()
    CybranM2BaseLandAttacks()
    CybranM2BaseNavalAttacks()
end

function CybranM2BaseAirAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}
end

function CybranM2BaseLandAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}
end

function CybranM2BaseNavalAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}
end