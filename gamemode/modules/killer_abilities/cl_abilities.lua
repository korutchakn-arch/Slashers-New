-- Slashers — Killer Abilities (Client)
-- All client-side HUD rendering, post-process effects, and net message handlers.

local GM = GM or GAMEMODE

-----------------------------------------------------------
-- GHOSTFACE — Door icons on HUD
-- Material: icons/icon_door.png
-----------------------------------------------------------

local ghostface_doors = {}

net.Receive("sls_kability_AddDoor", function(len)
    local pos = net.ReadVector()
    local endtime = net.ReadInt(16)
    table.insert(ghostface_doors, {
        pos     = pos,
        endtime = endtime,
    })
end)

local ICON_DOOR_GHOSTFACE = Material("icons/icon_door.png")

local function KA_ghostface_HUDPaintBackground()
    if LocalPlayer():Team() ~= TEAM_KILLER then return end
    local curtime = CurTime()

    for k, v in ipairs(ghostface_doors) do
        if curtime > v.endtime then
            table.remove(ghostface_doors, k)
            continue
        end
        local pos1 = v.pos:ToScreen()
        surface.SetDrawColor(Color(255, 255, 255))
        surface.SetMaterial(ICON_DOOR_GHOSTFACE)
        surface.DrawTexturedRect(pos1.x - 64, pos1.y - 64, 128, 128)
    end
end
hook.Add("HUDPaintBackground", "sls_ka_ghostface_HUDPaintBackground", KA_ghostface_HUDPaintBackground)

local function KA_ghostface_PreStart()
    ghostface_doors = {}
end
hook.Add("sls_round_PreStart", "sls_ka_ghostface_PreStart", KA_ghostface_PreStart)

local function KA_ghostface_End()
    ghostface_doors = {}
end
hook.Add("sls_round_End", "sls_ka_ghostface_End", KA_ghostface_End)

-----------------------------------------------------------
-- JASON — 3D Footprint rendering
-- Material: icons/footsteps.png
-----------------------------------------------------------

local jason_steps = {}

net.Receive("sls_kability_AddStep", function(len)
    local ply = net.ReadEntity()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local endtime = net.ReadInt(16)

    ang.p = 0
    ang.r = 0

    -- Offset left/right per step to simulate alternating feet
    local fpos = pos
    if ply.LastFoot then
        fpos = fpos + ang:Right() * 5
    else
        fpos = fpos + ang:Right() * -5
    end
    ply.LastFoot = not ply.LastFoot

    local trace = {}
    trace.start   = fpos
    trace.endpos  = fpos + Vector(0, 0, -10)
    trace.filter  = ply
    local tr = util.TraceLine(trace)

    if tr.Hit then
        table.insert(jason_steps, {
            pos     = tr.HitPos,
            endtime = endtime,
            angle   = ang.y,
            normal  = Vector(0, 0, 1),
        })
    end
end)

local ICON_STEP_JASON = Material("icons/footsteps.png")
local maxDistSqr = 600 * 600

local function KA_jason_PostDrawTranslucentRenderables()
    local pos = EyePos()

    cam.Start3D(pos, EyeAngles())
        render.SetMaterial(ICON_STEP_JASON)
        for k, v in ipairs(jason_steps) do
            if CurTime() > v.endtime then
                table.remove(jason_steps, k)
                continue
            end
            if (v.pos - pos):LengthSqr() < maxDistSqr then
                render.DrawQuadEasy(v.pos + v.normal, v.normal, 10, 20, Color(255, 255, 255), v.angle)
            end
        end
    cam.End3D()
end
hook.Add("PostDrawTranslucentRenderables", "sls_ka_jason_PostDrawTranslucentRenderables", KA_jason_PostDrawTranslucentRenderables)

local function KA_jason_PreStart()
    jason_steps = {}
end
hook.Add("sls_round_PreStart", "sls_ka_jason_PreStart", KA_jason_PreStart)

local function KA_jason_End()
    jason_steps = {}
end
hook.Add("sls_round_End", "sls_ka_jason_End", KA_jason_End)

-----------------------------------------------------------
-- MYERS — Target icon + wallhack status sounds
-- Material: icons/icon_target.png
-----------------------------------------------------------

