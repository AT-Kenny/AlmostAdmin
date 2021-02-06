
--global stuff

aa={}

aa.color={}
aa.color.blue=Color(32,164,255)
aa.color.white=Color(255,255,255)
aa.color.green=Color(164,255,32)

function aa.notify(...)
    local msg={...}

    if type(msg[1])!="table" then 
        newmsg={Color(255,255,255)}
        for i=1,#msg do
            newmsg[i+1]=msg[i]
        end
        msg=newmsg
    end
    chat.AddText(unpack(msg))

    local strmsg=""
    for _,str in pairs(msg) do
        if type(str)=="string" then
            strmsg=strmsg..str
        end
    end 
    --aa.Log(strmsg)
end

function string.IsSteamID(str) 
    return str:match("STEAM_0:%d:%d+") and true or false 
end

function string.IsIPAddress(str)
    return str:match("%d+%.%d+%.%d+%.%d") and true or false
end

//////////////////////////////
/////////////Bans/////////////
//////////////////////////////

if !file.Exists("AlmostAdmin/bans.txt","DATA") then
	file.CreateDir("AlmostAdmin")
	file.Write("AlmostAdmin/bans.txt","{}")
end
aa.bans=von.deserialize(file.Read("AlmostAdmin/bans.txt","DATA"))

local function IsBanned(steam)
    if !steam then print("no steamid given") return end
    
    local ply=von.deserialize(file.Read("at_players/"..steam:gsub(":","_").."/playerinfo.txt","DATA"))
    
    if aa.bans[steam] or ply and ply.banned then
        return true
    end
    
end

--[[hook.Add("PlayerPasswordAuth","checkbans",function(name,pass,steam,ip)
    
    if !steam then return "SteamID error" end
    
    if IsBanned(steam) then
        return "Banned"
    end

end)]]

//////////////////////////////
///////////Players////////////
//////////////////////////////

local meta=FindMetaTable("Player")

function meta:Save()
    file.Write("at_players/"..self:SteamID():gsub(":","_").."/playerinfo.txt",von.serialize(self.info))
end

function meta:Load()
    self.info=von.deserialize(file.Read("at_players/"..self:SteamID():gsub(":","_").."/playerinfo.txt","DATA"))
end

local function SavePlayerInfo()
    for k,v in pairs(player.GetHumans()) do
        v:Save()
    end
end

function GetNick(nick)
    local Nicks={}
    local longest=""
    for word in nick:gmatch("(%a+)") do
        if !word:match("(ing)$") and !word:match("(ly)$") then
            longest = #word > #longest and word or longest
        end
    end
    if longest=="" or #longest<3 then
          longest="player "..(table.Count(aa.GetAll())+1)
    end
    return longest
end

function aa.GetAll()
    local players={}
    local _,plfolders=file.Find("at_players/*","DATA")
    for k,v in pairs(plfolders) do
    	if file.Exists("at_players/"..v.."/playerinfo.txt","DATA") then
        	players[v]=von.deserialize(file.Read("at_players/"..v.."/playerinfo.txt","DATA"))
    	end
    end
    return players
end

function aa.findplayer(str,unique)
    local ply=easylua.FindEntity(str)
    if ply:IsPlayer() then
        return ply
    end
    print("searching playerinfo")
    local aaplayers=aa.GetAll()
    if str:IsSteamID() then
        for k,v in pairs(aaplayers) do
            if v.SteamID==str then
                return unique and k or v
            end
        end
    elseif str:IsIPAddress() then
        for k,v in pairs(aaplayers) do
            if v.IPAddress==str then
                return unique and k or v
            end
        end
    else
        for k,v in pairs(aaplayers) do
            if v.Nick==str then
                return unique and k or v
            end
        end
    end
    print("player not found")
end

function meta:GetNick()
    if !self:IsValid() then return "Console" end
    if self:IsBot() then return "Bot" end
    if !self.info then self.info={} end
    return (self.info.Nick or self:Nick())
end


function meta:GetValue(name,default)
    if !self:IsValid() then return end
    return self.info and (self.info[name] or default) or default
end

function meta:SetValue(name,value)
    if !self:IsValid() then return end
    --if !self.info then self.info={} end
    self.info[name]=value
