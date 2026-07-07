-- Slashers — Killer Setup Pipeline (Client)

local GM = GM or GAMEMODE

-- ─────────────────────────────────────────────
-- Local setup state — starts true so Survivors always have HUD
-- ─────────────────────────────────────────────
local hasFinishedSetup = true

-- ─────────────────────────────────────────────
-- HUD suppression during setup (killer only)
-- ─────────────────────────────────────────────
hook.Add("HUDShouldDraw", "sls_KillerSetup_HUD", function(name)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_KILLER then return end
	if hasFinishedSetup ~= true then
		-- Allow CHudGMod (which powers HUDPaint) to render while the sync barrier
		-- is active so the black-screen overlay in cl_rounds.lua can draw.
		-- HUDPaint exits early via `return` after drawing the black rect, so no
		-- normal HUD content (timers, objectives) can bleed through.
		if GAMEMODE.ROUND.SetupWaiting and name == "CHudGMod" then
			return  -- return nil = allow this element
		end
		-- Suppress every other HUD element (health, ammo, crosshair, etc.)
		return false
	end
end)

-- ─────────────────────────────────────────────
-- Rendering-level blackout — DISABLED (blackout bypass plan)
-- Kept as comments for reference only.
-- ─────────────────────────────────────────────
-- hook.Add("RenderScreenspaceEffects", "sls_KillerSetup_Blackout", function()
-- 	if hasFinishedSetup ~= true then
-- 		render.Clear(0, 0, 0, 255, true, true)
-- 	end
-- end)

-- ─────────────────────────────────────────────
-- Weapon name lookup (matches server config)
-- ─────────────────────────────────────────────
local WeaponNames = {
	["tfa_nmrih_chainsaw"]       = "Chainsaw",
	["tfa_nmrih_fireaxe"]        = "Fire Axe",
	["tfa_nmrih_machete"]        = "Machete",
	["tfa_nmrih_washingmachine"] = "Washing Machine"
}

local function GetWeaponName(class)
	if WeaponNames[class] then
		return WeaponNames[class]
	end
	local data = weapons.GetStored(class)
	return data and data.PrintName or class
end

-- ─────────────────────────────────────────────
-- Shared UI constants
-- ─────────────────────────────────────────────
local FRAME_PAD  = 16
local TITLE_H    = 56
local BUTTON_H   = 52
local BUTTON_PAD = 8
local FOOTER_H   = 12

