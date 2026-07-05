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
    if not IsValid(fuseEnt) or fuseEnt:GetNWBool("destroyed", false) then return end

    local dist = fuseEnt:GetPos():Distance(lp:GetPos())

    if dist < 300 then
        -- Smooth alpha fade: full opacity ≤150u, fades to 0 at 300u
        local alpha = 255
        if dist > 150 then
            alpha = 255 * (1 - ((dist - 150) / 150))
        end

        -- Center of the fusebox + float 12 units outward from the front face
        local center = fuseEnt:LocalToWorld(fuseEnt:OBBCenter())
        local pos = center + (fuseEnt:GetAngles():Forward() * 12)

        -- Align drawing plane perfectly with the box's orientation
        local drawAng = fuseEnt:GetAngles()

        -- 1. Align text left-to-right along the wall
        drawAng:RotateAroundAxis(drawAng:Up(), 90)

        -- 2. Flip the drawing plane vertically so it faces outward (Normal = Out, Y-axis = Down)
        drawAng:RotateAroundAxis(drawAng:Forward(), 90)

        cam.Start3D2D(pos, drawAng, 0.1)
            cam.IgnoreZ(true) -- Draw over geometry so text is never clipped by the fusebox model
            draw.SimpleText("FUSE BOX", "Bohemian typewriter STITLE", 0, -30, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("[ E ] POWER CUT", "horrormid", 0, 15, Color(220, 220, 220, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.IgnoreZ(false)
        cam.End3D2D()
    end
end

------------------------------------------------------------
-- HUDPaint — draw the 5-second progress bar at the bottom-center
-- Only shown when Jason is holding [E] on a fusebox (progress 0–1).
------------------------------------------------------------
hook.Add("HUDPaint", "sls_fusebox_HUD", function()
    local lp = LocalPlayer()
    -- EyeTrace: Jason must be looking at this entity to press E,
    -- so GetNWFloat on the looked-at entity is sufficient for HUD display.
    local tr       = lp:GetEyeTrace()
    local ent      = tr.Entity
    if not IsValid(ent) or ent:GetClass() ~= "sls_fusebox" then return end
    if lp:Team() ~= TEAM_KILLER then return end

    local progress = ent:GetNWFloat("progress", 0)
    if progress <= 0 or progress >= 2 then return end

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
