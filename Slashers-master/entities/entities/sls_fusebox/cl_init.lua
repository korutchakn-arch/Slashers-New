-- Slashers — Jason Fuse Box Entity (Client)
-- @Author: Claude (Execution Agent)
-- @Date:   2026-07-05
-- @Last Modified by:   Claude
-- @Last Modified time: 2026-07-05

include("shared.lua")
ENT.RenderGroup = RENDERGROUP_BOTH

------------------------------------------------------------
-- Local state for fusebox interaction progress HUD
------------------------------------------------------------
local fuseboxProgress     = 0
local fuseboxActiveEntity = NULL

------------------------------------------------------------
-- Receive progress updates from server
-- Float:  0 = idle, 0–1 = in-progress, 2 = completed/destroyed
-- Entity: which fusebox this update belongs to
------------------------------------------------------------
net.Receive("sls_kability_fusebox_progress", function(len)
    local progress = net.ReadFloat()
    local ent      = net.ReadEntity()

    if not IsValid(ent) then return end

    if ent == fuseboxActiveEntity or progress == 0 then
        fuseboxProgress     = progress
        fuseboxActiveEntity = (progress == 0) and NULL or ent
    end
end)

------------------------------------------------------------
-- ENT:Initialize
------------------------------------------------------------
function ENT:Initialize()
    self.Destroyed = false
end

------------------------------------------------------------
-- ENT:Draw — draw the model
------------------------------------------------------------
function ENT:Draw()
    self.Entity:DrawModel()
end

------------------------------------------------------------
-- ENT:DrawTranslucent — show [E] indicator for Jason
------------------------------------------------------------
function ENT:DrawTranslucent()
    local lp = LocalPlayer()
    if lp:Team() ~= TEAM_KILLER then return end

    local fuseEnt = self.Entity
    if not IsValid(fuseEnt) then return end
    if fuseEnt:GetNWBool("destroyed", false) then return end

    local dist = fuseEnt:GetPos():Distance(lp:GetPos())
    if dist < 150 and lp:IsLineOfSightClear(fuseEnt) then
        DrawIndicator(fuseEnt)
    end
end

------------------------------------------------------------
-- HUDPaint — draw the 5-second progress bar at the bottom-center
-- Only shown when Jason is holding [E] on a fusebox (progress 0–1).
------------------------------------------------------------
hook.Add("HUDPaint", "sls_fusebox_HUD", function()
    local lp = LocalPlayer()
    if lp:Team() ~= TEAM_KILLER then return end
    if fuseboxProgress <= 0 or fuseboxProgress >= 2 then return end

    local progress = fuseboxProgress

    local barW  = 400
    local barH  = 24
    local x     = ScrW() * 0.5 - barW * 0.5
    local y     = ScrH() - 80
    local corner = 4

    -- Background
    draw.RoundedBox(corner, x, y, barW, barH, Color(20, 20, 20, 210))

    -- Fill
    draw.RoundedBox(corner, x, y, barW * progress, barH, Color(220, 30, 30, 255))

    -- Border
    surface.SetDrawColor(255, 255, 255, 180)
    surface.DrawOutlinedRect(x, y, barW, barH)

    -- Label
    draw.SimpleText("POWER CUT", "DermaDefaultBold", ScrW() * 0.5, y - 18, Color(220, 30, 30, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText("Hold [E]", "DermaDefault", ScrW() * 0.5, y + barH + 6, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
