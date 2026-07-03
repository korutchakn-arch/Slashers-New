-- Slashers — Survivor Setup Pipeline (Client)
-- Blue-themed class selection UI for survivors.
-- Mirrors the visual style of killer_setup/cl_setup.lua.

local GM = GM or GAMEMODE

-- ─────────────────────────────────────────────
-- Shared UI constants (blue survivor theme)
-- ─────────────────────────────────────────────
local FRAME_PAD  = 16
local TITLE_H    = 56
local CARD_W     = 260
local CARD_H     = 340
local COL_GAP    = 20
local ROW_GAP    = 16
local COLS       = 3
local FOOTER_H   = 12

-- Colour palette (blue/survivor theme)
local CLR_BG      = Color(4, 8, 16, 245)
local CLR_BORDER  = Color(25, 60, 140, 255)
local CLR_BORDER2 = Color(15, 40, 100, 100)
local CLR_TITLEBG = Color(18, 50, 120, 200)
local CLR_CARDBG  = Color(8, 16, 32, 255)
local CLR_CARDBDR = Color(20, 55, 130, 200)
local CLR_UNKNOWN = Color(30, 60, 120, 120)
local CLR_NAME    = Color(80, 160, 255, 255)
local CLR_DESC    = Color(180, 200, 230, 255)
local CLR_BTN_NORM= Color(15, 45, 100)
local CLR_BTN_HOV = Color(25, 70, 150)
local CLR_BTN_BDR = Color(40, 90, 180, 180)
local CLR_BTN_HBDR= Color(80, 140, 240)
local CLR_BTN_TXT = Color(230, 240, 255)
local CLR_TAKEN_BG= Color(30, 30, 40, 230)
local CLR_TAKEN_BDR= Color(60, 60, 80, 200)
local CLR_TAKEN_TXT= Color(120, 120, 140, 255)
local CLR_DENIED_TXT= Color(255, 80, 80, 255)

-- ─────────────────────────────────────────────
-- Open Character Selection Menu
-- ─────────────────────────────────────────────
local TakenSurvClasses = {}

