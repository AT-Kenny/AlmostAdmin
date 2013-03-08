easylua = {} local s = easylua

local function compare(a, b)

	if a == b then return true end
	if a:find(b, nil, true) then return true end
	if a:lower() == b:lower() then return true end
	if a:lower():find(b:lower(), nil, true) then return true end

	return false
end

if CLIENT then
	function easylua.PrintOnServer(...)
		local args = {...}
		local new = {}

		for key, value in pairs(args) do
			table.insert(new, luadata.ToString(value))
		end

		RunConsoleCommand("easylua_print", unpack(new))
	end
end

if SERVER then
	function easylua.CMDPrint(ply, cmd, args)
		args = table.concat(args, ", ")

		print(Format("[easylua %s] : %s", ply:Nick(), args))
	end

	concommand.Add("easylua_print", easylua.CMDPrint)
end

function easylua.FindEntity(str)
	str = tostring(str)
	if not str then return NULL end

	-- unique id
	local ply = player.GetByUniqueID(str)
	if ply and ply:IsPlayer() then
		return ply
	end

	-- steam id
	if str:find("STEAM") then
		for key, _ply in pairs(player.GetAll()) do
			if _ply:SteamID() == str then
				return _ply
			end
		end
	end

	if tonumber(str) then
		ply = Entity(tonumber(str))
		if ply:IsValid() then
			return ply
		end
	end

	-- community id
	if #str == 17 then

	end

	-- ip
	if str:find("%d+%.%d+%.%d+%.%d") then
		for key, _ply in pairs(player.GetAll()) do
			if _ply:IPAddress():find(str) then
				return _ply
			end
		end
	end

	for key, ent in pairs(ents.GetAll()) do

		if ent.GetName and compare(ent:GetName(), str) then
			return ent
		end

		if compare(ent:GetClass(), str) then
			return ent
		end

		if key == tonumber(str) then return ent end
		if key == tonumber(str:sub(2)) then return ent end

		if ent:GetModel() and compare(ent:GetModel(), str) then
			return ent
		end
	end

	return ents.FindByClass(str)[1] or NULL
end

function easylua.CreateEntity(class)
	local mdl = "error.mdl"

	if IsEntity(class) and class:IsValid() then
		this = class
	elseif class:find(".mdl", nil, true) then
		mdl = class
		class = "prop_physics"

		this = ents.Create(class)
		this:SetModel( 	)
	else
		this = ents.Create(class)
	end

	this:Spawn()
	this:SetPos(there + Vector(0,0,this:BoundingRadius() * 2))
	this:DropToFloor()
	this:PhysWake()

	undo.Create(class)
		undo.SetPlayer(me)
		undo.AddEntity(this)
	undo.Finish()
end

function easylua.CopyToClipboard(var, ply)
	ply = ply or me
	if luadata then
		local str = luadata.ToString(var)

		if not str and IsEntity(var) and var:IsValid() then
			if var:IsPlayer() then
				str = Format("player.GetByUniqueID(--[[%s]] %q)", var:GetName(), var:UniqueID())
			else
				str = Format("Entity(%i)", var:EntIndex())
			end

		end

		if CLIENT then
			SetClipboardText(str)
		end

		if SERVER then
			ply:SendLua(Format("SetClipboardText(%q)", str))
		end
	end
end

function easylua.Start(ply)
	ply = ply or CLIENT and LocalPlayer() or nil

	local vars = {}
		local trace = ply:GetEyeTrace()

		if trace.Entity:IsWorld() then
			trace.Entity = NULL
		end

		vars.me = ply
		vars.there = trace.HitPos
		vars.here = trace.StartPos
		vars.dir = ply:GetAimVector()
		vars.length = trace.StartPos:Distance(trace.HitPos)
		vars.this = trace.Entity
		vars.trace = trace
		vars.wep = ply:GetActiveWeapon()
		vars.copy = s.CopyToClipboard
		vars.create = s.CreateEntity

		if vars.this:IsValid() then
			vars.phys = vars.this:GetPhysicsObject()
			vars.model = vars.this:GetModel()
		end

		vars.E = s.FindEntity
		s.vars = vars
	table.Merge(_G, vars)