end

function meta:GetAccessLevel()
    return self:GetValue("AccessLevel") or 0
end

function meta:TakeLevels(amt)
    self:SetValue("AccessLevel",self:GetValue("AccessLevel")-amt)
    self:Spawn()
end

function meta:GiveLevels(amt)
    self:SetValue("AccessLevel",self:GetValue("AccessLevel")+amt)
    self:Spawn()
end

function meta:Log(text)
    file.Append("at_players/"..self:SteamID():gsub(":","_").."/log.txt",text)
end

local function AddPlayertoTable(ply)
    
    local plinfofile="at_players/"..ply:SteamID():gsub(":","_").."/playerinfo.txt"

    if file.Exists(plinfofile,"DATA") then
    	ply.info=von.deserialize(file.Read(plinfofile,"DATA"))
    else
    	if !file.Exists("at_players","DATA") then
    		file.CreateDir("at_players")
    	end
    	file.CreateDir("at_players/"..ply:SteamID():gsub(":","_"))
    	ply.info={}
    end
    
    if !ply.info.LastJoin then
        print(ply:GetNick().." has joined for the first time.")
        ply.info.SteamID=ply:SteamID()
        ply.info.Nick=GetNick(ply:Nick())
        ply.info.IPAddress=ply:IPAddress()
        ply.info.PlayTime=0
        ply.info.Sessions=0
        ply.info.AccessLevel=0
        ply.info.LevelUps=0

    end
    print("[LastJoin] "..ply:Nick().." "..math.floor((os.time()-(ply.info.LastJoin or os.time()))/60))
    ply:SetValue("LastJoin",os.time())
    ply:SetValue("Sessions",ply:GetValue("Sessions",0)+1)
    if ply.info.IPAddress!=ply:IPAddress() then
        ply:Log("IP Address changed from "..ply.info.IPAddress.." to "..ply:IPAddress())
        ply:SetValue("IPAddress",ply:IPAddress())
    end

    ply:Save()

end

local function SetTeam(ply)
    if !(ply:GetAccessLevel()) or ply:GetAccessLevel()<0 then
        ply:SetTeam(4)
    elseif (ply:GetValue("AccessLevel",0) or 0)>=90 then
        ply:SetTeam(1)
    elseif (ply:GetValue("AccessLevel",0) or 0)>=80 then
        ply:SetTeam(2)
    else
        ply:SetTeam(3)
    end
end

function Loadout(ply)
    if ply:GetAccessLevel()<0 then return true end
    if ply:IsValid() then
        ply:Give("weapon_crowbar")
        ply:Give("weapon_physgun")
        ply:Give("weapon_physcannon")
        ply:Give("gmod_camera")
        ply:Give("gmod_tool")
        ply:SelectWeapon("weapon_physcannon")
        return true
    end
end

hook.Add("PlayerLoadout","ATPlayerLoadout",Loadout)

local function AA_PlayerInitialSpawn(ply)
    if ply:IsValid() then
        ply.GreetingPending=true
    end

    timer.Simple(1,function() Loadout(ply) end)
  
end

local function AA_PlayerSpawn(ply)
    if ply.GreetingPending and !ply:IsBot() then
        AddPlayertoTable(ply)
        ply.GreetingPending=false
        Loadout(ply)
        SetTeam(ply)
        local tcolor = team.GetColor(ply:Team())
    	local teamcolor = Color(tcolor.r,tcolor.g,tcolor.b,255)
    	chat.AddText(teamcolor,ply:Nick(),aa.color.white," has joined the game.")
    else
    	SetTeam(ply)
    end

    ply:SetNetworkedInt("Level",ply:GetAccessLevel())
    if ply.god then ply:GodEnable() end
end

hook.Add("PlayerInitialSpawn","AA_PlayerInitialSpawn",AA_PlayerInitialSpawn)
hook.Add("PlayerSpawn","AA_PlayerSpawn",AA_PlayerSpawn)

local function PlayTime(ply)
    print("playtime")
    if ply:IsValid() and !ply:IsBot() then
        print("saving playtime: "..math.floor(ply:GetValue("PlayTime")+(ply:TimeConnected()/60)))
        ply:SetValue("PlayTime",math.floor(ply:GetValue("PlayTime")+(ply:TimeConnected()/60)))
        ply:Save()
    end