local myers_victimPos = nil

net.Receive("sls_kability_update_myersability", function(len)
    local status = net.ReadInt(2)
    if status == 2 then
        -- Ability available
    elseif status == 1 then
        surface.PlaySound("slashers/effects/michael_ability_on.wav")
    elseif status == 0 then
        -- Deactivated
    end
end)

net.Receive("sls_kability_Wallhack", function(len)
    local tempPos = net.ReadVector()
    if tempPos == Vector(42, 42, 42) then
        myers_victimPos = nil
    else
        myers_victimPos = tempPos
    end
end)

local ICON_TARGET_MYERS = Material("icons/icon_target.png")

local function KA_myers_HUDPaintBackground()
    if LocalPlayer():Team() ~= TEAM_KILLER or not GM.ROUND.Active or not myers_victimPos then return end
    local pos = myers_victimPos:ToScreen()
    surface.SetDrawColor(Color(255, 255, 255))
    surface.SetMaterial(ICON_TARGET_MYERS)
    surface.DrawTexturedRect(pos.x - 64, pos.y - 64, 128, 128)
    -- Also draw the static icon in the top-right corner
    surface.DrawTexturedRect(ScrW() - 110, 10, 100, 100)
end
hook.Add("HUDPaintBackground", "sls_ka_myers_HUDPaintBackground", KA_myers_HUDPaintBackground)

local function KA_myers_PreStart()
    myers_victimPos = nil
end
hook.Add("sls_round_PreStart", "sls_ka_myers_PreStart", KA_myers_PreStart)

local function KA_myers_End()
    myers_victimPos = nil
end
hook.Add("sls_round_End", "sls_ka_myers_End", KA_myers_End)

-----------------------------------------------------------
-- PROXY — Invisibility visual effect + killer icon for shy girl
-- Effect:  DrawMaterialOverlay + DrawSharpen when invisible
-- Indicator: proxy icon shown to shy girl when killer in LoS
-----------------------------------------------------------

local proxy_PlyInvisible = false
local proxy_Visible      = false
local proxyPos           = nil
local proxyShowIcon      = false
local proxyTimerView     = 0

-- Reset all Proxy client state at round boundaries to prevent the
-- invisibility post-process effect from bleeding into the next round
-- (e.g. when an admin force-restarts mid-invisibility).
local function KA_proxy_Reset()
    proxy_PlyInvisible = false
    proxy_Visible     = false
end
hook.Add("sls_round_PreStart", "sls_ka_proxy_Reset", KA_proxy_Reset)
hook.Add("sls_round_End",     "sls_ka_proxy_Reset", KA_proxy_Reset)

net.Receive("sls_kability_Invisible", function(len)
    proxy_PlyInvisible = net.ReadBool()
end)

net.Receive("sls_kability_InvisibleIndic", function(len)
    proxy_Visible = net.ReadBool()
end)

-- When invisible, apply a post-process overlay for the killer
local function KA_proxy_InvisibleVision()
    if not GM.ROUND.Active or not GM.ROUND.Survivors then return end
    if LocalPlayer():Team() ~= TEAM_KILLER then return end
    if proxy_PlyInvisible and LocalPlayer():Alive() then
        DrawMaterialOverlay("effects/dodge_overlay.vmt", -0.42)
        DrawSharpen(1.2, 1.2)
    end
end
hook.Add("RenderScreenspaceEffects", "sls_ka_proxy_InvisibleVision", KA_proxy_InvisibleVision)

