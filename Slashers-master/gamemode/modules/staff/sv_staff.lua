-- Slashers — Staff / Admin Module (Server)

util.AddNetworkString("sls_staff_open")
util.AddNetworkString("sls_staff_action")
util.AddNetworkString("sls_spectator_scare")

-- ─────────────────────────────────────────────────────────────────────────────
--  Console command: sls_admin
-- ─────────────────────────────────────────────────────────────────────────────
concommand.Add("sls_admin", function(ply, cmd, args)
	if not IsValid(ply) then return end
	if not ply:IsAdmin() then
		ply:ChatPrint("[Staff] Admin access required.")
		return
	end
	net.Start("sls_staff_open")
	net.Send(ply)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Staff actions
-- ─────────────────────────────────────────────────────────────────────────────
net.Receive("sls_staff_action", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local action = net.ReadString()
	local target  = net.ReadEntity()

	-- ── 1. KICK — strict validation, NO fallback to ply ──────────────────────
	if action == "kick" then
		if not IsValid(target) or not target:IsPlayer() then
			ply:ChatPrint("[Staff] Invalid kick target.")
			return
		end
		target:Kick("Kicked by Admin")
		ply:ChatPrint("[Staff] " .. target:Nick() .. " kicked.")
		return
	end

	-- ── 1b. TELEPORT TO PLAYER ───────────────────────────────────────────────
	if action == "teleport_to" then
		if not IsValid(target) or not target:IsPlayer() then
			ply:ChatPrint("[Staff] Invalid teleport target.")
			return
		end
		ply:SetPos(target:GetPos())
		ply:ChatPrint("[Staff] Teleported to " .. target:Nick() .. ".")
		return
	end

	-- ── 2. GIVE_WEAPON — reads weapon class after the entity ────────────────
	if action == "give_weapon" then
		local weaponClass = net.ReadString()
		if IsValid(target) and target:IsPlayer() then
			target:Give(weaponClass)
			target:ChatPrint("[Staff] You received: " .. weaponClass)
		end
		return
	end

	-- ── 3. Fallback for all remaining actions ────────────────────────────────
	if not IsValid(target) then
		target = ply
	end

	-- ── 4. Remaining actions (force_start, force_end, set_killer, noclip) ──
	if action == "force_start" then
		GAMEMODE.ROUND:Start()
		ply:ChatPrint("[Staff] Round started.")

	elseif action == "force_end" then
		GAMEMODE.ROUND:End(true)
		ply:ChatPrint("[Staff] Round ended.")

	elseif action == "set_killer" then
		-- End any active round first so Start() picks the new killer cleanly
		if GAMEMODE.ROUND.Active then
			GAMEMODE.ROUND:End(true)
		end
		GAMEMODE.ROUND:Start(target)
		ply:ChatPrint("[Staff] " .. target:Nick() .. " set as killer.")

	elseif action == "noclip" then
		if ply:GetMoveType() == MOVETYPE_NOCLIP then
			ply:SetMoveType(MOVETYPE_WALK)
			ply:ChatPrint("[Staff] NoClip disabled.")
		else
			ply:SetMoveType(MOVETYPE_NOCLIP)
			ply:ChatPrint("[Staff] NoClip enabled.")
		end

	elseif action == "play_survivor" then
		local classes = table.GetKeys(GAMEMODE.CLASS.Survivors)
		if classes and classes[1] then
			local chosenClass = classes[1]
			target:SetTeam(TEAM_SURVIVORS)
			target:Spawn()
			target:SetSurvClass(chosenClass)
			ply:ChatPrint("[Staff] " .. target:Nick() .. " is now a Survivor.")
		end
	end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Spectator Scare
-- ─────────────────────────────────────────────────────────────────────────────
local SCARE_SOUNDS = {
	"ambient/creatures/town_scared_1.wav",
	"ambient/creatures/town_scared_2.wav",
	"npc/stalker/go_alert2a.wav",
	"npc/stalker/go_alert3a.wav"
}

net.Receive("sls_spectator_scare", function(len, ply)
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED then return end
	if ply:IsAdmin() == false and ply:IsSuperAdmin() == false then return end

	-- Must be in chase spectate mode observing a player
	local obsTarget = ply:GetObserverTarget()
	if ply:GetObserverMode() ~= OBS_MODE_CHASE or not IsValid(obsTarget) then return end

	-- 30-second cooldown
	if ply.NextScareTime and CurTime() < ply.NextScareTime then
		local remaining = math.ceil(ply.NextScareTime - CurTime())
		ply:ChatPrint("[Staff] Scare on cooldown — " .. remaining .. "s remaining.")
		return
	end

	-- Play a random scare sound at the target's position
	local snd = SCARE_SOUNDS[math.random(#SCARE_SOUNDS)]
	ply.NextScareTime = CurTime() + 30

	sound.Play(snd, obsTarget:GetPos(), 100, 100)

	-- Notify the spectator
	net.Start("sls_spectator_scare")
		net.WriteBool(true)
	net.Send(ply)
end)
