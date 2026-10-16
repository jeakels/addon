fx_version 'cerulean'
game 'gta5'

author 'Community of fiveguard.net'
description 'Addon pack for fiveguard'
version '1.6.2'
lua54 'yes'
addon 'yes'

data_file 'DLC_ITYP_REQUEST' 'stream/mads_no_exp_pumps.ytyp'

shared_script 'shared.lua'

server_scripts {
    'server/sv_resourceManager.js',
    'server/vrp_bridge.lua',
    'server/sv_main.lua'
}

client_script 'client/cl_main.lua'

files {
    'client/cl_antiFiveguardStopper.lua',
    'client/cl_easyBypass.lua',
    'client/cl_heartbeat.lua',
    'client/cl_vehicleProtection.lua',
    'client/cl_weaponProtection.lua'
}

file 'bypassNative.lua'
file 'xss.lua'
