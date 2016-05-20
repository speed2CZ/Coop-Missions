version = 3
ScenarioInfo = {
    name = 'Operation Freedom',
    description = 'The Coalition have arrested some of their Pilots that were suspected to be helping us. Unfortunately, they were and now we must free them. Commander, you will gate in and free our imprisoned Comrades.',
    type = 'campaign_coop',
    starts = true,
    preview = '',
    size = {1024, 1024},
    map = '/maps/jj_mission2/jj_mission2.scmap',
    save = '/maps/jj_mission2/JJ_Mission2_save.lua',
    script = '/maps/jj_mission2/JJ_Mission2_script.lua',
    norushradius = 0.000000,
    Configurations = {
        ['standard'] = {
            teams = {
                { name = 'FFA', armies = {'Player','UEF','NeutralUEF','Coop1','Coop2','Coop3',} },
            },
            customprops = {
            },
        },
    }}
