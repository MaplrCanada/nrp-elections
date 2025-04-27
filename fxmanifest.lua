-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Claude'
description 'QBCore Election System'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

lua54 'yes'