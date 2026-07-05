-- Slashers — Killer Abilities (Server)
-- Dynamic hook manager + all server-side ability implementations.
-- Convars and net strings are declared in sh_abilities.lua.

local GM = GM or GAMEMODE

-----------------------------------------------------------
-- 1. Create convars from sh_abilities.lua registry
-----------------------------------------------------------
if GM.KillerAbilities then
    for charKey, ability in pairs(GM.KillerAbilities) do
        if ability.convars then
            for _, cv in ipairs(ability.convars) do
                CreateConVar(cv.name, cv.default, cv.flags, cv.help)
            end
        end
    end
end

-----------------------------------------------------------
-- 2. Dynamic Hook Manager
-- Hooks are registered on sls_round_PostStart (when the killer's
-- chosen character is known) and removed on sls_round_End.
-----------------------------------------------------------

-- Track which hooks are currently registered for which character.
local registeredHooks = {} -- [charKey] = true

local function RegisterAbilityHooks(charKey)
    if registeredHooks[charKey] then return end
    registeredHooks[charKey] = true

    local ability = GM.KillerAbilities[charKey]
    if not ability then return end

    for _, hookDef in ipairs(ability.hooks) do
        local tag = hookDef.tag
        local funcName = "KA_" .. charKey .. "_" .. hookDef.name
        if not hook.GetTable()[hookDef.name] then return end
        local hookTable = hook.GetTable()[hookDef.name]
        if hookTable and not hookTable[tag] and _G[funcName] then
            hook.Add(hookDef.name, tag, _G[funcName])
        end
    end
end

local function UnregisterAbilityHooks(charKey)
    if not registeredHooks[charKey] then return end
    registeredHooks[charKey] = nil

    local ability = GM.KillerAbilities[charKey]
    if not ability then return end

    for _, hookDef in ipairs(ability.hooks) do
        hook.Remove(hookDef.name, hookDef.tag)
    end
end

-- Called when a round starts and the killer has a ChosenCharacter.
local function ActivateAbilityHooks()
    if not IsValid(GM.ROUND.Killer) then return end
    local charKey = GM.ROUND.Killer.ChosenCharacter
    if not charKey then return end
    RegisterAbilityHooks(charKey)
end

-- Called when the round ends — clean up all active hooks.
local function DeactivateAllAbilityHooks()
    for charKey, _ in pairs(registeredHooks) do
        UnregisterAbilityHooks(charKey)
    end
end

hook.Add("sls_round_PostStart", "sls_ka_ActivateHooks", ActivateAbilityHooks)
hook.Add("sls_round_End",       "sls_ka_DeactivateHooks", DeactivateAllAbilityHooks)

-----------------------------------------------------------
-- 3. Override GM.MAP.Killer:UseAbility
-- This replaces the empty stub in mapsloader.lua.
-- It routes to the centralized ability system.
-----------------------------------------------------------
function GM.MAP.Killer:UseAbility(ply)
    local charKey = ply and ply.ChosenCharacter
    if not charKey then return end
    local ability = GM.KillerAbilities[charKey]
    if ability and ability.UseAbility then
        ability.UseAbility(ply, self)
    end
end

-----------------------------------------------------------
-- 4. GHOSTFACE ABILITY — See doors being used
-- Hook: PlayerUse
-- Net:  sls_kability_AddDoor
-----------------------------------------------------------

