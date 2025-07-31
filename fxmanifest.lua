game 'gta5'
fx_version 'cerulean'
lua54 'yes'
author 'ahezu'
description 'simple and user-friendly outfit management system'

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
}

client_script 'cl_garderoba.lua'


server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'sv_garderoba.lua'
}	
