-- Utopia Games - Slashers
--
-- @Author: Garrus2142
-- @Date:   2017-07-25 16:15:48
-- @Last Modified by:   Daryl_Winters
-- @Last Modified time: 2017-08-10T15:08:45+02:00

local GM = GM or GAMEMODE
local MAPS_LIST

util.AddNetworkString("sls_round_PreStart")
util.AddNetworkString("sls_round_PostStart")
util.AddNetworkString("sls_round_StartWaitingPolice")
util.AddNetworkString("sls_round_StartEscape")
util.AddNetworkString("sls_round_OnTeamWin")
util.AddNetworkString("sls_round_End")
util.AddNetworkString("sls_round_Update")
util.AddNetworkString("sls_round_WaitingPlayers")
util.AddNetworkString("sls_round_PlayerConnect")
util.AddNetworkString("sls_round_SetupCamera")
util.AddNetworkString("sls_round_Camera")
util.AddNetworkString("sls_round_UpdateEndTime")

function GM.ROUND:ViewInitCam(enable)
	GM.ROUND.CameraEnable = enable
	net.Start("sls_round_Camera")
		net.WriteBool(GM.ROUND.CameraEnable)
	net.Broadcast()

	if enable then
		for _, v in ipairs(player.GetAll()) do
			if IsValid(v) then
				v:SetPos(GM.ROUND.CameraPos)
			end
		end
	end
end