end

function easylua.End()
	if s.vars then
		for key, value in pairs(s.vars) do
			_G[key] = nil
		end
	end
end

function easylua.RunLua(ply, code)
	easylua.Start(ply)

		local header = ""

		for key, value in pairs(s.vars) do
			header = header .. Format("local %s = %s ", key, key)
		end

		code = header .. "\n" .. code

		local func = CompileString(code, tostring(ply))
		if func then
			local noerr, errormsg = pcall(func)

			if noerr == false then
				ErrorNoHalt("Script from '"..tostring(ply).."' errored: "..tostring(errormsg).."\n")
			end
		end
	easylua.End()
end

function easylua.StartWeapon(classname)
	_G.SWEP = {Primary = {}, Secondary = {}}

	SWEP.Base = "weapon_cs_base"

	SWEP.ClassName = classname or "no_swep_name_" .. me:Nick() .. "_" .. me:UniqueID()
end

function easylua.EndWeapon(spawn, reinit)
	weapons.Register(SWEP, SWEP.ClassName, true)

	for key, entity in pairs(ents.FindByClass(SWEP.ClassName)) do
		if entity:GetTable() then table.Merge(entity:GetTable(), SWEP) end
		if reinit then
			entity:Initialize()
		end
	end

	if SERVER and spawn then
		SafeRemoveEntity(me:GetWeapon(SWEP.ClassName))
		local me = me
		local class = SWEP.ClassName
		timer.Simple(0.2, function() if me:IsPlayer() then me:Give(class) end end)
	end

	SWEP = nil
end

function easylua.StartEntity(classname)
	_G.ENT = {}

	ENT.Type = "anim"
	ENT.Base = "base_anim"

	ENT.Model = Model("models/props_borealis/bluebarrel001.mdl")
	ENT.ClassName = classname or "no_ent_name_" .. me:Nick() .. "_" .. me:UniqueID()
end

function easylua.EndEntity(spawn, reinit)
	scripted_ents.Register(ENT, ENT.ClassName, true)

	for key, entity in pairs(ents.FindByClass(ENT.ClassName)) do
		table.Merge(entity:GetTable(), ENT)
		if reinit then
			entity:Initialize()
		end
	end

	if SERVER and spawn then
		create(ENT.ClassName)
	end

	ENT = nil
end

do -- all
	local META = {}

	function META:__index(key)
		return function(_, ...)
			local args = {}

			for _, ent in pairs(ents.GetAll()) do
				if (not self.func or self.func(ent)) then
					if type(ent[key]) == "function" or ent[key] == "table" and type(ent[key].__call) == "function" and getmetatable(ent[key]) then
						table.insert(args, {ent = ent, args = (ent[key](ent, ...))})
					else
						ErrorNoHalt("attempt to call field '" .. key .. "' on ".. tostring(ent) .." a " .. type(ent[key]) .. " value\n")
					end
				end
			end

			return args
		end
	end

	function META:__newindex(key, value)
		for _, ent in pairs(ents.GetAll()) do
			if not self.func or self.func(ent) then
				ent[key] = value
			end
		end
	end



	function CreateAllFuncton(func)
		return setmetatable({func = func}, META)
	end

	all = CreateAllFuncton(function(v) return v:IsPlayer() end)
	props = CreateAllFuncton(function(v) return v:GetClass() == "prop_physics" end)
	props = CreateAllFuncton(function(v) return util.IsValidPhysicsObject(vm) end)
	bots = CreateAllFuncton(function(v) return v:IsBot() end)
	these = CreateAllFuncton(function(v) return easylua and table.HasValue(constraint.GetAllConstrainedEntities(this), v) end)
end

hook.Add("PreLuaDevRun", "easylua_luadev", function(script, info,extra)
	easylua.Start(extra.ply)
end)

hook.Add("PostLuaDevRun", "easylua_luadev", function(script, info,extra)
	easylua.End()
end)