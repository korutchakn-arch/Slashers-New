-- Slashers — Killer Setup Pipeline (Server)

util.AddNetworkString("sls_killer_opencharselect")
util.AddNetworkString("sls_killer_selectchar")
util.AddNetworkString("sls_killer_openweaponselect")
util.AddNetworkString("sls_killer_selectweapon")
util.AddNetworkString("sls_killer_showintro")
util.AddNetworkString("sls_killer_intro_finished")
util.AddNetworkString("sls_killer_sync_character")

-- Reset state at the start of each round
hook.Add("sls_round_PreStart", "sls_KillerSetup_Reset", function()
	for _, ply in ipairs(player.GetAll()) do
		ply.HasChosenCharacter = false
		ply.HasChosenWeapon    = false
		ply.ChosenCharacter    = nil
	end
end)

-- Safety: if killer never receives weapon menu within 5s of character selection, resend it
-- Also set a 30s watchdog to auto-proceed if they never pick a weapon
local function StartWeaponSelectWatchdog(ply)
	timer.Remove("sls_KillerSetup_WeaponWatchdog_" .. ply:SteamID64())

	-- Fallback: if no weapon chosen within 30s of character selection, force a default
	timer.Create("sls_KillerSetup_WeaponWatchdog_" .. ply:SteamID64(), 30, 1, function()
		if not IsValid(ply) then return end
		if ply:Team() ~= TEAM_KILLER then return end
		if ply.HasChosenWeapon then return end

		print("[Setup-Pipeline] WARNING: Killer timed out on weapon selection. Auto-selecting default weapon.")

		local allowed = GAMEMODE.CONFIG["killer_weapons"]
		local weaponClass = allowed and allowed[1] or "tfa_nmrih_machete"

		ply:Give(weaponClass)
		ply:SelectWeapon(weaponClass)
		ply.InitialWeapon   = weaponClass
		ply.HasChosenWeapon = true

		-- Signal killer is ready; PostStart only fires once survivors are also done.
		GAMEMODE.ROUND.KillerReady = true
		GAMEMODE.ROUND:CheckSetupComplete()

		net.Start("sls_killer_showintro")
			net.WriteString(ply.ChosenCharacter or "")
		net.Send(ply)
	end)
end

-- ─────────────────────────────────────────────
-- Stage 2 → Weapon Selection
-- ─────────────────────────────────────────────
net.Receive("sls_killer_selectchar", function(len, ply)
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_KILLER then return end
	if ply.HasChosenCharacter then return end

	local charKey = net.ReadString()
	print("[Staff-Debug] Server received character: " .. charKey)

	local charData = GAMEMODE.KillerCharacters[charKey]
	if not charData then return end

	-- Apply character stats and model
	ply:SetModel(charData.model)
	ply:SetupHands()
	ply:SetWalkSpeed(charData.walk)
	ply:SetRunSpeed(charData.run)
	ply.ChosenCharacter    = charKey
	ply.HasChosenCharacter = true

	-- Keep the killer frozen until the full intro finishes
	ply:Freeze(true)

	-- ATMOSPHERIC: update global GM.MAP.Killer so other systems see the chosen character
	GAMEMODE.MAP.Killer = GAMEMODE.MAP.Killer or {}
	GAMEMODE.MAP.Killer.Name  = charData.name
	GAMEMODE.MAP.Killer.Model = charData.model

	-- Broadcast character choice to all clients so their HUD/Scoreboard updates in real-time
	net.Start("sls_killer_sync_character")
		net.WriteString(charKey)
	net.Broadcast()

	-- Stage 2: open weapon selection
	net.Start("sls_killer_openweaponselect")
	net.Send(ply)

	-- Start 30s watchdog — if killer never picks a weapon, auto-proceed
	StartWeaponSelectWatchdog(ply)
	print("[Setup-Pipeline] Weapon selection menu sent. Watchdog started for " .. ply:Nick())

	-- Fire hook so survivor_setup knows the killer has picked their character.
	-- This opens the survivor class-select menu (sls_surv_KillerCharSelected listener
	-- in sv_surv_setup.lua calls OpenSurvivorCharSelect).
	-- NOTE: bot killers never reach this receiver — their full pipeline is handled
	-- server-side inside GM.ROUND:Start() in sv_rounds.lua.
	hook.Run("sls_surv_KillerCharSelected", ply)
end)