function GM.ROUND:Start(forceKiller)
	GM.ROUND.Survivors = {}
	GM.ROUND.Killer = nil
	GM.ROUND.EndTime = nil
	GM.ROUND.WaitingPolice = false
	GM.ROUND.Escape = false
	GM.ROUND.NextStart = nil
	-- Synchronisation flags: PostStart only fires when BOTH sides are ready.
	-- Prevents the cinematic from overlapping the survivor class-select menu.
	GM.ROUND.KillerReady    = false
	GM.ROUND.SurvivorsReady = false

	local playersCount = 0
	for _, v in ipairs(player.GetAll()) do
		if v.initialKill then
			playersCount = playersCount + 1
		end
	end
	if playersCount < GetConVar("slashers_round_min_player"):GetInt() then
		GM.ROUND.WaitingPlayers = true
		net.Start("sls_round_WaitingPlayers")
			net.WriteBool(true)
		net.Broadcast()
		return false
	end

	if GM.ROUND.Active then
		GM.ROUND:End(true)
	end

	hook.Run("sls_round_PreStart")
	net.Start("sls_round_PreStart")
	net.Broadcast()

	-- Setup players
	if IsValid(forceKiller) then
		GM.ROUND.Killer = forceKiller
	else
		GM.ROUND.Killer = GM.ROUND:ChooseKiller()
	end

	local i = 0
	for _, v in ipairs(player.GetAll()) do
		if i > 10 then break end
		if GM.ROUND.Killer != v then
			table.insert(GM.ROUND.Survivors, v)
		end
		i = i + 1
	end
	GM.ROUND:ViewInitCam(false)

	local spawnpoints = ents.FindByClass("info_player_counterterrorist")
	for _, v in ipairs(GM.ROUND.Survivors) do
		v:Spawn()
		v:SetPos(table.Random(spawnpoints):GetPos())
		-- Freeze survivors immediately on spawn so they cannot run around the map
		-- during the killer's character/weapon selection phase.
		-- MakePopup() in the Derma UI allows UI interaction while the entity is frozen,
		-- so freezing here is both correct and safe.
		-- They will be unfrozen by the centralised sls_round_PostStart hook in sv_setup.lua
		-- after the cinematic intro window expires.
		v:Freeze(true)
		v:SetNWBool("Escaped", false)
	end
	GM.CLASS:SetupSurvivors()

	if IsValid(GM.ROUND.Killer) then
		GM.ROUND.Killer:Spawn()
		GM.ROUND.Killer:SetupKiller()
		GM.ROUND.Killer:SetPos(table.Random(ents.FindByClass("info_player_terrorist")):GetPos())
		GM.ROUND.Killer:Freeze(true)
		-- BLACKOUT BYPASS: disabled ScreenFade for killer
		-- GM.ROUND.Killer:ScreenFade(SCREENFADE.IN, Color(0, 0, 0), 2, GM.CONFIG["round_freeze_start"] - 2)
		GM.ROUND.Killer:SetNWBool("Escaped", false)
	end

	game.CleanUpMap()

	GM.ROUND.Active = true
	GM.ROUND.Count = GM.ROUND.Count + 1
	GM.ROUND.EndTime = CurTime() + GM.CONFIG["round_freeze_start"] + GetConVar("slashers_duration_base"):GetFloat() + (#GM.ROUND.Survivors * GetConVar("slashers_duration_addsurv"):GetFloat())

	-- Survivors are frozen above at spawn time and will be unfrozen by the
	-- centralised sls_round_PostStart hook in sv_setup.lua after the cinematic.

	-- Trigger the Setup Pipeline for the Killer.
	-- Bots never interact with net messages, so their entire pipeline is driven
	-- server-side here. Human killers receive the character-select UI as normal.
	if IsValid(GM.ROUND.Killer) then
		if GM.ROUND.Killer:IsBot() then
			-- ── Bot killer: simulate the full setup pipeline automatically ──────
			timer.Simple(0.5, function()
				local killer = GM.ROUND.Killer
				if not IsValid(killer) then return end

				-- 1. Pick a random character from the registry.
				local charKeys = table.GetKeys(GAMEMODE.KillerCharacters)
				local charKey  = charKeys[math.random(#charKeys)]
				local charData = GAMEMODE.KillerCharacters[charKey]

				if charData then
					killer:SetModel(charData.model)
					killer:SetupHands()
					killer:SetWalkSpeed(charData.walk)
					killer:SetRunSpeed(charData.run)
					GAMEMODE.MAP.Killer       = GAMEMODE.MAP.Killer or {}
					GAMEMODE.MAP.Killer.Name  = charData.name
					GAMEMODE.MAP.Killer.Model = charData.model
				end
				killer.ChosenCharacter    = charKey
				killer.HasChosenCharacter = true

				-- 2. Broadcast character choice so HUD/scoreboard updates.
				net.Start("sls_killer_sync_character")
					net.WriteString(charKey)
				net.Broadcast()
				print("[Setup-Pipeline] Bot killer auto-selected character: " .. tostring(charKey))

				-- 3. CRITICAL: Fire sls_surv_KillerCharSelected so survivors
				--    receive their class-select menu. Without this hook the
				--    survivor menu never opens and the round soft-locks.
				hook.Run("sls_surv_KillerCharSelected", killer)

				-- 4. Pick and give a default weapon.
				local allowed     = GAMEMODE.CONFIG["killer_weapons"]
				local weaponClass = (allowed and allowed[1]) or "tfa_nmrih_machete"
				killer:Give(weaponClass)
				killer:SelectWeapon(weaponClass)
				killer.InitialWeapon   = weaponClass
				killer.HasChosenWeapon = true
				print("[Setup-Pipeline] Bot killer auto-equipped weapon: " .. weaponClass)

				-- 5. Signal that the killer side is done. PostStart only fires once
				--    the survivors are also ready (CheckSetupComplete barrier).
				GAMEMODE.ROUND.KillerReady = true
				GAMEMODE.ROUND:CheckSetupComplete()
			end)
		else
			-- ── Human killer: open the character-select UI as normal ─────────
			timer.Simple(0.5, function()
				if IsValid(GM.ROUND.Killer) then
					net.Start("sls_killer_opencharselect")
					net.Send(GM.ROUND.Killer)
					print("[Setup-Pipeline] Character selection dispatched to " .. GM.ROUND.Killer:Nick())
				end
			end)
		end
	end

	print("Start round " .. GM.ROUND.Count .. "/" .. GetConVar("slashers_round_max"):GetInt())
end

-- ─────────────────────────────────────────────
-- Synchronisation barrier: fires sls_round_PostStart only when BOTH
-- the killer pipeline AND the survivor class-select pipeline are complete.
-- Prevents the cinematic overlay from appearing before survivors have
-- finished choosing their class.
-- ─────────────────────────────────────────────
function GM.ROUND:CheckSetupComplete()
	if not self.KillerReady or not self.SurvivorsReady then return end
	if not self.Active then return end -- Abort if the round died during setup

	print("[Setup-Pipeline] Both killer and survivors ready — firing PostStart.")
	hook.Run("sls_round_PostStart")
	net.Start("sls_round_PostStart")
		net.WriteInt(self.Count, 16)
		net.WriteInt(self.EndTime or 0, 16)
		net.WriteTable(self.Survivors)
		net.WriteEntity(self.Killer)
		net.WriteTable(GAMEMODE.CLASS:GetClassIDTable())
	net.Broadcast()

	-- ─── Send killer intro in the same tick as PostStart ───────────────────
	-- Keeping showintro here guarantees the cinematic only starts after ALL
	-- survivors have finished their class-select window. Bot killers are skipped
	-- because they have no client to receive the net message.
	if IsValid(self.Killer) and not self.Killer:IsBot() then
		net.Start("sls_killer_showintro")
			net.WriteString(self.Killer.ChosenCharacter or "")
		net.Send(self.Killer)
		print("[Staff-Debug] Server sent showintro to " .. self.Killer:Nick() .. " via CheckSetupComplete")
	end
end

function GM.ROUND:StartWaitingPolice()
	GM.ROUND.WaitingPolice = true
	GM.ROUND.EndTime = CurTime() + GM.CONFIG["round_freeze_start"] + GetConVar("slashers_duration_waitingpolice_base"):GetFloat() +
		(#GM.ROUND:GetSurvivorsAlive() * GetConVar("slashers_duration_waitingpolice_addsurv"):GetFloat())

	hook.Run("sls_round_StartWaitingPolice")
	net.Start("sls_round_StartWaitingPolice")
		net.WriteInt(GM.ROUND.EndTime, 16)
	net.Broadcast()
end

function GM.ROUND:StartEscape()
	objectifComplete()
	GM.ROUND.WaitingPolice = false
	GM.ROUND.Escape = true
	GM.ROUND.EndTime = CurTime() + (GM.MAP.EscapeDuration or 60)

	-- Button escape
	GM.ROUND.EscapeButton = table.Random(ents.FindByName("button_escape"))
	GM.ROUND.EscapeButton:Fire("Press")

	hook.Run("sls_round_StartEscape")
	net.Start("sls_round_StartEscape")
		net.WriteInt(GM.ROUND.EndTime, 16)
	net.Broadcast()
end

function GM.ROUND:End(nowin)
	local winTeam

	GM.ROUND.Active = false
	GM.ROUND.WaitingPolice = false
	GM.ROUND.Escape = false
	if !nowin then
		winTeam = TEAM_KILLER
		for _, v in ipairs(GM.ROUND.Survivors) do
			if v:GetNWBool("Escaped") then
				winTeam = TEAM_SURVIVORS
				break
			end
		end

		hook.Run("sls_round_OnTeamWin", winTeam)
		net.Start("sls_round_OnTeamWin")
			net.WriteInt(winTeam, 4)
		net.Broadcast()
		print("Winner - " .. (winTeam == TEAM_SURVIVORS and "Survivors" or "Killer"))
	end

	for _, v in ipairs(player.GetAll()) do
		v:KillSilent()
	end
	GM.ROUND:ViewInitCam(true)

	GM.ROUND.Survivors = {}
	GM.ROUND.Killer = nil
	GM.ROUND.EndTime = nil
	GM.ROUND.NextStart = CurTime() + (nowin and 8 or GM.CONFIG["round_duration_end"])

	if #player.GetAll() < GetConVar("slashers_round_min_player"):GetInt() then
		GM.ROUND.WaitingPlayers = true
		net.Start("sls_round_WaitingPlayers")
			net.WriteBool(true)
		net.Broadcast()
		hook.Run("sls_round_WaitingPlayers")
	end

	hook.Run("sls_round_End")
	net.Start("sls_round_End")
	net.Broadcast()
	print("Round End")
end

function GM.ROUND:UpdateEndTime(endtime)
	GM.ROUND.EndTime = endtime
	net.Start("sls_round_UpdateEndTime")
		net.WriteInt(GM.ROUND.EndTime, 16)
	net.Broadcast()
end

function GM:PlayerSpawn(ply)
	if !ply.initialKill then
		local camera = ents.FindByName("camera_view")[1]

		ply:KillSilent()
		ply.initialKill = true

		net.Start("sls_round_SetupCamera")
			net.WriteVector(GM.ROUND.CameraPos or Vector(0, 0, 0))
			net.WriteAngle(GM.ROUND.CameraAng or Angle(0, 0, 0))
		net.Send(ply)
		ply:SetPos(GM.ROUND.CameraPos or Vector(0, 0, 0))

		-- Send data
		if GM.ROUND.Active then
			net.Start("sls_round_PlayerConnect")
				net.WriteInt(GM.ROUND.Count, 16)
				net.WriteInt(GM.ROUND.EndTime, 16)
				net.WriteTable(GM.ROUND.Survivors)
				net.WriteEntity(GM.ROUND.Killer)
				net.WriteBool(GM.ROUND.WaitingPlayers)
				net.WriteBool(GM.ROUND.WaitingPolice)
				net.WriteBool(GM.ROUND.Escape)
				net.WriteTable(GM.CLASS:GetClassIDTable())
			net.Send(ply)
		end
	end
end

local function PlayerDK(ply)
	if !GM.ROUND.Active then return end
	if #GM.ROUND:GetSurvivorsAlive() == 0 then
		GM.ROUND:End()
	end
	if ply:Team() == TEAM_KILLER then
		GM.ROUND:End(true)
	end

	print("left survivors: ", #GM.ROUND:GetSurvivorsAlive())
end
hook.Add("PostPlayerDeath", "sls_round_PostPlayerDeath", PlayerDK)

local function PlayerDisconnected(ply)
	if !GM.ROUND.Survivors then return end
	if !IsValid(ply) || !ply:IsValid() then return end

	table.RemoveByValue(GM.ROUND.Survivors, ply)
	net.Start("sls_round_Update")
		net.WriteTable(GM.ROUND.Survivors)
	net.Broadcast()

	PlayerDK(ply)
end
hook.Add("PlayerDisconnected", "sls_round_PlayerDisconnected", PlayerDisconnected)

local function Think()
	local curtime = CurTime()

	if GM.ROUND.Active && GM.ROUND.EndTime && curtime > GM.ROUND.EndTime then
		-- Escape
		if GM.ROUND.WaitingPolice then
			GM.ROUND:StartEscape()
		else
			GM.ROUND:End()
		end
	end

	-- Check NextMap
	if !GM.ROUND.Active && GM.ROUND.NextStart && curtime >= GM.ROUND.NextStart && GM.ROUND.Count >= GetConVar("slashers_round_max"):GetInt() && GM.CONFIG["disabled_modules"]["votemap"] then
		local mapindex = table.KeyFromValue(GM.MAPS, game.GetMap())
		GM.ROUND.NextStart = nil
		RunConsoleCommand("changelevel", mapindex == #GM.MAPS and GM.MAPS[1] or GM.MAPS[mapindex + 1])
	end

	-- Waiting Players
	if GM.ROUND.WaitingPlayers && (!GM.ROUND.NextStart || curtime >= GM.ROUND.NextStart) then
		local count = 0
		for _, v in ipairs(player.GetAll()) do
			if v.initialKill then
				count = count + 1
			end
		end
		if count >= GetConVar("slashers_round_min_player"):GetInt() then
			GM.ROUND.WaitingPlayers = false
			timer.Simple(1, function()
				if #player.GetAll() < GetConVar("slashers_round_min_player"):GetInt() then
					GM.ROUND.WaitingPlayers = true
					return
				end

				net.Start("sls_round_WaitingPlayers")
					net.WriteBool(false)
				net.Broadcast()
				GM.ROUND:Start()
			end)
		end
	end

	-- Auto restart
	if !GM.ROUND.Active && GM.ROUND.NextStart && curtime >= GM.ROUND.NextStart then
		GM.ROUND:Start()
	end
end
hook.Add("Think", "sls_round_Think", Think)

local function InitPostEntity()
	-- Create zones
	for _, v in ipairs(ents.FindByName("trigger_escape")) do
		local zone
		local vec1, vec2

		vec1 = v:LocalToWorld(v:OBBMins())
		vec2 = v:LocalToWorld(v:OBBMaxs())
		zone = CreateZone(vec1, vec2)

		function zone:OnPlayerEnter(ply)
			if !GM.ROUND.Escape then return end
			if ply:Team() != TEAM_SURVIVORS then return end
			ply:SetNWBool("Escaped", true)
			ply:KillSilent()
		end
	end

	-- Get Cam pos
	local camera = ents.FindByName("camera_view")[1]
	if IsValid(camera) then
		GM.ROUND.CameraPos = camera:GetPos()
		GM.ROUND.CameraAng = camera:GetAngles()
	else
		GM.ROUND.CameraPos = Vector(0, 0, 0)
		GM.ROUND.CameraAng = Angle(0, 0, 0)
	end
end
hook.Add("InitPostEntity", "sls_round_InitPostEntity", InitPostEntity)
