-- Slashers — Staff / Admin Module (Client)

-- ─────────────────────────────────────────────────────────────────────────────
--  UI helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function MakeStaffButton(parent, label, y, action, target)
	local btn = vgui.Create("DButton", parent)
	btn:SetPos(16, y)
	btn:SetSize(parent:GetWide() - 32, 40)
	btn:SetText("")
	btn:SetContentAlignment(5)

	btn.Paint = function(s, w, h)
		local hovered = s:IsHovered()
		local bg     = hovered and Color(90, 20, 20) or Color(45, 15, 15)
		local border = hovered and Color(220, 60, 60, 255) or Color(110, 30, 30, 180)

		draw.RoundedBox(4, 0, 0, w, h, bg)
		surface.SetDrawColor(border)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText(label, "horrortext", w / 2, h / 2, hovered and Color(255, 200, 200) or Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	btn.DoClick = function()
		net.Start("sls_staff_action")
		net.WriteString(action)
		-- Evaluate LocalPlayer() at click-time, not at panel-creation time
		net.WriteEntity(target or LocalPlayer())
		net.SendToServer()
		parent:Close()
	end

	return btn
end

local function OpenStaffPanel()
	if IsValid(StaffPanel) then
		StaffPanel:Remove()
	end

	local frameW, frameH = 480, 540
	local frame = vgui.Create("DFrame")
	frame:SetSize(frameW, frameH)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(true)
	frame:MakePopup()
	StaffPanel = frame

	frame.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(10, 5, 5, 245))
		surface.SetDrawColor(180, 30, 30, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.SetDrawColor(100, 20, 20, 120)
		surface.DrawOutlinedRect(3, 3, w - 6, h - 6)
	end

	-- Title bar
	local titlePanel = vgui.Create("DPanel", frame)
	titlePanel:SetPos(0, 0)
	titlePanel:SetSize(frameW, 52)
	titlePanel.Paint = function(s, w, h)
		surface.SetDrawColor(140, 20, 20, 200)
		surface.DrawRect(0, h - 4, w, 4)
		draw.SimpleText("STAFF PANEL", "horror2", w / 2, h / 2, Color(220, 50, 50, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- Close button (top-right)
	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetPos(frameW - 44, 4)
	closeBtn:SetSize(40, 36)
	closeBtn:SetText("")
	closeBtn.Paint = function(s, w, h)
		local hovered = s:IsHovered()
		draw.RoundedBox(4, 0, 0, w, h, hovered and Color(100, 20, 20) or Color(60, 15, 15))
		draw.SimpleText("X", "DermaLarge", w / 2, h / 2, Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function() frame:Close() end

	-- Section: Round Controls
	local section1Y = 60
	local section1Label = vgui.Create("DLabel", frame)
	section1Label:SetPos(16, section1Y)
	section1Label:SetSize(frameW - 32, 20)
	section1Label:SetText("Round Controls")
	section1Label:SetFont("DermaDefaultBold")
	section1Label:SetTextColor(Color(200, 60, 60))

	MakeStaffButton(frame, "Force Start Round", 82,  "force_start", Entity(0))
	MakeStaffButton(frame, "Force End Round",   130, "force_end",   Entity(0))

	-- Section: Killer Controls
	local section2Y = 184
	local section2Label = vgui.Create("DLabel", frame)
	section2Label:SetPos(16, section2Y)
	section2Label:SetSize(frameW - 32, 20)
	section2Label:SetText("Killer Controls")
	section2Label:SetFont("DermaDefaultBold")
	section2Label:SetTextColor(Color(200, 60, 60))

	MakeStaffButton(frame, "Make Me Killer (Restart)", 206, "set_killer", LocalPlayer())

	-- Section: Player Controls
	local section3Y = 254
	local section3Label = vgui.Create("DLabel", frame)
	section3Label:SetPos(16, section3Y)
	section3Label:SetSize(frameW - 32, 20)
	section3Label:SetText("Player Controls")
	section3Label:SetFont("DermaDefaultBold")
	section3Label:SetTextColor(Color(200, 60, 60))

	-- NoClip toggle
	MakeStaffButton(frame, "Toggle NoClip", 276, "noclip", LocalPlayer())

	-- Play as Survivor — directly makes the admin a survivor (no picker)
	MakeStaffButton(frame, "Play as Survivor", 420, "play_survivor", LocalPlayer())

	-- ─────────────────────────────────────────────────────────────────────
	-- Section: Dev Tools
	-- ─────────────────────────────────────────────────────────────────────
	local section4Label = vgui.Create("DLabel", frame)
	section4Label:SetPos(16, 472)
	section4Label:SetSize(frameW - 32, 20)
	section4Label:SetText("Dev Tools")
	section4Label:SetFont("DermaDefaultBold")
	section4Label:SetTextColor(Color(200, 60, 60))

	-- Gives the admin the TFA SWEP Construction Kit creator tool so VElements
	-- positions can be adjusted in-game without needing the spawnmenu.
	local sckBtn = vgui.Create("DButton", frame)
	sckBtn:SetPos(16, 494)
	sckBtn:SetSize(frameW - 32, 40)
	sckBtn:SetText("")
	sckBtn:SetContentAlignment(5)
	sckBtn.Paint = function(s, w, h)
		local hovered = s:IsHovered()
		local bg     = hovered and Color(90, 20, 20) or Color(45, 15, 15)
		local border = hovered and Color(220, 60, 60, 255) or Color(110, 30, 30, 180)
		draw.RoundedBox(4, 0, 0, w, h, bg)
		surface.SetDrawColor(border)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("Give SCK Creator Tool", "horrortext", w / 2, h / 2, hovered and Color(255, 200, 200) or Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	sckBtn.DoClick = function()
		net.Start("sls_staff_action")
		net.WriteString("give_weapon")
		net.WriteEntity(LocalPlayer())
		net.WriteString("swep_construction_kit")  -- Original SWEP Construction Kit class
		net.SendToServer()
		frame:Close()
	end

	-- Teleport to Player — opens a DermaMenu dropdown
	local teleportBtn = vgui.Create("DButton", frame)
	teleportBtn:SetPos(16, 324)
	teleportBtn:SetSize(frameW - 32, 40)
	teleportBtn:SetText("")
	teleportBtn:SetContentAlignment(5)
	teleportBtn.Paint = function(s, w, h)
		local hovered = s:IsHovered()
		local bg     = hovered and Color(90, 20, 20) or Color(45, 15, 15)
		local border = hovered and Color(220, 60, 60, 255) or Color(110, 30, 30, 180)
		draw.RoundedBox(4, 0, 0, w, h, bg)
		surface.SetDrawColor(border)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("Teleport to Player", "horrortext", w / 2, h / 2, hovered and Color(255, 200, 200) or Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	teleportBtn.DoClick = function()
		local menu = DermaMenu()
		for _, p in ipairs(player.GetAll()) do
			local targetPly = p
			menu:AddOption(targetPly:Nick(), function()
				net.Start("sls_staff_action")
				net.WriteString("teleport_to")
				net.WriteEntity(targetPly)
				net.SendToServer()
				if IsValid(frame) then frame:Close() end
			end)
		end
		menu:Open()
	end

	-- Kick Player — opens a DermaMenu dropdown
	local kickBtn = vgui.Create("DButton", frame)
	kickBtn:SetPos(16, 372)
	kickBtn:SetSize(frameW - 32, 40)
	kickBtn:SetText("")
	kickBtn:SetContentAlignment(5)
	kickBtn.Paint = function(s, w, h)
		local hovered = s:IsHovered()
		local bg     = hovered and Color(90, 20, 20) or Color(45, 15, 15)
		local border = hovered and Color(220, 60, 60, 255) or Color(110, 30, 30, 180)
		draw.RoundedBox(4, 0, 0, w, h, bg)
		surface.SetDrawColor(border)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("Kick Player", "horrortext", w / 2, h / 2, hovered and Color(255, 200, 200) or Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	kickBtn.DoClick = function()
		local menu = DermaMenu()
		for _, p in ipairs(player.GetAll()) do
			-- Capture a local copy so the closure always sees the correct player
			local targetPly = p
			menu:AddOption(targetPly:Nick(), function()
				net.Start("sls_staff_action")
				net.WriteString("kick")
				net.WriteEntity(targetPly)
				net.SendToServer()
				if IsValid(frame) then frame:Close() end
			end)
		end
		menu:Open()
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Net receivers
-- ─────────────────────────────────────────────────────────────────────────────
net.Receive("sls_staff_open", function(len)
	OpenStaffPanel()
end)

-- Confirmed scare sent to the client for chat feedback
net.Receive("sls_spectator_scare", function(len)
	local success = net.ReadBool()
	if success then
		chat.AddText(Color(180, 40, 40), "[Staff] ", Color(220, 220, 220), "You spooked your target!")
	end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Spectator input: +reload while in OBS_MODE_CHASE triggers scare
-- ─────────────────────────────────────────────────────────────────────────────
hook.Add("KeyPress", "sls_SpectatorScare", function(ply, key)
	if key ~= IN_RELOAD then return end
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED then return end
	if ply:IsAdmin() == false and ply:IsSuperAdmin() == false then return end

	local obsTarget = ply:GetObserverTarget()
	if ply:GetObserverMode() ~= OBS_MODE_CHASE or not IsValid(obsTarget) then return end

	net.Start("sls_spectator_scare")
	net.SendToServer()
end)