end

hook.Add("PlayerDisconnected","AAPlayerDisconnected",PlayTime)

timer.Create("SavePlayerTable",300,0,function()
    if #player.GetHumans()>0 then
        SavePlayerInfo()
    end
end)

hook.Add("ShutDown","SavePlayerInfo_Shutdown",function()
    SavePlayerInfo()
end)


function meta:IsAdmin()
    return self:GetAccessLevel()>=80 or false
end

function meta:IsSuperAdmin()
    return self:GetAccessLevel()>=90 or false
end


//////////////////////////////
///////Prop Protection////////
//////////////////////////////

aa.AddCount = meta.AddCount
function meta:AddCount(type,ent)
    ent.ATOwner=self
    return aa.AddCount(self,type,ent)
end

aa.CleanupAdd = cleanup.Add
function cleanup.Add(ply,type,ent)
    if ent then ent.ATOwner=ply end
    return aa.CleanupAdd(ply,type,ent)
end

function meta:Cleanup()
    local count=0
    for k,v in pairs(ents.GetAll()) do
        if v.ATOwner==self then
            v:Remove()
            count=count+1
        end
    end
    print("Removed "..count.." ents.")
end

//////////////////////////////
///////////Logging////////////
//////////////////////////////

if !file.Exists("aa_logs","DATA") then
    file.CreateDir("aa_logs")
end