function KA_ghostface_PlayerUse(ply, ent)
    if not GM.ROUND.Active or not IsValid(GM.ROUND.Killer) then return end
    if ply:Team() ~= TEAM_SURVIVORS then return end
    if ply.ClassID == CLASS_SURV_SHY then return end
    if not table.HasValue(GM.CONFIG["killerhelp_door_entities"], ent:GetClass()) then return end

    -- Per-survivor, per-entity cooldown
    ply.kh_use = ply.kh_use or {}
    local lastUse = ply.kh_use[ent:EntIndex()] or 0
    if CurTime() <= lastUse then return end
    ply.kh_use[ent:EntIndex()] = CurTime() + GetConVar("slashers_ghostface_door_duration"):GetFloat()

    local doorPos = ent:GetPos()
    local radius = GetConVar("slashers_ghostface_door_radius"):GetInt()

    -- Optional radius check: only show if killer is nearby
    if radius ~= 0 then
        local nearby = ents.FindInSphere(doorPos, radius)
        if not table.HasValue(nearby, GM.ROUND.Killer) then return end
    end

    local endTime = CurTime() + GetConVar("slashers_ghostface_door_duration"):GetFloat()
    net.Start("sls_kability_AddDoor")
        net.WriteVector(doorPos)
        net.WriteInt(endTime, 16)
    net.Send(GM.ROUND.Killer)
end

-----------------------------------------------------------
-- 5. JASON ABILITY — Track footsteps
-- Hook: PlayerFootstep
-- Net:  sls_kability_AddStep
-----------------------------------------------------------

function KA_jason_PlayerFootstep(ply, pos, foot, sound, volume, filter)
    -- Suppress footstep sound for invisible (alpha-0) players
    if ply:GetColor().a == 0 then return true end
    if not GM.ROUND.Active or not IsValid(GM.ROUND.Killer) then return end
    if ply:Team() ~= TEAM_SURVIVORS then return end
    if ply.ClassID == CLASS_SURV_SHY then return end

    net.Start("sls_kability_AddStep")
        net.WriteEntity(ply)
        net.WriteVector(pos)
        net.WriteAngle(ply:GetAimVector():Angle())
        net.WriteInt(CurTime() + GetConVar("slashers_jason_step_duration"):GetFloat(), 16)
    net.Send(GM.ROUND.Killer)
end

-- Separate hook entry to suppress footstep sounds for alpha-0 players
function KA_jason_CDisableFootsteps(ply, pos, foot, sound, volume, filter)
	if ply:GetColor().a == 0 then
		return true
	end
end

------------------------------------------------------------
-- JASON ABILITY — Power Cut / Fuse Box
-- Hook: sls_round_PostStart, sls_round_End
-- Spawns one fusebox at a random GM.MAP.Goal.Fusebox location.
------------------------------------------------------------