-- Shy girl client: tell server when she sees the killer (so killer can stay visible)
local function KA_proxy_CheckKillerInSight()
    local killer = team.GetPlayers(TEAM_KILLER)[1]
    if not IsValid(killer) then return end
    local ply = LocalPlayer()
    local curtime = CurTime()

    if not ply:Alive() or killer == ply or not ply:IsLineOfSightClear(killer) then return end

    local TargetPosMax    = killer:GetPos() + killer:OBBMaxs() - Vector(10, 0, 0)
    local TargetPosCenter = killer:GetPos() + killer:OBBCenter()
    local TargetPosMin    = killer:GetPos() + killer:OBBMins() + Vector(10, 0, 0)

    local ScreenPosMax    = TargetPosMax:ToScreen()
    local ScreenPosCenter = TargetPosCenter:ToScreen()
    local ScreenPosMin    = TargetPosMin:ToScreen()

    local posPlayer = ply:GetPos()
    if proxyTimerView < curtime and posPlayer:Distance(killer:GetPos()) < 150 then
        net.Start("sls_kability_survivorseekiller")
            net.WriteFloat(curtime)
        net.SendToServer()
        proxyTimerView = curtime + 0.2

    elseif proxyTimerView < curtime
       and ScreenPosMax.x < ScrW() and ScreenPosMax.y < ScrH()
       and ScreenPosMin.x > 0 and ScreenPosMin.y > 0 then
        net.Start("sls_kability_survivorseekiller")
            net.WriteFloat(curtime)
        net.SendToServer()
        proxyTimerView = curtime + 0.2
    end
end
hook.Add("Think", "sls_ka_proxy_CheckKillerInSight", KA_proxy_CheckKillerInSight)

-- Receive killer position when invisible (shown only to shy girl)
net.Receive("sls_proxy_sendpos", function(len)
    proxyPos      = net.ReadVector()
    proxyShowIcon = net.ReadBool()
end)

-- Draw proxy icon for shy girl when she has LoS to invisible killer
local function KA_proxy_drawIconOnProxy()
    if not proxyShowIcon or not proxyPos then return end
    if LocalPlayer().ClassID ~= CLASS_SURV_SHY then return end

    local pos = proxyPos:ToScreen()
    local iconMat = GM.MAP.Killer.Icon or Material("icons/icon_proxy.png")
    surface.SetDrawColor(Color(255, 255, 255))
    surface.SetMaterial(iconMat)
    surface.DrawTexturedRect(pos.x - 64, pos.y - 64, 64, 64)
end
hook.Add("HUDPaintBackground", "sls_ka_proxy_drawIconOnProxy", KA_proxy_drawIconOnProxy)

-----------------------------------------------------------
-- BATES — Mother radar visual warning
-- Indicator: colored circle + text in top-right, Killer only
-----------------------------------------------------------

local bates_distLevel = 0

-- Received from server when survivor→mother distance changes (0–3)
net.Receive("sls_motherradar", function(len)
    bates_distLevel = net.ReadUInt(2)
end)

local ICON_TARGET_BATES = Material("icons/icon_target.png")