function aa.Log(text)
    if !file.Exists("aa_logs/"..os.date("%m-%d-%y"),"DATA") then
	   file.CreateDir("aa_logs/"..os.date("%m-%d-%y"))
    end
    local logfile="aa_logs/"..os.date("%m-%d-%y").."/".."0.txt"
    local files=file.Find("aa_logs/"..os.date("%m-%d-%y").."/".."*.txt","DATA")
    if (#files>0) then logfile="aa_logs/"..os.date("%m-%d-%y").."/"..(#files-1)..".txt" end

    if file.Size(logfile,"DATA")>200000 then
        logfile="aa_logs/"..os.date("%m-%d-%y").."/"..(#files)..".txt"
    end
    aa_logfile=logfile
    file.Append(logfile,"["..os.date("%H:%M:%S").."]"..text.."\n")
end

local function PlyLogStr(ply)
    if ply:IsValid() then
        return ply:Nick().."|"..ply:GetNick().."["..ply:SteamID().."]" 
    end
end

hook.Add("InitPostEntity","AA_LogInit",function()
    aa.Log("\n\n=== "..game.GetMap().." ===\n")
end)

hook.Add("PlayerConnect","AA_LogPlayerConnect",function(name,address)
    aa.Log(name.." connected from "..address)
end)

hook.Add("PlayerInitialSpawn","AA_LogInitialSpawn",function(ply)
    aa.Log(PlyLogStr(ply).." joined the game.")
    print(PlyLogStr(ply).." joined the game.")
end)

hook.Add("PlayerDisconnected","AA_LogDisconnect",function(ply)
    aa.Log(PlyLogStr(ply).." disconnected.")
    print(PlyLogStr(ply).." disconnected.")
end)

hook.Add("PlayerDeath","AA_LogDeath",function(victim,wep,killer)
    if !killer:IsPlayer() then
        aa.Log(victim:Nick().." was killed by "..killer:GetClass())
        print(victim:Nick().." was killed by "..killer:GetClass())
    elseif victim!=killer then
        aa.Log(killer:Nick().." killed "..victim:Nick().." with "..wep:GetClass())
        print(killer:Nick().." killed "..victim:Nick().." with "..wep:GetClass())
    end
end)

hook.Add("PlayerSay","AA_LogChat",function(ply,txt)
    aa.Log(ply:GetNick()..": "..txt)
end)

hook.Add("CanTool","AA_LogTool",function(pl,tr,tool)
    if tool!="inflator" and tool!="paint" then
        aa.Log(PlyLogStr(pl).." used "..tool.." on "..tr.Entity:GetClass())
        print(PlyLogStr(pl).." used "..tool.." on "..tr.Entity:GetClass())
    end
end)




//////////////////////////////
///////////Commands///////////
//////////////////////////////

local function GetArguments(txt)
    local args = {}
    local first = true
    
    for match in string.gmatch( txt, "[^ ]+" ) do
        if ( first ) then first = false else
            table.insert( args, match )
        end
    end
    
    return args
end

local cmds={}

function aa.addcmd(cmd,lvl,func)
    cmds[cmd]={}
    cmds[cmd].callback=func
    cmds[cmd].access=lvl or 0

    concommand.Add("at_"..cmd,chatcmds)
end

local function chatcmds(ply,txt)

    if txt:Left(1)=="!" or txt:Left(1)=="/" then
        if (ply.aalastcommand or 0)+1>CurTime() then return end
        local command=(txt:match("%w+") or ""):lower()
        local args=GetArguments(txt)
        local target=args[1]
        if target then
            table.remove(args,1)
        end

        aa.Log(ply:Nick().." used command "..command.." with args "..string.Implode(" ",args))
        ply.aalastcommand=CurTime()

        if cmds[command] and ply:GetAccessLevel()>=cmds[command].access then
            local _,err=pcall(function() cmds[command].callback(ply,target,args) end)
            if err then print(err) end
            return ""
        end
    end
end

hook.Add("PlayerSay","chatcmd",chatcmds)

-- rehook
timer.Create("aa_rehook",60,0,function()
    hook.Add("PlayerSay","chatcmd",chatcmds)
end)

aa.addcmd("kick",75,function(ply,target,args)
    local kickee=easylua.FindEntity(target)
    local reason="no reason given"
    if args!="" then
        reason=string.Implode(" ",args)
    end
    if kickee:IsPlayer() then
        if ply:GetAccessLevel()>kickee:GetAccessLevel() or kickee:IsBot() then
            for k,v in pairs(ents.GetAll()) do
                if v.ATOwner==kickee then
                    v:Remove()
                end
            end
            chat.AddText(team.GetColor(kickee:Team()),kickee:Nick(),aa.color.white," was kicked by ",team.GetColor(ply:Team()),ply:Nick())
            kickee:Kick(reason)
            print(kickee:Nick().." has been kicked by "..ply:Nick())
            
        else
            print("target has higher access level than user")
        end
    else
        print("target is not a player")
    end
end)

aa.addcmd("ban",80,function(ply,target,args)
    print(target)
    if target!="" then
        local banee=easylua.FindEntity(target)
        local time=(tonumber(args[1]) or 5)
        if args[2] then
            reason=string.Implode(" ",args):gsub(args[1],"")
        else
            reason="no reason given"
        end
        --0=permaban
        
        if banee:IsPlayer() then
            if ply:GetAccessLevel()>banee:GetAccessLevel() then
                for k,v in pairs(ents.GetAll()) do
                    if v.ATOwner==banee then
                        v:Remove()
                    end
                end
                banee:SetValue("AccessLevel",-1)
                banee.info.banned={time=time,reason=reason}
                banee:Save()
                banee:Ban(time>0 and time or 5,reason or "no reason given")
                banee:Kick("Banned for "..time.." minutes.")
            end
        else
            print("target not found, searching playerinfo")
            local banee=aa.findplayer(target,true)
            local playertable=aa.GetAll()[banee]
            if banee and aa.GetAll()[banee] then
                playertable.AccessLevel=-1
                file.Write("at_players/"..banee.."/playerinfo.txt",von.serialize(playertable))
                chat.AddText(aa.color.white,playertable.Nick.." has been sent to purgatory")
            elseif target:upper():IsSteamID() then
                aa.bans[target]={time=time,reason=reason}
                file.Write("AlmostAdmin/bans.txt",von.serialize(aa.bans))
            else
                print("player not found in playerinfo")
            end 
        end
    end
end)

aa.addcmd("unban",80,function(ply,steam)
    if !steam then return end
    local plfile="at_players/"..steam:gsub(":","_").."/playerinfo.txt"
    if file.Exists(plfile) then
        local plinfo=von.deserialize(file.Read(plfile,"DATA"))
        plinfo.banned=nil
        chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," unbanned ",aa.color.green,plinfo.Nick)
        file.Write(plfile,von.serialize(plinfo))
    elseif aa.bans[steam] then
        aa.bans[steam]=nil
    else
        print(steam.." isn't banned.")
    end
end)

aa.addcmd("map",75,function(ply,target,time)
    local map=target or "gm_construct"
    local time=time[1] or 1
    if !Alice.maps[map] or !file.Exists("maps/"..map..".bsp","GAME") then
        local maplist={}
        for k,v in pairs(Alice.maps) do
            if file.Exists("maps/"..k..".bsp","GAME") and k:find(map) or table.HasValue(Alice.maps[k].tags,map) or map=="*" then
                table.insert(maplist,k)
            end
        end
        if #maplist>0 then
            map=table.Random(maplist)
        end  
    end
    chat.AddText(aa.color.white,"Changing map to ",aa.color.blue,map,aa.color.white,((tonumber(time)>1) and " in "..time.." seconds." or ""))
    timer.Simple(time,function()
        game.ConsoleCommand("changelevel "..map.."\n")
    end)
end)

aa.addcmd("reload",80,function(ply)
    local map=game.GetMap()
    chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," reloaded the map")
    timer.Simple(1,function()
        game.ConsoleCommand("changelevel "..map.."\n")
    end)
end)


