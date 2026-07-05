-- Slashers — Killer Weapon Selection Module (Client)

local WeaponNames = {
	["tfa_nmrih_chainsaw"]      = "Chainsaw",
	["tfa_nmrih_fireaxe"]       = "Fire Axe",
	["tfa_nmrih_machete"]       = "Machete",
	["tfa_nmrih_washingmachine"] = "Washing Machine"
}

local BUTTON_H    = 52
local BUTTON_PAD  = 8
local FRAME_PAD   = 16
local TITLE_H     = 56
local FOOTER_H    = 12

local function GetWeaponName(class)
	if WeaponNames[class] then
		return WeaponNames[class]
	end
	local data = weapons.GetStored(class)
	return data and data.PrintName or class
end

local function OpenWeaponSelectMenu()
	if IsValid(SlashersWeaponFrame) then
		SlashersWeaponFrame:Remove()
	end

	local weapons = GAMEMODE.CONFIG["killer_weapons"]
	if not weapons or #weapons == 0 then return end

	local numWeapons  = #weapons
	local frameW      = 560
	local frameH      = FRAME_PAD + TITLE_H + (numWeapons * (BUTTON_H + BUTTON_PAD)) + FOOTER_H + FRAME_PAD

	local frame = vgui.Create("DFrame")
	frame:SetSize(frameW, frameH)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:MakePopup()
	frame:SetKeyboardInputEnabled(false)
	SlashersWeaponFrame = frame

	-- Custom cinematic dark panel with red border — no default DFrame chrome
	frame.Paint = function(s, w, h)
		-- Outer dark background
		draw.RoundedBox(6, 0, 0, w, h, Color(10, 5, 5, 240))
		-- Red border
		surface.SetDrawColor(180, 30, 30, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		-- Inner subtle border
		surface.SetDrawColor(100, 20, 20, 120)
		surface.DrawOutlinedRect(3, 3, w - 6, h - 6)
	end

	-- ── Title ──────────────────────────────────────────────────────────────
	local titleY = FRAME_PAD
	local titlePanel = vgui.Create("DPanel", frame)
	titlePanel:SetPos(FRAME_PAD, titleY)
	titlePanel:SetSize(frameW - FRAME_PAD * 2, TITLE_H)
	titlePanel.Paint = function(s, w, h)
		-- Blood-red underline
		surface.SetDrawColor(140, 20, 20, 200)
		surface.DrawRect(0, h - 4, w, 4)

		-- Cinematic title
		draw.SimpleText("CHOOSE YOUR WEAPON", "horror1", w / 2, h / 2, Color(220, 50, 50, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- ── Buttons ─────────────────────────────────────────────────────────────
	local canvasY = FRAME_PAD + TITLE_H + BUTTON_PAD
	local canvasH = numWeapons * (BUTTON_H + BUTTON_PAD)

	local canvas = vgui.Create("DPanel", frame)
	canvas:SetPos(FRAME_PAD, canvasY)
	canvas:SetSize(frameW - FRAME_PAD * 2, canvasH)
	canvas:SetPaintBackground(false)

	local yOffset = 0
	for _, class in ipairs(weapons) do
		local printName = GetWeaponName(class)

		local btn = vgui.Create("DButton", canvas)
		btn:SetPos(0, yOffset)
		btn:SetSize(frameW - FRAME_PAD * 2, BUTTON_H)
		btn:SetText("")
		btn:SetContentAlignment(5)

		-- Subtle idle + strong hover/armed states
		btn.Paint = function(s, w, h)
			local hovered = s:IsHovered()
			local bg     = hovered and Color(90, 20, 20) or Color(45, 15, 15)
			local border = hovered and Color(220, 60, 60, 255) or Color(110, 30, 30, 180)

			draw.RoundedBox(4, 0, 0, w, h, bg)
			draw.RoundedBox(4, 0, 0, w, h, Color(border.r, border.g, border.b, 30)) -- inner tint
			surface.SetDrawColor(border)
			surface.DrawOutlinedRect(0, 0, w, h)

			draw.SimpleText(printName, "horrortext", w / 2, h / 2, hovered and Color(255, 200, 200) or Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		btn.DoClick = function()
			net.Start("sls_killer_selectweapon")
			net.WriteString(class)
			net.SendToServer()
			frame:Close()
		end

		yOffset = yOffset + BUTTON_H + BUTTON_PAD
	end
end

net.Receive("sls_killer_openweaponselect", function(len)
	OpenWeaponSelectMenu()
end)
