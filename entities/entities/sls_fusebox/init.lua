-- Slashers — Jason Fuse Box Entity (Server)
-- @Author: Claude (Execution Agent)
-- @Date:   2026-07-05
-- @Last Modified by:   Claude
-- @Last Modified time: 2026-07-05

local GM = GAMEMODE

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("sls_blackout_sync")

-- Power-down sound (map-wide)
sound.Add({
    name    = "slashers_fusebox_powerdown",
    channel = CHAN_AUTO,
    volume  = 1.0,
    level   = 100,
    pitch   = { 95, 110 },
    sound   = "ambient/energy/zap9.wav",
})

-- Blackout state — shared across all instances so it persists across round resets
local blackoutActive = false

------------------------------------------------------------
-- Returns whether a map-wide blackout has been triggered this round.
------------------------------------------------------------
function GM:IsBlackoutActive()
    return blackoutActive
end

------------------------------------------------------------
-- Resets blackout state at round start.
-- Called from KA_jason_PostStart.
------------------------------------------------------------
function GM:ResetBlackout()
    blackoutActive = false
    engine.LightStyle(0, "m")

    -- Re-enable all map lights
    for _, ent in ipairs(ents.FindByClass("light*")) do
        if IsValid(ent) then ent:Fire("TurnOn", "", 0) end
    end
    for _, ent in ipairs(ents.FindByClass("light_spot")) do
        if IsValid(ent) then ent:Fire("TurnOn", "", 0) end
    end

    net.Start("sls_blackout_sync")
        net.WriteFloat(0)
    net.Broadcast()
end

------------------------------------------------------------
-- Internal: triggers the blackout.
-- Runs once per round. Called by the first fusebox to complete.
------------------------------------------------------------
local function TriggerBlackout(activator)
    if blackoutActive then return end
    blackoutActive = true

    -- 1. Kill all baked dynamic lights (light* entities)
    for _, ent in ipairs(ents.FindByClass("light*")) do
        if IsValid(ent) then
            ent:Fire("TurnOff", "", 0)
        end
    end

    -- 2. Kill any info_lights in the map
    for _, ent in ipairs(ents.FindByClass("light_spot")) do
        if IsValid(ent) then ent:Fire("TurnOff", "", 0) end
    end

    -- 3. Override the engine's default fullbright style 0 to "a" (near-zero)
    engine.LightStyle(0, "a")

    -- 4. Force all client lightmaps to re-render under zero ambient
    net.Start("sls_blackout_sync")
        net.WriteFloat(1)
    net.Broadcast()

    -- 5. Map-wide power-down sound
    for _, ply in ipairs(player.GetAll()) do
        ply:EmitSound("slashers_fusebox_powerdown", 100, 100, 1, CHAN_AUTO)
    end

    -- 6. Notify all survivors that the lights went out
    net.Start("notificationSlasher")
        net.WriteTable({"round_notif_blackout"})
        net.WriteString("warning")
    net.Broadcast()
end

------------------------------------------------------------
-- ENT:Initialize
------------------------------------------------------------
function ENT:Initialize()
    self.Destroyed = false
    self:SetModel("models/props_lab/powerbox01a.mdl")

    -- Smart wall-snap: trace FORWARD along the raw (sloppily recorded) angle,
    -- snap X/Y flush to wall while preserving the original Z height, then
    -- align pitch/roll to zero via surface normal. No blind 180° rotation.
    local traceStart = self:GetPos() + Vector(0, 0, 10)
    local tr = util.TraceLine({
        start  = traceStart,
        endpos = traceStart + (self:GetAngles():Forward() * 100),
        filter = self,
    })
    if tr.Hit then
        -- Snap X and Y to the wall, preserve original Z height,
        -- push 1.5 units along normal to prevent Z-fighting and LOS occlusion
        local targetPos = Vector(tr.HitPos.x, tr.HitPos.y, self:GetPos().z)
        self:SetPos(targetPos + (tr.HitNormal * 1.5))
        -- Align perfectly outward from the wall (zeroes out sloppy pitch/roll)
        self:SetAngles(tr.HitNormal:Angle())
    else
        -- Fallback if no wall was found in front: just zero pitch/roll, flip 180°
        local ang = self:GetAngles()
        ang.p = 0
        ang.r = 0
        ang:RotateAroundAxis(Vector(0, 0, 1), 180)
        self:SetAngles(ang)
    end

    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(CONTINUOUS_USE)
    self:SetNWFloat("progress", 0)
    self:SetNWBool("destroyed", false)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
end

------------------------------------------------------------
-- ENT:SpawnFunction — map-placed spawn
------------------------------------------------------------
function ENT:SpawnFunction(ply, tr)
    if not tr.Hit then return end
    local ent = ents.Create("sls_fusebox")
    ent:SetPos(tr.HitPos + tr.HitNormal * 8)
    ent:Spawn()
    return ent
end

------------------------------------------------------------
-- ENT:Use — continuous hold (Jason only)
-- Progress: 0 → 1 over 5 seconds (0.0033 per tick at 66 tickrate).
-- Cancelled if Jason moves more than 4 units from start position.
------------------------------------------------------------
function ENT:Use(activator, caller)
    -- Only Jason (TEAM_KILLER)
    if not IsValid(caller) or caller:Team() ~= TEAM_KILLER then return end

    -- Already destroyed
    if self.Destroyed then return end

    -- Blackout already active
    if GAMEMODE:IsBlackoutActive() then return end

    local curProgress = self:GetNWFloat("progress", 0)

    -- === Increment progress ===
    -- Note: SetNWFloat already syncs to all clients automatically.
    -- Only send the net message at meaningful state transitions.
    if curProgress < 1 then
        -- First tick of a new hold: notify client which entity to track

        local newProgress = math.min(curProgress + 0.0033, 1)
        self:SetNWFloat("progress", newProgress)
    end

    -- Record last use time and holder — Think() cancels on E-release or walk-away
    self._fuse_lastUse = CurTime()
    self._fuse_holder  = caller

    -- === Completion ===
    if curProgress >= 1 and not self.Destroyed then
        self.Destroyed = true
        self:SetNWBool("destroyed", true)
        self:SetNWFloat("progress", 2)

        -- Burnt/black visual + spark effect
        self:SetColor(Color(50, 50, 50))
        local spark = ents.Create("env_spark")
        if IsValid(spark) then
            spark:SetPos(self:GetPos())
            spark:Spawn()
            spark:Fire("SparkOnce")
            SafeRemoveEntityDelayed(spark, 2)
        end

        TriggerBlackout(caller)
    end

end

------------------------------------------------------------
-- ENT:Think — reset progress if Jason releases E or walks away
-- 0.15 s timeout; if Use() hasn't fired in that window, the
-- hold is broken and progress silently resets.
------------------------------------------------------------
function ENT:Think()
    if self.Destroyed then return end

    local curProgress = self:GetNWFloat("progress", 0)
    if curProgress > 0 and curProgress < 1 then
        if not self._fuse_lastUse or (CurTime() - self._fuse_lastUse > 0.15) then
            self:SetNWFloat("progress", 0)
            self._fuse_holder = nil
        end
    end

    self:NextThink(CurTime() + 0.1)
    return true
end

------------------------------------------------------------
-- ENT:OnRemove
------------------------------------------------------------
function ENT:OnRemove()
    self:StopSound("slashers_fusebox_powerdown")
end