aa.addcmd("cleanup",75,function(ply,target,args)
    local pl=ply
    if target then pl=easylua.FindEntity(target) end
    if pl:IsPlayer() and (ply:GetAccessLevel()>=pl:GetAccessLevel()) then
        pl:Cleanup()
        pl.at_cleanedup=SysTime()
    end
end)

-- save player if found and run next command on them

aa.addcmd("find",25,function(ply,target)
    if !target or target=="" then return end
    local found=aa.findplayer(target)
    if !found then return end
    chat.AddText(aa.color.white,found.info and found.info.Nick or found.Nick)
end)

aa.addcmd("god",1,function(ply,target)
    target=target and easylua.FindEntity(target) or ply
    if !target:IsPlayer() then return end
    if ply:GetAccessLevel()>=target:GetAccessLevel() then
        if !target.god then
            target:GodEnable()
            target.god=true
            chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," enabled godmode for ",team.GetColor(target:Team()),target:Nick())
        else
            target:GodDisable()
            target.god=false
            chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," disabled godmode for ",team.GetColor(target:Team()),target:Nick())
        end
    end
end)

aa.addcmd("gag",75,function(ply,target)
    target=target and easylua.FindEntity(target) or ply
    if !target:IsPlayer() then return end
    if ply:GetAccessLevel()>=target:GetAccessLevel() then
        if !target.gagged then
            target.gagged=true
            chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," gagged ",team.GetColor(target:Team()),target:Nick())
        else
            target.gagged=false
            chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," ungagged ",team.GetColor(target:Team()),target:Nick())
        end
    end
end)

aa.addcmd("spawn",75,function(ply,target)
    target=target and easylua.FindEntity(target) or ply
    if !target:IsPlayer() then return end
    if ply:GetAccessLevel()>=target:GetAccessLevel() then
        target:Spawn()
        chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," respawned ",team.GetColor(target:Team()),target:Nick())
    end
end)

aa.addcmd("slay",75,function(ply,target,args)
    local pl=ply
    if target then pl=easylua.FindEntity(target) end
    if pl:IsPlayer() and (ply:GetAccessLevel()>=pl:GetAccessLevel()) then
        pl:Kill()
    end
end)