local function KA_bates_HUDPaint()
    if bates_distLevel == 0 then return end
    if LocalPlayer():Team() ~= TEAM_KILLER then return end

    local col
    if bates_distLevel == 1 then
        col = Color(220, 180, 0)   -- Yellow
    elseif bates_distLevel == 2 then
        col = Color(220, 90, 0)    -- Orange
    else
        col = Color(200, 30, 30)   -- Red (level 3)
    end

    local x = ScrW() - 110
    local y = 10
    local sz = 96

    -- Filled circle background
    draw.RoundedBox(sz / 2, x, y, sz, sz, col)

    -- Target icon centred inside
    surface.SetDrawColor(Color(255, 255, 255))
    surface.SetMaterial(ICON_TARGET_BATES)
    surface.DrawTexturedRect(x, y, sz, sz)

    -- Proximity label
    local label = bates_distLevel == 1 and "LOW" or bates_distLevel == 2 and "MEDIUM" or "HIGH"
    draw.SimpleText(label, "DermaDefaultBold", x + sz / 2, y + sz + 12, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end
hook.Add("HUDPaintBackground", "sls_ka_bates_HUDPaint", KA_bates_HUDPaint)

-- Reset radar when round ends
local function KA_bates_End()
    bates_distLevel = 0
end
hook.Add("sls_round_End", "sls_ka_bates_End", KA_bates_End)

-----------------------------------------------------------
-- INTRUDER — Red halo around nearby traps for shy girl
-- Net: sls_trapspos
-----------------------------------------------------------

local intruder_trapsEntity = {}

net.Receive("sls_trapspos", function(len)
    intruder_trapsEntity = net.ReadTable()
end)

local function KA_intruder_AddHalos()
    if LocalPlayer().ClassID ~= CLASS_SURV_SHY then return end
    if #intruder_trapsEntity == 0 then return end
    halo.Add(intruder_trapsEntity, Color(255, 0, 0), 5, 5, 2)
end
hook.Add("PreDrawHalos", "sls_ka_intruder_AddHalos", KA_intruder_AddHalos)

-----------------------------------------------------------
-- GHOSTFACE (Phone) — Furthest survivor position reveal
-- Net: sls_ghostface_phone_reveal
-- HUD: Skull icon + survivor name drawn at world-to-screen pos
-- Cleared on: sls_round_PreStart / sls_round_End
-----------------------------------------------------------

local ghostface_phoneRevealPos  = nil  -- Vector: head-level world position of the target
local ghostface_phoneRevealName = ""   -- Nick of the called survivor
local ghostface_phoneRevealEnd  = 0    -- CurTime() when the marker expires

-- Duration (seconds) the reveal marker stays on Ghostface's HUD after the call
local PHONE_REVEAL_HUD_DURATION = 8

local ICON_PHONE_REVEAL = Material("icons/icon_target.png") -- reuse target icon (same as Myers)

net.Receive("sls_ghostface_phone_reveal", function()
    ghostface_phoneRevealPos  = net.ReadVector()
    ghostface_phoneRevealName = net.ReadString()
    ghostface_phoneRevealEnd  = CurTime() + PHONE_REVEAL_HUD_DURATION
end)

--[[
    KA_ghostface_phone_HUDPaintBackground
    Draws a skull/target icon + survivor name at the screen position
    corresponding to the revealed survivor's head.
    Only visible to Ghostface (TEAM_KILLER) during the reveal window.
    Mirrors Myers' KA_myers_HUDPaintBackground exactly, with an extra
    name label for better feedback.
]]
local function KA_ghostface_phone_HUDPaintBackground()
    if LocalPlayer():Team() ~= TEAM_KILLER then return end
    if not ghostface_phoneRevealPos then return end
    if CurTime() > ghostface_phoneRevealEnd then
        ghostface_phoneRevealPos  = nil
        ghostface_phoneRevealName = ""
        return
    end

    local screenPos = ghostface_phoneRevealPos:ToScreen()
    if not screenPos.visible then return end -- skip when behind camera

    local iconSize = 64

    -- Draw target icon centred on the survivor's world position
    surface.SetDrawColor(Color(255, 60, 60, 220))
    surface.SetMaterial(ICON_PHONE_REVEAL)
    surface.DrawTexturedRect(screenPos.x - iconSize * 0.5, screenPos.y - iconSize * 0.5, iconSize, iconSize)

    -- Draw survivor name below the icon
    draw.SimpleTextOutlined(
        ghostface_phoneRevealName,
        "DermaDefaultBold",
        screenPos.x,
        screenPos.y + iconSize * 0.5 + 4,
        Color(255, 60, 60, 220),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,
        1,
        Color(0, 0, 0, 180)
    )

    -- Draw a small pulsing corner indicator so Ghostface knows the ability fired
    local pulseAlpha = math.abs(math.sin(CurTime() * 3)) * 200 + 55
    surface.SetDrawColor(Color(255, 60, 60, pulseAlpha))
    surface.SetMaterial(ICON_PHONE_REVEAL)
    surface.DrawTexturedRect(ScrW() - 110, 10, 96, 96)
end
hook.Add("HUDPaintBackground", "sls_ka_ghostface_phone_HUDPaintBackground", KA_ghostface_phone_HUDPaintBackground)

-- Clear state at round boundaries (prevents stale markers across rounds)
local function KA_ghostface_phone_ResetReveal()
    ghostface_phoneRevealPos  = nil
    ghostface_phoneRevealName = ""
    ghostface_phoneRevealEnd  = 0
end
hook.Add("sls_round_PreStart", "sls_ka_ghostface_phone_PreStart", KA_ghostface_phone_ResetReveal)
hook.Add("sls_round_End",      "sls_ka_ghostface_phone_End",      KA_ghostface_phone_ResetReveal)

