local BaseManager = import('/lua/ai/opai/basemanager.lua')

local SPAIFileName = '/lua/scenarioplatoonai.lua'

# ------
# Locals
# ------
local Seraphim = 5

# -------------
# Base Managers
# -------------
local SeraphimM6IslandBase = BaseManager.CreateBaseManager()

function SeraphimM6IslandBaseAI()
	SeraphimM6IslandBase:Initialize(ArmyBrains[Seraphim], 'M6_Seraphim_Island_Base', 'M6_Seraphim_Island_Base_Marker', 150,
        {
             M6_Sera_MEX1 = 1000,
             M6_Sera_FACT1 = 990,
             M6_Sera_FACT2 = 980,
             M6_Sera_MEX2 = 970,
             M6_Sera_PWR1 = 960,
             M6_Sera_FACT3 = 950,
             M6_Sera_PWR2 = 940,
             M6_Sera_MSTR1 = 930,
             M6_Sera_FACT4 = 920,
             M6_Sera_MEX3 = 910,
             M6_Sera_DEF1 = 900,
             M6_Sera_SHD1 = 890,
             M6_Sera_FACT5 = 880,
             M6_Sera_DEF2 = 870,
             M6_Sera_SHD2 = 860,
             M6_Sera_PWR3 = 850,
             M6_Sera_MISC1 = 840,
             M6_Sera_DEF3 = 830,
         }
    )
    SeraphimM6IslandBase:StartEmptyBase(25)
    # SeraphimM6IslandBase:SetConstructionAlwaysAssist(true)
    SeraphimM6IslandBase:SetMaximumConstructionEngineers(5)
    SeraphimM6IslandBase.SetFactoryBuildRateBuff = 'BaseManagerFactoryDefaultBuildRate'
    SeraphimM6IslandBase.SetEngineerBuildRateBuff = 'BaseManagerEngineerDefaultBuildRate'

    SeraphimM6IslandBase:SetActive('AirScouting', true)

end

function NewEngineerCount()
    SeraphimM6IslandBase:SetEngineerCount({25, 20})
    SeraphimM6IslandBase:SetMaximumConstructionEngineers(5)
end