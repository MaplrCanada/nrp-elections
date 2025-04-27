-- File: fxmanifest.lua

fx_version 'cerulean'
game 'gta5'

author 'Claude'
description 'QBCore Election System'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/nui_callbacks.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/*.jpg',
}

lua54 'yes'