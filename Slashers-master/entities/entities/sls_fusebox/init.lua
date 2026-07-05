-- Slashers — Jason Fuse Box Entity (Server)
-- @Author: Claude (Execution Agent)
-- @Date:   2026-07-05
-- @Last Modified by:   Claude
-- @Last Modified time: 2026-07-05

local GM = GAMEMODE

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

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

    -- 4. Map-wide power-down sound
    for _, ply in ipairs(player.GetAll()) do
        ply:EmitSound("slashers_fusebox_powerdown", 100, 100, 1, CHAN_AUTO)
    end

    -- 5. Notify all survivors that the lights went out
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
    self:SetModel("models/props_c17/substation_stripebox01a.mdl")
    self:PhysicsInit(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
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

    -- === START of hold: capture initial position ===
    if curProgress == 0 then
        self._fuse_startPos = caller:GetPos()
        self._fuse_holder   = caller
    end

    -- Safety: if someone else started it, ignore
    if self._fuse_holder ~= caller then return end

    -- === Cancellation: Jason moved away ===
    if self._fuse_startPos and caller:GetPos():DistToSqr(self._fuse_startPos) > 16 then
        self:SetNWFloat("progress", 0)
        self._fuse_startPos = nil
        self._fuse_holder   = nil
        net.Start("sls_kability_fusebox_progress")
            net.WriteFloat(0)
            net.WriteEntity(self)
        net.Send(caller)
        return
    end

    -- === Increment progress ===
    if curProgress < 1 then
        local newProgress = math.min(curProgress + 0.0033, 1)
        self:SetNWFloat("progress", newProgress)

        net.Start("sls_kability_fusebox_progress")
            net.WriteFloat(newProgress)
            net.WriteEntity(self)
        net.Send(caller)
    end

    -- === Completion ===
    if curProgress >= 1 and not self.Destroyed then
        self.Destroyed = true
        self:SetNWBool("destroyed", true)
        self:SetNWFloat("progress", 2)

        -- Change model to indicate destruction
        self:SetModel("models/props_c17/substation_stripebox01b.mdl")

        TriggerBlackout(caller)

        net.Start("sls_kability_fusebox_progress")
            net.WriteFloat(2)
            net.WriteEntity(self)
        net.Send(caller)
    end
end

------------------------------------------------------------
-- ENT:OnRemove
------------------------------------------------------------
function ENT:OnRemove()
    self:StopSound("slashers_fusebox_powerdown")
end