-- ─────────────────────────────────────────────
-- Stage 1: Character Selection Menu
-- ─────────────────────────────────────────────
local function OpenCharSelectMenu()
	if IsValid(SlashersCharFrame) then
		SlashersCharFrame:Remove()
	end

	local chars = GAMEMODE.KillerCharacters
	local numChars = table.Count(chars)

	-- 3 columns: 3 cards per row, fixed card width
	local CARD_W    = 260
	local CARD_H    = 340
	local COL_GAP   = 20
	local ROW_GAP   = 16
	local COLS      = 3
	local rows      = math.ceil(numChars / COLS)
	local TIMER_H   = 48
	local frameW    = COLS * CARD_W + (COLS - 1) * COL_GAP + FRAME_PAD * 2
	local frameH    = FRAME_PAD + TITLE_H + TIMER_H + 16 + rows * CARD_H + (rows - 1) * ROW_GAP + FOOTER_H + FRAME_PAD

	-- Standalone DFrame — no parent panel. HUDPaintBackground covers the world behind it.
	local frame = vgui.Create("DFrame")
	frame:SetSize(frameW, frameH)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:MakePopup()
	frame:SetKeyboardInputEnabled(false)
	SlashersCharFrame = frame

	frame.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(8, 4, 4, 245))
		surface.SetDrawColor(160, 25, 25, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.SetDrawColor(90, 15, 15, 100)
		surface.DrawOutlinedRect(3, 3, w - 6, h - 6)
	end

	-- Title bar
	local titlePanel = vgui.Create("DPanel", frame)
	titlePanel:SetPos(FRAME_PAD, FRAME_PAD)
	titlePanel:SetSize(frameW - FRAME_PAD * 2, TITLE_H)
	titlePanel.Paint = function(s, w, h)
		surface.SetDrawColor(130, 18, 18, 200)
		surface.DrawRect(0, h - 4, w, 4)
		draw.SimpleText("CHOOSE YOUR CHARACTER", "horror1", w / 2, h / 2, Color(220, 50, 50, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- ─── Countdown timer panel ───
	local TIMER_DURATION = 10
	local timeLeft = TIMER_DURATION

	local timerPanel = vgui.Create("DPanel", frame)
	timerPanel:SetPos((frameW - 100) / 2, FRAME_PAD + TITLE_H + 8)
	timerPanel:SetSize(100, TIMER_H)
	timerPanel.Paint = function(s, w, h)
		local frac = timeLeft / TIMER_DURATION
		local r = frac < 0.3 and 255 or math.floor(220 + (1 - frac) * 35)
		local g = frac < 0.3 and math.floor(frac * 200) or math.floor(50 + (1 - frac) * 50)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 8, 8, 220))
		surface.SetDrawColor(140, 20, 20, 180)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("0:" .. string.format("%02d", timeLeft), "horror1", w / 2, h / 2, Color(r, g, 60, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- Build character list before the timer Think hook references it
	local charList = {}
	for k, v in pairs(chars) do
		table.insert(charList, {key = k, data = v})
	end

	local timerThink = 0
	hook.Add("Think", "sls_CharSelectTimer", function()
		if not IsValid(frame) then
			hook.Remove("Think", "sls_CharSelectTimer")
			return
		end
		timerThink = timerThink + FrameTime()
		if timerThink >= 1 then
			timerThink = 0
			timeLeft = timeLeft - 1
			if timeLeft <= 0 then
				timeLeft = 0
				hook.Remove("Think", "sls_CharSelectTimer")
				-- Auto-select first character on timeout
				local firstEntry = charList[1]
				if firstEntry then
					net.Start("sls_killer_selectchar")
					net.WriteString(firstEntry.key)
					net.SendToServer()
				end
				frame:Close()
			end
		end
	end)

	frame:InvalidateLayout()

	-- Card grid
	local gridY = FRAME_PAD + TITLE_H + TIMER_H + 16

	local idx = 0
	for _, entry in ipairs(charList) do
		local col   = idx % COLS
		local row   = math.floor(idx / COLS)
		local cardX = FRAME_PAD + col * (CARD_W + COL_GAP)
		local cardY = gridY + row * (CARD_H + ROW_GAP)
		idx = idx + 1

		local card = vgui.Create("DPanel", frame)
		card:SetPos(cardX, cardY)
		card:SetSize(CARD_W, CARD_H)
		card:SetPaintBackground(false)

		-- Cinematic portrait silhouette (icon or fallback)
		local portrait = vgui.Create("DPanel", card)
		portrait:SetPos(0, 0)
		portrait:SetSize(CARD_W, 180)
		local iconMat = Material("icons/icon_" .. entry.key .. ".png")
		portrait.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(20, 8, 8, 255))
			surface.SetDrawColor(120, 20, 20, 200)
			surface.DrawOutlinedRect(0, 0, w, h)
			if iconMat and not iconMat:IsError() then
				surface.SetMaterial(iconMat)
				surface.DrawTexturedRect(w / 2 - 64, h / 2 - 64, 128, 128)
			else
				draw.SimpleText("???", "horrortext", w / 2, h / 2, Color(120, 30, 30, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		-- Name label
		local nameLabel = vgui.Create("DLabel", card)
		nameLabel:SetPos(0, 184)
		nameLabel:SetSize(CARD_W, 28)
		nameLabel:SetFont("horrortext")
		nameLabel:SetText(entry.data.name:upper())
		nameLabel:SetContentAlignment(5)
		nameLabel:SetTextColor(Color(230, 60, 60, 255))

		-- Description
		local descLabel = vgui.Create("DLabel", card)
		descLabel:SetPos(8, 212)
		descLabel:SetSize(CARD_W - 16, 70)
		descLabel:SetFont("ChatFont")
		descLabel:SetText(entry.data.desc)
		descLabel:SetContentAlignment(5)
		descLabel:SetTextColor(Color(200, 180, 180, 255))
		descLabel:SetWrap(true)

		-- Select button
		local selectBtn = vgui.Create("DButton", card)
		selectBtn:SetPos(10, CARD_H - 40)
		selectBtn:SetSize(CARD_W - 20, 30)
		selectBtn:SetText("")
		selectBtn.Paint = function(s, w, h)
			local hovered = s:IsHovered()
			draw.RoundedBox(4, 0, 0, w, h, hovered and Color(140, 20, 20) or Color(70, 15, 15))
			surface.SetDrawColor(hovered and Color(220, 60, 60) or Color(130, 30, 30))
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.SimpleText("SELECT", "horror1", w / 2, h / 2, Color(240, 240, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		-- Capture entry in closure to prevent loop variable aliasing bug
		local entryCopy = entry
		selectBtn.DoClick = function()
			net.Start("sls_killer_selectchar")
			net.WriteString(entryCopy.key)
			net.SendToServer()
			frame:Close()
		end
	end
end

-- ─────────────────────────────────────────────
-- Stage 2: Weapon Selection Menu
-- ─────────────────────────────────────────────
local function OpenWeaponSelectMenu()
	if IsValid(SlashersWeaponFrame) then
		SlashersWeaponFrame:Remove()
	end

	local weapons   = GAMEMODE.CONFIG["killer_weapons"]
	if not weapons or #weapons == 0 then return end

	local numWeapons = #weapons
	local frameW     = 560
	local TIMER_H    = 36
	local frameH     = FRAME_PAD + TITLE_H + TIMER_H + 12 + (numWeapons * (BUTTON_H + BUTTON_PAD)) + FOOTER_H + FRAME_PAD

	-- Standalone DFrame — no parent panel. HUDPaintBackground covers the world behind it.
	local frame = vgui.Create("DFrame")
	frame:SetSize(frameW, frameH)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:MakePopup()
	frame:SetKeyboardInputEnabled(false)
	SlashersWeaponFrame = frame

	frame.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(10, 5, 5, 240))
		surface.SetDrawColor(180, 30, 30, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.SetDrawColor(100, 20, 20, 120)
		surface.DrawOutlinedRect(3, 3, w - 6, h - 6)
	end

	-- Title bar
	local titlePanel = vgui.Create("DPanel", frame)
	titlePanel:SetPos(FRAME_PAD, FRAME_PAD)
	titlePanel:SetSize(frameW - FRAME_PAD * 2, TITLE_H)
	titlePanel.Paint = function(s, w, h)
		surface.SetDrawColor(140, 20, 20, 200)
		surface.DrawRect(0, h - 4, w, 4)
		draw.SimpleText("CHOOSE YOUR WEAPON", "horror1", w / 2, h / 2, Color(220, 50, 50, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- ─── Countdown timer panel ───
	local TIMER_DURATION = 10
	local timeLeft = TIMER_DURATION
	local endTime  = CurTime() + TIMER_DURATION

	local timerPanel = vgui.Create("DPanel", frame)
	timerPanel:SetPos((frameW - 80) / 2, FRAME_PAD + TITLE_H + 8)
	timerPanel:SetSize(80, TIMER_H)
	timerPanel.Paint = function(s, w, h)
		local frac = timeLeft / TIMER_DURATION
		local r = frac < 0.3 and 255 or math.floor(220 + (1 - frac) * 35)
		local g = frac < 0.3 and math.floor(frac * 200) or math.floor(50 + (1 - frac) * 50)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 8, 8, 220))
		surface.SetDrawColor(140, 20, 20, 180)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("0:" .. string.format("%02d", timeLeft), "horror1", w / 2, h / 2, Color(r, g, 60, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	hook.Add("Think", "sls_WeaponSelectTimer", function()
		if not IsValid(frame) then
			hook.Remove("Think", "sls_WeaponSelectTimer")
			return
		end
		timeLeft = math.max(0, math.ceil(endTime - CurTime()))
		if timeLeft <= 0 then
			hook.Remove("Think", "sls_WeaponSelectTimer")
			-- Auto-select first weapon on timeout
			local firstWeapon = weapons[1]
			if firstWeapon then
				net.Start("sls_killer_selectweapon")
				net.WriteString(firstWeapon)
				net.SendToServer()
			end
			-- Show black screen while waiting for all players to finish setup.
			GAMEMODE.ROUND.SetupWaiting = true
			frame:Close()
		end
	end)

	frame:InvalidateLayout()

	-- Button canvas
	local canvasY = FRAME_PAD + TITLE_H + TIMER_H + 8 + BUTTON_PAD
	local canvasH = numWeapons * (BUTTON_H + BUTTON_PAD)
	local canvas  = vgui.Create("DPanel", frame)
	canvas:SetPos(FRAME_PAD, canvasY)
	canvas:SetSize(frameW - FRAME_PAD * 2, canvasH)
	canvas:SetPaintBackground(false)

	local yOffset = 0
	for _, class in ipairs(weapons) do
		local printName = GetWeaponName(class)
		local btnClass  = class  -- closure capture per iteration

		local btn = vgui.Create("DButton", canvas)
		btn:SetPos(0, yOffset)
		btn:SetSize(frameW - FRAME_PAD * 2, BUTTON_H)
		btn:SetText("")
		btn.Paint = function(s, w, h)
			local hovered = s:IsHovered()
			draw.RoundedBox(4, 0, 0, w, h, hovered and Color(90, 20, 20) or Color(45, 15, 15))
			surface.SetDrawColor(hovered and Color(220, 60, 60) or Color(110, 30, 30, 180))
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.SimpleText(printName, "horrortext", w / 2, h / 2, hovered and Color(255, 200, 200) or Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			print("[Client-Debug] DoClick fired — sending weapon: " .. btnClass)
			net.Start("sls_killer_selectweapon")
			net.WriteString(btnClass)
			net.SendToServer()
			-- Show black screen while waiting for all players to finish setup.
			GAMEMODE.ROUND.SetupWaiting = true
			frame:Close()
		end

		yOffset = yOffset + BUTTON_H + BUTTON_PAD
	end
end

-- ─────────────────────────────────────────────
-- Stage 3: Trigger Custom Character Intro
-- ─────────────────────────────────────────────
local function ShowCustomIntro(charKey)
	-- Safe fallback for character data — never crash
	local charData = GAMEMODE.KillerCharacters[charKey]
	if not charData then
		charData = GAMEMODE.KillerCharacters["ghostface"] or {
			name = "Unknown",
			desc = "No character data available.",
			model = "models/player.mdl"
		}
	end

	-- ─── FIX: Removed ShowTitle() call entirely.
	-- ShowTitle creates a full-screen black DPanel (alpha 250) that covers the world.
	-- With blackout disabled the world is visible, so ShowTitle now hides it and
	-- creates a conflicting black→world→ShowPlayerScreen visual glitch.
	-- The killer intro is handled exclusively by ShowPlayerScreen below.

	local freezeDur = GM.CONFIG["round_freeze_start"] or 10
	-- delay = how long ShowPlayerScreen stays on screen before auto-removing itself
	local delay = math.max(0.5, freezeDur - 3)

	-- Resolve all values now so ShowPlayerScreen's nil-guard never triggers
	local TeamName   = GM.LANG:GetString("round_team_name_killer") or "KILLER"
	local TeamText   = GM.LANG:GetString("round_team_desc_killer") or "You are the killer. Hunt them down."
	local CharacName = charData.name or "Killer"
	local CharacText = charData.desc or ""
	local ImageCharc = "materials/characteres/" .. string.lower(charData.name or "default") .. ".png"

	-- Final defensive defaults so ShowPlayerScreen never silently returns early
	if not TeamName   or TeamName   == "" then TeamName   = "KILLER" end
	if not TeamText   or TeamText   == "" then TeamText   = "Hunt them down." end
	if not CharacName or CharacName == "" then CharacName = "Killer" end
	if not ImageCharc or ImageCharc == "" then ImageCharc = "materials/characteres/default.png" end

	print("[Setup-Pipeline] ShowPlayerScreen: " .. TeamName .. " | " .. CharacName .. " | " .. ImageCharc .. " | delay=" .. delay)

	-- ShowPlayerScreen builds the animated intro panel immediately.
	-- It auto-removes itself after `delay` seconds via its internal timer chain.
	ShowPlayerScreen(TeamName, TeamText, CharacName, CharacText, ImageCharc, delay)

	-- ─── FIX: Use `delay` (not `freezeDur`) so the server is notified exactly
	-- when ShowPlayerScreen finishes, regardless of the internal animation.
	timer.Simple(delay + 0.5, function()
		hasFinishedSetup = true

		-- Kill the round-start camera override so the killer sees from their real position
		GM.ROUND.CameraEnable = false

		if IsValid(LocalPlayer()) then
			net.Start("sls_killer_intro_finished")
			net.SendToServer()
			print("[Setup-Pipeline] Cinematic finished. Killer unfrozen.")
		end
	end)
end

-- ─────────────────────────────────────────────
-- Net receivers
-- ─────────────────────────────────────────────
net.Receive("sls_killer_opencharselect", function(len)
	hasFinishedSetup = false
	OpenCharSelectMenu()
end)

net.Receive("sls_killer_openweaponselect", function(len)
	OpenWeaponSelectMenu()
end)

net.Receive("sls_killer_showintro", function(len)
	local charKey = net.ReadString() or ""
	print("[Staff-Debug] Client received showintro for: " .. charKey)
	ShowCustomIntro(charKey)
end)

-- ─────────────────────────────────────────────
-- Sync chosen character to all clients so their HUD/Scoreboard
-- renders the correct name and icon instead of the map default
-- ─────────────────────────────────────────────
net.Receive("sls_killer_sync_character", function(len)
	local charKey = net.ReadString()
	local charData = GAMEMODE.KillerCharacters[charKey]
	if not charData then return end

	-- Also sync the character key onto the local player entity so that
	-- ability guards (e.g. ChosenCharacter ~= "myers") work correctly.
	-- Without this, LocalPlayer().ChosenCharacter is nil for all clients,
	-- causing Myers-only net receivers to fire for all Killer characters.
	LocalPlayer().ChosenCharacter = charKey

	GAMEMODE.MAP.Killer = GAMEMODE.MAP.Killer or {}
	GAMEMODE.MAP.Killer.Name  = charData.name
	GAMEMODE.MAP.Killer.Model = charData.model

	if CLIENT then
		GAMEMODE.MAP.Killer.Desc = charData.desc
		GAMEMODE.MAP.Killer.Icon = Material(charData.icon or "icons/icon_ghostface.png")
	end

	print("[Setup-Pipeline] Synchronized Killer to: " .. charData.name .. " | LocalPlayer().ChosenCharacter = " .. charKey)
end)
