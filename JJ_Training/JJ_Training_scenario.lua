version = 3
ScenarioInfo = {
    name = 'Operation: Training',
    description = '<LOC JJ_Training_Description>A Former UEF Naval testing ground that has been occupied by the coalition to train new commanders. This area was once a fearce battle field but has deceased in to a small training ground. This ground is maintained by Colonel JJ.',
    type = 'campaign_coop',
    starts = true,
    preview = '',
    size = {256, 256},
    map = '/maps/JJ_Training/JJ_Training.scmap',
    save = '/maps/JJ_Training/JJ_Training_save.lua',
    script = '/maps/JJ_Training/JJ_Training_script.lua',
    norushradius = 70.000000,
    norushoffsetX_JJ = 0.000000,
    norushoffsetY_JJ = 0.000000,
    norushoffsetX_Player = 0.000000,
    norushoffsetY_Player = 0.000000,
    norushoffsetX_Enemy = 0.000000,
    norushoffsetY_Enemy = 0.000000,
    Configurations = {
        ['standard'] = {
            teams = {
                { name = 'FFA', armies = {'JJ','Player','Enemy',} },
            },
            customprops = {
                ['ExtraArmies'] = STRING( 'Island 20' ),
            },
        },
    }}