-- ─────────────────────────────────────────────
-- Stage 3 → Weapon chosen — fire PostStart globally & send intro
-- All clients receive the correct (chosen) character data synchronously.
-- ─────────────────────────────────────────────
net.Receive("sls_killer_selectweapon", function(len, ply)
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_KILLER then return end
	if ply.HasChosenWeapon then return end

	-- Cancel watchdog since weapon was chosen
	timer.Remove("sls_KillerSetup_WeaponWatchdog_" .. ply:SteamID64())

	local weaponClass = net.ReadString()
	print("[Setup-Pipeline] sls_killer_selectweapon RECEIVED from " .. ply:Nick() .. " — weapon: " .. weaponClass)
	print("[Staff-Debug] Server received weapon: " .. weaponClass)

	-- Validate weapon against allowed config list
	local allowed = GAMEMODE.CONFIG["killer_weapons"]
	local valid = false
	for _, class in ipairs(allowed) do
		if class == weaponClass then
			valid = true
			break
		end
	end
	if not valid then
		print("[Staff-Debug] Selected weapon '" .. weaponClass .. "' not found in config! Falling back to default.")
		weaponClass = allowed[1] or "tfa_nmrih_machete"
	end

	-- Give the weapon and finalize
	ply:Give(weaponClass)
	ply:SelectWeapon(weaponClass)
	ply.InitialWeapon   = weaponClass
	ply.HasChosenWeapon = true

	-- ─── 1. Signal killer ready — PostStart fires only after BOTH sides are done ───
	-- CheckSetupComplete() in sv_rounds.lua holds the barrier. Survivors must finish
	-- their 10-second class-select window before PostStart (and the cinematic) fires.
	GAMEMODE.ROUND.KillerReady = true
	GAMEMODE.ROUND:CheckSetupComplete()

	-- ─── 2. Keep the killer frozen until their cinematic finishes ───
	-- Stage 3: show custom intro screen to the killer only
	net.Start("sls_killer_showintro")
		net.WriteString(ply.ChosenCharacter or "")
	net.Send(ply)
	print("[Staff-Debug] Server sent showintro to " .. ply:Nick())
end)

-- ─────────────────────────────────────────────
-- Centralised survivor freeze/unfreeze for the cinematic window.
-- Fires on sls_round_PostStart, which is now gated by GM.ROUND:CheckSetupComplete()
-- so it only runs once BOTH the killer AND survivors are fully ready.
-- This guarantees the cinematic never overlaps the class-select menu.
-- Using GAMEMODE (not GM) for runtime safety.
-- ─────────────────────────────────────────────
hook.Add("sls_round_PostStart", "sls_Setup_FreezeSurvivors", function()
	local gm = GAMEMODE
	if not gm or not gm.ROUND or not gm.ROUND.Survivors then
		print("[Setup-Pipeline] GAMEMODE.ROUND.Survivors not ready — skipping survivor freeze.")
		return
	end

	-- Freeze all survivors for the cinematic intro window.
	for _, v in ipairs(gm.ROUND.Survivors) do
		if IsValid(v) then v:Freeze(true) end
	end
	print("[Setup-Pipeline] Survivors frozen for cinematic intro.")

	-- Unfreeze after the cinematic window expires.
	local freezeDur = (gm.CONFIG and gm.CONFIG["round_freeze_start"]) or 10
	timer.Simple(freezeDur, function()
		if not GAMEMODE.ROUND or not GAMEMODE.ROUND.Survivors then return end
		for _, v in ipairs(GAMEMODE.ROUND.Survivors) do
			if IsValid(v) then v:Freeze(false) end
		end
		print("[Setup-Pipeline] Survivors unfrozen after cinematic.")
	end)
end)

-- ─────────────────────────────────────────────
-- Stage 4 → Intro finished — unfreeze the killer
-- ─────────────────────────────────────────────
net.Receive("sls_killer_intro_finished", function(len, ply)
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_KILLER then return end

	-- Cancel watchdog in case the 30s timer fires after intro finished normally
	timer.Remove("sls_KillerSetup_WeaponWatchdog_" .. ply:SteamID64())

	ply:Freeze(false)
	print("[Staff-Debug] Killer setup complete. Player unfrozen!")
end)
