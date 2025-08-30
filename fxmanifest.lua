fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MidlandMan'
description 'Standalone Airfield Fast Travel with Cutscene and Sound'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    '@NativeUI/NativeUI.lua',
    'config.lua',
    'client.lua'
}

dependencies {
    'qb-target',
    'ox_lib'
}
