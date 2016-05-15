version = 3
ScenarioInfo = {
    name = 'Colony',
    description = 'Mission designed for at least 2 players.',
    type = 'campaign_coop',
    starts = true,
    preview = '',
    size = {1024, 1024},
    map = '/maps/Colony/Colony.scmap',
    save = '/maps/Colony/Colony_save.lua',
    script = '/maps/Colony/Colony_script.lua',
    norushradius = 0.000000,
    norushoffsetX_Player = 0.000000,
    norushoffsetY_Player = 0.000000,
    norushoffsetX_UEF = 0.000000,
    norushoffsetY_UEF = 0.000000,
    norushoffsetX_Civilian = 0.000000,
    norushoffsetY_Civilian = 0.000000,
    norushoffsetX_Cybran = 0.000000,
    norushoffsetY_Cybran = 0.000000,
    norushoffsetX_Coop1 = 0.000000,
    norushoffsetY_Coop1 = 0.000000,
    norushoffsetX_Coop2 = 0.000000,
    norushoffsetY_Coop2 = 0.000000,
    norushoffsetX_Coop3 = 0.000000,
    norushoffsetY_Coop3 = 0.000000,
    Configurations = {
        ['standard'] = {
            teams = {
                { name = 'FFA', armies = {'Player','UEF','Civilian','Cybran','Coop1','Coop2','Coop3',} },
            },
            customprops = {
            },
        },
    }}
