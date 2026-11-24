fx_version 'cerulean'
game 'gta5'

name 'mz_lib'
author 'mz_lib contributors'
description 'Biblioteca standalone, modular e tipada para FiveM'
version '1.0.2'
lua54 'yes'

ui_page 'web/dist/index.html'

shared_scripts {
  'config.lua',
  'shared/init.lua',
  'shared/locale.lua',
  'shared/utils.lua'
}

client_scripts {
  'client/callbacks.lua',
  'client/ui.lua',
  'client/progress.lua',
  'client/streaming.lua',
  'client/world.lua',
  'client/zones.lua',
  'client/points.lua',
  'client/helpers.lua'
}

server_scripts {
  'server/callbacks.lua',
  'server/utils.lua',
  'server/version.lua'
}

files {
  'web/dist/index.html',
  'web/dist/assets/*',
  'locales/*.json'
}

provide 'mz_lib'
