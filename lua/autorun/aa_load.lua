include('aa_shared.lua')
include('easylua.lua')
include('von.lua')

if CLIENT then
    include('client/aa_base.lua')
end

if SERVER then
    AddCSLuaFile('autorun/aa_load.lua')
    AddCSLuaFile('aa_shared.lua')
    AddCSLuaFile('client/aa_base.lua')
    AddCSLuaFile('easylua.lua')
    AddCSLuaFile('von.lua')
    
    include('server/aa_base.lua')
	--include('server/irc.lua')
    --include('server/radio.lua')   
    --uncomment this one when gm_luaerror is fixed
    --include('server/errors.lua')
end