local function OpenCharSelectMenu()
    if IsValid(SlashersSurvCharFrame) then
        SlashersSurvCharFrame:Remove()
    end

    local chars  = GM.SurvivorClasses
    local numChars = table.Count(chars)
    local rows    = math.ceil(numChars / COLS)
    local baseFrameW = COLS * CARD_W + (COLS - 1) * COL_GAP + FRAME_PAD * 2
    local frameW  = baseFrameW + 16 -- add room for scrollbar
    local fullFrameH = FRAME_PAD + TITLE_H + 16 + rows * CARD_H + (rows - 1) * ROW_GAP + FOOTER_H + FRAME_PAD
    local frameH = math.min(fullFrameH, ScrH() * 0.85)

    local frame = vgui.Create("DFrame")
    frame:SetSize(frameW, frameH)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    SlashersSurvCharFrame = frame

    frame.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, CLR_BG)
        surface.SetDrawColor(CLR_BORDER)
        surface.DrawOutlinedRect(0, 0, w, h)
        surface.SetDrawColor(CLR_BORDER2)
        surface.DrawOutlinedRect(3, 3, w - 6, h - 6)
    end

    -- Title bar
    local titlePanel = vgui.Create("DPanel", frame)
    titlePanel:SetPos(FRAME_PAD, FRAME_PAD)
    titlePanel:SetSize(frameW - FRAME_PAD * 2, TITLE_H)
    titlePanel.Paint = function(s, w, h)
        surface.SetDrawColor(CLR_TITLEBG)
        surface.DrawRect(0, h - 4, w, 4)
        draw.SimpleText("CHOOSE YOUR CLASS", "horror1", w / 2, h / 2, CLR_NAME, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- ─── Countdown timer panel ───
    local TIMER_DURATION = 10
    local timeLeft = TIMER_DURATION

    local timerPanel = vgui.Create("DPanel", frame)
    timerPanel:SetPos(frameW - FRAME_PAD - 80, FRAME_PAD + 8)
    timerPanel:SetSize(80, TITLE_H - 16)
    timerPanel.Paint = function(s, w, h)
        local frac = timeLeft / TIMER_DURATION
        -- Colour shifts blue → orange → white as time runs out
        local r = frac < 0.3 and 255 or math.floor(40 + (1 - frac) * 180)
        local g = frac < 0.3 and math.floor(frac * 200) or math.floor(120 + (1 - frac) * 100)
        local b = frac < 0.3 and math.floor(frac * 80) or math.floor(220 - (1 - frac) * 100)
        draw.RoundedBox(4, 0, 0, w, h, Color(4, 8, 24, 220))
        surface.SetDrawColor(20, 60, 140, 180)
        surface.DrawOutlinedRect(0, 0, w, h)
        draw.SimpleText("0:" .. string.format("%02d", timeLeft), "horror1", w / 2, h / 2, Color(r, g, b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local timerThink = 0
    hook.Add("Think", "sls_SurvSelectTimer", function()
        if not IsValid(frame) then
            hook.Remove("Think", "sls_SurvSelectTimer")
            return
        end
        timerThink = timerThink + FrameTime()
        if timerThink >= 1 then
            timerThink = 0
            timeLeft = timeLeft - 1
            if timeLeft <= 0 then
                timeLeft = 0
                hook.Remove("Think", "sls_SurvSelectTimer")
            end
        end
    end)

    -- Scrollable Card grid
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, FRAME_PAD + TITLE_H + 16)
    scroll:SetSize(frameW, frameH - (FRAME_PAD + TITLE_H + 16) - FOOTER_H - FRAME_PAD)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(8)
    sbar.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, Color(4, 8, 24, 200)) end
    sbar.btnUp.Paint = function(s, w, h) end
    sbar.btnDown.Paint = function(s, w, h) end
    sbar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, CLR_BORDER) end

    local charList = {}
    for k, v in pairs(chars) do
        table.insert(charList, {key = k, data = v})
    end

    local idx = 0
    for _, entry in ipairs(charList) do
        local col   = idx % COLS
        local row   = math.floor(idx / COLS)
        local cardX = FRAME_PAD + col * (CARD_W + COL_GAP)
        local cardY = row * (CARD_H + ROW_GAP)
        idx = idx + 1

        -- Get the class data from GM.CLASS.Survivors for display info
        local classID  = entry.data.key
        local survData = GM.CLASS.Survivors[classID]
        if not survData then continue end

        local card = vgui.Create("DPanel", scroll)
        card:SetPos(cardX, cardY)
        card:SetSize(CARD_W, CARD_H)
        card:SetPaintBackground(false)

        -- Portrait silhouette panel
        local portrait = vgui.Create("DPanel", card)
        portrait:SetPos(0, 0)
        portrait:SetSize(CARD_W, 180)
        portrait.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, CLR_CARDBG)
            surface.SetDrawColor(CLR_CARDBDR)
            surface.DrawOutlinedRect(0, 0, w, h)
            -- Show class icon if available.
            -- survData.icon may be a pre-cached IMaterial OR a legacy string path —
            -- handle both without passing userdata into Material(), which would crash.
            if survData.icon then
                local icon
                local iconType = type(survData.icon)
                if iconType == "IMaterial" then
                    -- Already a cached material object — use it directly.
                    icon = survData.icon
                elseif iconType == "string" then
                    -- Legacy string path — resolve it now.
                    icon = Material(survData.icon)
                end

                if icon and not icon:IsError() then
                    local iconSize = 96
                    local ix = (w - iconSize) / 2
                    local iy = (h - iconSize) / 2
                    surface.SetDrawColor(255, 255, 255, 200)
                    surface.SetMaterial(icon)          -- bind texture before drawing
                    surface.DrawTexturedRect(ix, iy, iconSize, iconSize)
                    return
                end
            end
            draw.SimpleText("???", "horrortext", w / 2, h / 2, CLR_UNKNOWN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Class name label
        local nameLabel = vgui.Create("DLabel", card)
        nameLabel:SetPos(0, 184)
        nameLabel:SetSize(CARD_W, 28)
        nameLabel:SetFont("DermaDefaultBold")
        nameLabel:SetText(survData.name:upper())
        nameLabel:SetContentAlignment(5)
        nameLabel:SetTextColor(CLR_NAME)

        -- Short description from our registry
        local descText = entry.data.short_desc or ""
        local descLabel = vgui.Create("DLabel", card)
        descLabel:SetPos(8, 212)
        descLabel:SetSize(CARD_W - 16, 70)
        descLabel:SetFont("ChatFont")
        descLabel:SetText(descText)
        descLabel:SetContentAlignment(5)
        descLabel:SetTextColor(CLR_DESC)
        descLabel:SetWrap(true)

        -- Stats panel
        local statsLabel = vgui.Create("DLabel", card)
        statsLabel:SetPos(8, 268)
        statsLabel:SetSize(CARD_W - 16, 50)
        statsLabel:SetFont("ChatFont")
        local statsText = string.format(
            "HP: %d  |  Stam: %d  |  Spd: %d / %d",
            survData.life or 100,
            survData.stamina or 100,
            survData.walkspeed or 150,
            survData.runspeed or 240
        )
        statsLabel:SetText(statsText)
        statsLabel:SetContentAlignment(5)
        statsLabel:SetTextColor(Color(140, 170, 210, 200))
        statsLabel:SetWrap(true)

        -- Special weapons indicator
        if survData.weapons and #survData.weapons > 0 then
            local wepLabel = vgui.Create("DLabel", card)
            wepLabel:SetPos(8, 308)
            wepLabel:SetSize(CARD_W - 16, 20)
            wepLabel:SetFont("ChatFont")
            wepLabel:SetText("Special: " .. table.concat(survData.weapons, ", "))
            wepLabel:SetContentAlignment(5)
            wepLabel:SetTextColor(Color(100, 200, 120, 200))
        end

        -- ── Taken-state management ─────────────────────────────────────────
        -- Each card tracks its own taken status so it can update in real time.
        local isTaken = false

        local function SetCardTaken(taken)
            if taken == isTaken then return end
            isTaken = taken
            selectBtn:SetEnabled(not taken)
            selectBtn:InvalidateLayout()
        end

        -- Initial state: lock it now if this class is already taken
        if TakenSurvClasses[classID] then
            SetCardTaken(true)
        end

        -- ── Select button ──────────────────────────────────────────────────
        local selectBtn = vgui.Create("DButton", card)
        selectBtn:SetPos(10, CARD_H - 40)
        selectBtn:SetSize(CARD_W - 20, 30)
        selectBtn:SetText("")
        selectBtn.Paint = function(s, w, h)
            if isTaken then
                -- Dark grey "TAKEN" appearance — no hover change
                draw.RoundedBox(4, 0, 0, w, h, CLR_TAKEN_BG)
                surface.SetDrawColor(CLR_TAKEN_BDR)
                surface.DrawOutlinedRect(0, 0, w, h)
                draw.SimpleText("TAKEN", "horror1", w / 2, h / 2, CLR_TAKEN_TXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                local hovered = s:IsHovered()
                draw.RoundedBox(4, 0, 0, w, h, hovered and CLR_BTN_HOV or CLR_BTN_NORM)
                surface.SetDrawColor(hovered and CLR_BTN_HBDR or CLR_BTN_BDR)
                surface.DrawOutlinedRect(0, 0, w, h)
                draw.SimpleText("SELECT", "horror1", w / 2, h / 2, CLR_BTN_TXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        local entryCopy = entry
        selectBtn.DoClick = function()
            net.Start("sls_surv_selectclass")
            net.WriteString(entryCopy.key)
            net.SendToServer()
            -- Show black screen while waiting for all players to finish setup.
            GAMEMODE.ROUND.SetupWaiting = true
            frame:Close()
        end

        -- Store the per-card update function so the global sync hook can call it.
        -- card is the DPanel created at line 145 and is unique per card.
        frame._takenUpdaters = frame._takenUpdaters or {}
        frame._takenUpdaters[classID] = SetCardTaken
    end
end

-- ─────────────────────────────────────────────
-- Net receivers
-- ─────────────────────────────────────────────
net.Receive("sls_surv_opencharselect", function(len)
    OpenCharSelectMenu()
end)

-- Cache of chosen survivor classes for display purposes
local ChosenSurvClasses = {}

net.Receive("sls_surv_sync_class", function(len)
    local ply     = net.ReadEntity()
    local classKey = net.ReadString()
    if not IsValid(ply) then return end
    ChosenSurvClasses[ply:SteamID()] = classKey
end)

-- Expose to other client files if needed
function GM.GetSurvChosenClass(ply)
    if not IsValid(ply) then return nil end
    return ChosenSurvClasses[ply:SteamID()]
end

-- ─────────────────────────────────────────────
-- Taken-class tracking — mirrors the server's TakenSurvClasses table.
-- Updated whenever a class is successfully locked by any player.
-- Used to drive per-card SetCardTaken(true) in real time.
-- ─────────────────────────────────────────────
-- (Declaration moved to top of file)

net.Receive("sls_surv_sync_taken_classes", function(len)
    local count = net.ReadUInt(8)
    -- Rebuild from scratch each broadcast to keep in sync.
    TakenSurvClasses = {}
    for i = 1, count do
        local key = net.ReadString()
        TakenSurvClasses[key] = true
    end

    -- If the character select menu is open, update all card buttons immediately.
    if IsValid(SlashersSurvCharFrame) and SlashersSurvCharFrame._takenUpdaters then
        for classID, updater in pairs(SlashersSurvCharFrame._takenUpdaters) do
            updater(TakenSurvClasses[classID] == true)
        end
    end
end)

-- ─────────────────────────────────────────────
-- Class selection timeout — server watchdog closed the menu
-- ─────────────────────────────────────────────
net.Receive("sls_surv_classsetup_timeout", function(len)
    -- Show black screen while waiting for all players to finish setup.
    GAMEMODE.ROUND.SetupWaiting = true
    if IsValid(SlashersSurvCharFrame) then
        SlashersSurvCharFrame:Remove()
    end
    SlashersSurvCharFrame = nil
    hook.Remove("Think", "sls_SurvSelectTimer")
    print("[Surv-Setup] Survivor class menu auto-closed (timeout).")
end)

-- ─────────────────────────────────────────────
-- Denial handler — server rejected the player's class pick because
-- it was already taken. Shows a brief red flash label over the frame
-- then re-enables selection so they can pick a different character.
-- ─────────────────────────────────────────────
net.Receive("sls_surv_class_denied", function(len)
    local classKey = net.ReadString()
    if not IsValid(SlashersSurvCharFrame) then return end

    -- Clear the waiting state so the player can pick again.
    GAMEMODE.ROUND.SetupWaiting = false

    -- Briefly show a denial message centred on the frame.
    local deniedLabel = vgui.Create("DLabel", SlashersSurvCharFrame)
    local fw, fh = SlashersSurvCharFrame:GetSize()
    deniedLabel:SetPos(0, fh / 2 - 30)
    deniedLabel:SetSize(fw, 60)
    deniedLabel:SetFont("TargetID")
    deniedLabel:SetContentAlignment(5)
    deniedLabel:SetText("That class has already been taken.\nPlease choose another.")
    deniedLabel:SetTextColor(CLR_DENIED_TXT)
    deniedLabel:SetPaintBackground(true)
    deniedLabel:SetBGColor(0, 0, 0, 180)

    -- Auto-remove after 2 seconds.
    timer.Simple(2, function()
        if IsValid(deniedLabel) then
            deniedLabel:Remove()
        end
    end)

    print("[Surv-Setup] Class selection denied for class key: " .. classKey)
end)