function KA_jason_PostStart()
    -- Reset blackout state at round start
    GAMEMODE:ResetBlackout()

    if not GM.MAP.Fusebox or #GM.MAP.Fusebox == 0 then return end

    local entry = GM.MAP.Fusebox[math.random(#GM.MAP.Fusebox)]
    local fusebox = ents.Create("sls_fusebox")
    if not IsValid(fusebox) then return end

    fusebox:SetPos(entry.pos)
    fusebox:SetAngles(entry.ang)
    fusebox:Spawn()

    -- Keep a reference on the round object so it can be cleaned up
    GM.ROUND._fusebox = fusebox
end

function KA_jason_End()
    -- Clean up the fusebox if it still exists
    if IsValid(GM.ROUND._fusebox) then
        GM.ROUND._fusebox:Remove()
        GM.ROUND._fusebox = nil
    end
end

-----------------------------------------------------------
-- 6. MYERS ABILITY — Wallhack one victim
-- Hook: Think, PostPlayerDeath, sls_round_PostStart, sls_round_End
-- Net:  sls_kability_Wallhack, sls_kability_update_myersability
-----------------------------------------------------------

-- Module-level state (persists across hook calls)
local VictimMyers       = nil
local Timer1            = 0
local lastRequestMyers  = 0
local myersAbilityActivated = false

local function findVictim()
    for _, v in ipairs(GM.ROUND:GetSurvivorsAlive()) do
        if v.ClassID ~= CLASS_SURV_SHY then
            return v
        end
    end
end

function KA_myers_UseAbility(ply, selfRef)
    if not GM.ROUND.Active or not IsValid(GM.ROUND.Killer) then return end
    if myersAbilityActivated then return end
    if CurTime() - lastRequestMyers < GetConVar("slashers_myers_wallhack_cooldown"):GetFloat() then
        net.Start("notificationSlasher")
            net.WriteTable({"killerhelp_cant_use_ability"})
            net.WriteString("cross")
        net.Send(ply)
        return
    end

    myersAbilityActivated = true
    net.Start("sls_kability_update_myersability")
        net.WriteInt(1, 2)
    net.Send(ply)

    timer.Simple(GetConVar("slashers_myers_wallhack_duration"):GetFloat(), function()
        if not GM.ROUND.Active then return end
        myersAbilityActivated = false
        lastRequestMyers = CurTime()
        net.Start("sls_kability_update_myersability")
            net.WriteInt(0, 2)
        net.Send(GM.ROUND.Killer)
    end)
end

function KA_myers_Think()
    local curtime = CurTime()
    if not GM.ROUND.Active or not IsValid(GM.ROUND.Killer) then
        myersAbilityActivated = false
        return
    end

    -- Send victim position every 0.5s
    if Timer1 < curtime and IsValid(VictimMyers) and VictimMyers.ClassID ~= CLASS_SURV_SHY then
        net.Start("sls_kability_Wallhack")
            if myersAbilityActivated then
                net.WriteVector(VictimMyers:GetPos() + Vector(0, 0, 50))
            else
                net.WriteVector(Vector(42, 42, 42))
            end
        net.Send(GM.ROUND.Killer)
        Timer1 = curtime + 0.5
    end

    -- Notify when ability becomes available again
    local cooldown = GM.CONFIG["myers_cooldown"] or 10
    if math.abs(CurTime() - lastRequestMyers - cooldown) < 0.05 then
        net.Start("sls_kability_update_myersability")
            net.WriteInt(2, 2)
        net.Send(GM.ROUND.Killer)
    end
end

function KA_myers_PostPlayerDeath(ply)
    if GM.ROUND.Active and IsValid(GM.ROUND.Killer) and GM.ROUND.Killer:Team() == TEAM_KILLER and ply == VictimMyers then
        VictimMyers = findVictim()
        if not IsValid(VictimMyers) then
            net.Start("sls_kability_Wallhack")
                net.WriteVector(Vector(42, 42, 42))
            net.Send(GM.ROUND.Killer)
        end
    end
end

function KA_myers_PostStart()
    if not IsValid(GM.ROUND.Killer) then return end
    VictimMyers = findVictim()
end

function KA_myers_End()
    myersAbilityActivated = false
    lastRequestMyers = 0
    if IsValid(GM.ROUND.Killer) then
        net.Start("sls_kability_update_myersability")
            net.WriteInt(0, 2)
        net.Send(GM.ROUND.Killer)
    end
end

-- Register UseAbility for Myers in the registry
if GM.KillerAbilities["myers"] then
    GM.KillerAbilities["myers"].UseAbility = KA_myers_UseAbility
end

-- Hook Myers ability logic
hook.Add("Think",                  "sls_ka_myers_Think",           KA_myers_Think)
hook.Add("PostPlayerDeath",        "sls_ka_myers_PostPlayerDeath", KA_myers_PostPlayerDeath)
hook.Add("sls_round_PostStart",    "sls_ka_myers_PostStart",       KA_myers_PostStart)
hook.Add("sls_round_End",          "sls_ka_myers_End",             KA_myers_End)

-----------------------------------------------------------
-- 7. PROXY ABILITY — Invisibility toggle
-- Hook: Think (×2), PostPlayerDeath, sls_round_PostStart (×2), sls_round_End, InitPostEntity, ShouldCollide
-- Net:  sls_kability_Invisible, sls_kability_InvisibleIndic, sls_kability_survivorseekiller, sls_proxy_sendpos
-----------------------------------------------------------

local KInvisible = Color(255, 255, 255, 0)
local KNormal    = Color(255, 255, 255, 255)
local KillerInView      = false
local LastKillerInView  = 0
local timerSendProxy    = 0

-- Track survivors who are looking at the killer
local function ResponsePlayerSeeKiller()
    LastKillerInView = net.ReadFloat()
end
net.Receive("sls_kability_survivorseekiller", ResponsePlayerSeeKiller)

local function KA_proxy_UpdateKillerInView()
    local curtime = CurTime()
    if LastKillerInView > curtime - 0.5 then
        KillerInView = true
    else
        KillerInView = false
    end

    -- Fallback: check if any bot survivor is looking directly at the killer.
    -- Bots don't send the sls_kability_survivorseekiller net message, so we
    -- must perform a server-side FOV + LoS check to ensure they interrupt the
    -- Proxy's invisibility just like human players do.
    if not KillerInView and GM.ROUND.Active and IsValid(GM.ROUND.Killer) then
        for _, v in ipairs(GM.ROUND:GetSurvivorsAlive()) do
            if not v:IsBot() then continue end

            local toKiller = (GM.ROUND.Killer:GetPos() - v:GetPos()):GetNormalized()
            local aimVec   = v:GetAimVector()
            if toKiller:Dot(aimVec) > 0.5 and v:IsLineOfSightClear(GM.ROUND.Killer) then
                KillerInView = true
                break
            end
        end
    end
end

--[[
    KA_proxy_DeactivateAbility
    Shared deactivation logic for the Proxy's invisibility.
    Called when the Proxy manually toggles off, or when a survivor's
    gaze forces the ability to break while he is invisible.
]]
local function KA_proxy_DeactivateAbility(ply)
    ply:EmitSound("slashers/effects/proxy_power_off.wav")

    timer.Simple(1, function()
        if not IsValid(ply) then return end
        if ply.InitialWeapon and ply.InitialWeapon ~= "" then
            ply:Give(ply.InitialWeapon)
        end
        ply:SetColor(KNormal)
        local charKey  = ply.ChosenCharacter
        local charData = charKey and GAMEMODE.KillerCharacters and GAMEMODE.KillerCharacters[charKey]
        local baseWalk = charData and charData.walk or 200
        local baseRun  = charData and charData.run  or 200
        ply:SetWalkSpeed(baseWalk)
        ply:SetRunSpeed(baseRun)
        ply:DrawShadow(true)
        ply:SetRenderMode(RENDERMODE_TRANSALPHA)
        ply.InvisibleActive = false

        net.Start("sls_kability_Invisible")
            net.WriteBool(false)
        net.Send(ply)
    end)
end

function KA_proxy_UseAbility(ply)
    if not GM.ROUND.Active or not IsValid(ply) then return end

    local PlayerWeapon = ply:GetActiveWeapon()

    if KillerInView then
        net.Start("notificationSlasher")
            net.WriteTable({"killerhelp_cant_use_ability"})
            net.WriteString("cross")
        net.Send(ply)
        return
    end

    if not ply.InvisibleActive and not KillerInView then
        ply:EmitSound("slashers/effects/proxy_power_on.wav")

        timer.Simple(0.6, function()
            if not IsValid(ply) then return end
            ply:SetColor(KInvisible)
            ply:SetWalkSpeed(400)
            ply:SetRunSpeed(400)
            if IsValid(PlayerWeapon) then
                ply:StripWeapon(PlayerWeapon:GetClass())
            end
            ply:SetRenderMode(RENDERMODE_NONE)
            ply:DrawShadow(false)
            ply:AddEffects(EF_NOSHADOW)
            ply.InvisibleActive = true
            ply:CrosshairDisable()

            net.Start("sls_kability_Invisible")
                net.WriteBool(true)
            net.Send(ply)
        end)

    elseif ply.InvisibleActive and not KillerInView then
        KA_proxy_DeactivateAbility(ply)
    end
end

--[[
    KA_proxy_Think
    Runs every server tick for the Proxy. Handles:
      1. Updating KillerInView from client gaze reports.
      2. Forced ability interruption when a survivor looks at the invisible Proxy.
      3. Broadcasting the Proxy's position to the shy girl while he is invisible.
]]
function KA_proxy_Think()
    -- Part 1: Update gaze state
    KA_proxy_UpdateKillerInView()

    -- Part 2: Force-interrupt invisibility if a survivor is looking at the invisible Proxy
    if KillerInView and GM.ROUND.Active and IsValid(GM.ROUND.Killer) then
        local killer = GM.ROUND.Killer
        if killer.InvisibleActive then
            KA_proxy_DeactivateAbility(killer)
        end
    end

    -- Part 3: Send killer position to the shy girl while invisible (was KA_proxy_sendPosWhenInvisible)
    if not IsValid(GM.ROUND.Killer) or not GM.ROUND.Active then
        if timerSendProxy < CurTime() then
            timerSendProxy = CurTime() + 1
            net.Start("sls_proxy_sendpos")
                net.WriteVector(Vector(0, 0, 0))
                net.WriteBool(false)
            net.Broadcast()
        end
        return
    end

    if timerSendProxy >= CurTime() then return end
    timerSendProxy = CurTime() + 0.5

    local shygirl = getSurvivorByClass(CLASS_SURV_SHY)
    if not IsValid(shygirl) then return end

    local killer = GM.ROUND.Killer
    if not killer.InvisibleActive or not shygirl:IsLineOfSightClear(killer) then
        net.Start("sls_proxy_sendpos")
            net.WriteVector(Vector(0, 0, 0))
            net.WriteBool(false)
        net.Send(shygirl)
        return
    end

    net.Start("sls_proxy_sendpos")
        net.WriteVector(killer:GetPos())
        net.WriteBool(true)
    net.Send(shygirl)
end

local function ResetProxyVisibility()
    for _, v in ipairs(player.GetAll()) do
        v:DrawShadow(true)
        v:SetRenderMode(RENDERMODE_TRANSALPHA)
        v:SetColor(Color(255, 255, 255))
    end
    if not IsValid(GM.ROUND.Killer) then return end
    GM.ROUND.Killer.InvisibleActive = false
    net.Start("sls_kability_Invisible")
        net.WriteBool(false)
    net.Send(GM.ROUND.Killer)
end

function KA_proxy_ResetViewKiller(ply)
    ResetProxyVisibility()
end

function KA_proxy_ResetViewKillerAfterEnd()
    ResetProxyVisibility()
end


-- Register UseAbility for Proxy
if GM.KillerAbilities["proxy"] then
    GM.KillerAbilities["proxy"].UseAbility = KA_proxy_UseAbility
end

-----------------------------------------------------------
-- 8. BATES ABILITY — Mother radar (proximity audio)
-- Net: sls_motherradar  (sent by the batesmum entity, not here)
-- No server-side hooks needed; ability is entity-driven.
-----------------------------------------------------------

-----------------------------------------------------------
-- 9. INTRUDER ABILITY — Trap proximity for shy girl
-- Hook: Think
-- Net:  sls_trapspos
-----------------------------------------------------------

local timerTrap = 0

function KA_intruder_detectProximityTraps()
    if not IsValid(GM.ROUND.Killer) or not GM.ROUND.Active then return end
    if timerTrap >= CurTime() then return end
    timerTrap = CurTime() + 1

    local shygirl = getSurvivorByClass(CLASS_SURV_SHY)
    if not IsValid(shygirl) then return end

    local entsAround = ents.FindInSphere(shygirl:GetPos(), 700)
    local trapsAround = {}
    for _, v in ipairs(entsAround) do
        local cls = v:GetClass()
        if cls == "beartrap" or cls == "alertropes" or v.trapeddoor == 1 then
            table.insert(trapsAround, v)
        end
    end

    net.Start("sls_trapspos")
        net.WriteTable(trapsAround)
    net.Send(shygirl)
end