aa.addcmd("lua",99,function(ply,first,args)
    --borrowed from Evolve
    local code=first..table.concat(args," ")
    if ( #code > 0 ) then
        local f, a, b = CompileString( code, "" )

        if ( !f ) then
            print("Syntax error! Check your script!") 
            return
        end

        local status, err = pcall( f )
    end
end)

//////////////////////////////
///////////Entities///////////
//////////////////////////////

--move this section to prop protection file

hook.Add("PlayerSpawnedProp","AA_SpawnedHook",function(ply,mdl,ent) 
    ent.ATOwner=ply
    aa.Log(PlyLogStr(ply).." spawned prop "..mdl)
end)
hook.Add("PlayerSpawnedSENT","AA_SpawnedHook",function(ply,ent) 
    ent.ATOwner=ply 
    aa.Log(PlyLogStr(ply).." spawned sent "..ent:GetClass())
end)
hook.Add("PlayerSpawnedNPC","AA_SpawnedHook",function(ply,ent) 
    ent.ATOwner=ply
    aa.Log(PlyLogStr(ply).." spawned npc "..ent:GetClass())
end)
hook.Add("PlayerSpawnedVehicle","AA_SpawnedHook",function(ply,ent) 
    ent.ATOwner=ply 
    aa.Log(PlyLogStr(ply).." spawned vehicle "..ent:GetClass())
end)
hook.Add("PlayerSpawnedEffect","AA_SpawnedHook",function(ply,mdl,ent) 
    ent.ATOwner=ply 
    aa.Log(PlyLogStr(ply).." spawned effect "..mdl)
end)
hook.Add("PlayerSpawnedRagdoll","AA_SpawnedHook",function(ply,mdl,ent) 
    ent.ATOwner=ply 
    aa.Log(PlyLogStr(ply).." spawned ragdoll "..mdl)
end)


hook.Add("PlayerSpawnProp","AASpawnHook",function(ply,mdl,ent) if ply:GetAccessLevel()<0 or (ply.at_cleanedup and SysTime()-30<ply.at_cleanedup) then return false end end)
hook.Add("PlayerSpawnSENT","AASpawnHook",function(ply,ent) if ply:GetAccessLevel()<0 or (ply.at_cleanedup and SysTime()-30<ply.at_cleanedup) then return false end end)
hook.Add("PlayerSpawnNPC","AASpawnHook",function(ply,ent) if ply:GetAccessLevel()<0 or (ply.at_cleanedup and SysTime()-30<ply.at_cleanedup) then return false end end)
hook.Add("PlayerSpawnVehicle","AASpawnHook",function(ply,ent) if ply:GetAccessLevel()<0 or (ply.at_cleanedup and SysTime()-30<ply.at_cleanedup) then return false end end)
hook.Add("PlayerSpawnEffect","AASpawnHook",function(ply,mdl,ent) if ply:GetAccessLevel()<0 or (ply.at_cleanedup and SysTime()-30<ply.at_cleanedup) then return false end end)
hook.Add("PlayerSpawnRagdoll","AASpawnHook",function(ply,mdl,ent) if ply:GetAccessLevel()<0 or (ply.at_cleanedup and SysTime()-30<ply.at_cleanedup) then return false end end)

function ATPropCleanup(target)
    for _,ent in pairs(ents.GetAll()) do
        if ent.ATOwner==target then
            ent:Remove()
        end
    end
end


--this needs to be cleaned up or removed
hook.Add("CanTool","AA_CanTool",function(ply,tr,tool)

    --don't allow banned players to use tools
    if ply:GetAccessLevel()<0 then return false end

    --block buggy tools
    local restricted={"ignite","wire_detcord","wire_igniter"}
    if table.HasValue(restricted,tool) then return false end

    local ent=tr.Entity

    --allow all players to remove NPCs
    if tool=="remover" and ent:IsNPC() then
        return true
    end

    --block crash exploits
    local breakableprops={
    "FurnitureCupboard",
    "FurnitureDrawer",
    "FurnitureDresser",
    "gascan001a.mdl",
    "explosive",
    "shelfunit01a",
    "Furniture_shelf01a",
    "cardboard_box",
    "wood_crate",
    "wood_pallet",
    "cafeteria_bench",
    "cafeteria_table",
    "dock_plank",
    "wood_fence",
    "props_phx/ball",
    "mk-82",
    "cannonball",
    "torpedo",
    "amraam",
    "flakshell",
    "ww2bomb",
    "wood",
    "melon",
    "egg"
    }
    if tool=="motor" or tool=="slider" then
        for k,v in pairs(breakableprops) do
            if ent:GetModel():find(v) then
                return false
            end
        end
    end

    if tool=="thruster" and ent:GetClass()=="prop_ragdoll" then return false end
    if tool=="nocollideall_multi" and ent:GetClass()=="prop_vehicle_jeep" then return false end
    if ent:GetModel()=="models/props/de_tides/gate_large.mdl" then return false end
    if tool=="motor" and ent:IsWorld() then return false end
    --if tool=="duplicator" then return false end
end)

local function RestrictSWEPs(p,w)
    if p:GetAccessLevel()<0 then return false end
    if #player.GetAll()>1 then
        local wep=w:GetClass()
        local allowed={"laserpointer","remotecontroller","weapon_physgun","weapon_physcannon","gmod_camera","gmod_tool","weapon_crowbar"}
        if !table.HasValue(allowed,wep) and !p:IsAdmin() and !wep:find("pcmod") then
            return false
        end
    end
    return true
end


hook.Add("PlayerSpawnSENT","RestrictSENTS",function(ply,ent)
    --return ply:IsAdmin()
end)

hook.Add("PlayerCanPickupWeapon","RestrictSWEPs",RestrictSWEPs)

hook.Add("PhysgunPickup","PlayerPickup",function(ply,pl)
    if pl:IsPlayer() then
        if ply:IsAdmin() and (ply:GetAccessLevel()>pl:GetAccessLevel()) or ply:GetAccessLevel()>0 and pl:GetAccessLevel()<0 then
            return true
        end
    end
end)

hook.Add("PlayerUse","Purgatory",function(ply)
    return ply:GetAccessLevel()>=0
end)

hook.Add("PlayerNoClip","Purgatory",function(ply)
    return ply:GetAccessLevel()>=0
end)
hook.Add("PlayerCanHearPlayersVoice","Gag",function(listener,talker)
    return !talker.gagged
end)


  ///////////////////////////////////
 /////////////TEMPORARY/////////////
///////////////////////////////////

local function LevelUp(ply)
	print("LevelCheck "..ply:Nick())
    if ply:IsValid() and !ply:IsBot() and ply.info and ply.info.PlayTime then
        local playtime=(ply:GetValue("PlayTime")+ply:TimeConnected())/60
        print("playtime: "..playtime)
        local levelups=ply:GetValue("LevelUps",0)
        print("levelups: "..levelups)
    
        local leveltime=0
        local multiplier=1
        
        if furryfinder then
            if ply:IsGroupOfficer("103582791430342520") then
                multiplier=10
            elseif ply:IsGroupMember("103582791430342520") then
                multiplier=2
            end
        end

        if file.Read("AlmostAdmin/multiplier.txt","DATA"):match(ply:SteamID()) then
            multiplier=60
        end

        for i=0,levelups do
            --leveltime=leveltime+math.floor(((levelups/12)^2+1)*(60/multiplier))
            leveltime=leveltime+math.Clamp(math.floor((0.2*levelups)^2+levelups+(30/multiplier)),0,1000)
        end
        print(playtime.." "..leveltime)
    
        if playtime>leveltime and ply:GetValue("AccessLevel",0)<99 then
            ply:SetValue("AccessLevel",ply:GetValue("AccessLevel",0)+1)
            ply:SetValue("LevelUps",ply:GetValue("LevelUps",0)+1)
            chat.AddText(team.GetColor(ply:Team()),ply:Nick(),aa.color.white," is now level ",team.GetColor(ply:Team()),tostring(ply:GetValue("AccessLevel")))
            print(ply:Nick().." is now level "..tostring(ply:GetValue("AccessLevel")))
	    --the line below needs to be updated
            --chat.AddText(aa.color.white,"Hours to next level: ",team.GetColor(ply:Team()),tostring(math.floor((ply:GetValue("AccessLevel")/12)^2+1)))
            file.Append("LevelUp.txt",os.time().." "..ply:Nick()..": "..ply:GetValue("AccessLevel").." - "..ply:GetValue("LevelUps").."\n")
        end
    end
end

hook.Add("PlayerSpawn","LevelUp",LevelUp)


aa.addcmd("e2",75,function(ply,args)
    local e2s=ents.FindByClass("gmod_wire_expression2")
    local mode=args and args[1] or ""
    if #e2s==0 then print("no e2s found") return end
    
    if mode=="s" then
        for k,v in pairs(e2s) do
            print(E2Lib.getOwner(v):Nick())
            print(v.original)
        end
    elseif mode=="r" then
        for k,v in pairs(e2s) do
            v:Remove()
        end
    end
end)

--mysql support
    --use txt files if mysql is down
