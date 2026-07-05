-- Slashers — Killer Abilities Registry (Shared)
-- Defines per-character ability metadata, hooks, and net message declarations.
-- All ability implementations live in sv_abilities.lua (server) and cl_abilities.lua (client).

local GM = GM or GAMEMODE

GM.KillerAbilities = {}

-----------------------------------------------------------
-- Helper: declare all ability network strings once (shared)
-----------------------------------------------------------
if SERVER then
    -- Ghostface
    util.AddNetworkString("sls_kability_AddDoor")
    util.AddNetworkString("sls_ghostface_phone_reveal") -- Phone SWEP: broadcast furthest-survivor position to Ghostface
    -- Jason
    util.AddNetworkString("sls_kability_AddStep")
    util.AddNetworkString("sls_kability_fusebox_progress")
    -- Myers
    util.AddNetworkString("sls_kability_update_myersability")
    util.AddNetworkString("sls_kability_Wallhack")
    -- Proxy
    util.AddNetworkString("sls_kability_Invisible")
    util.AddNetworkString("sls_kability_InvisibleIndic")
    util.AddNetworkString("sls_kability_survivorseekiller")
    util.AddNetworkString("sls_proxy_sendpos")
    -- Bates
    util.AddNetworkString("sls_motherradar")
    -- Intruder
    util.AddNetworkString("sls_trapspos")
end

-----------------------------------------------------------
-- GHOSTFACE
-- Active: PlayerUse hook (server)
-- Passive: HUD icon overlay (client)
-----------------------------------------------------------
GM.KillerAbilities["ghostface"] = {
    name = "Ghostface",
    desc = "See doors being opened near survivors.",
    hooks = {
        -- Server
        {name = "PlayerUse",          tag = "sls_ka_ghostface_PlayerUse"},
        -- Client
        {name = "HUDPaintBackground", tag = "sls_ka_ghostface_HUDPaintBackground"},
        {name = "sls_round_PreStart", tag = "sls_ka_ghostface_PreStart"},
        {name = "sls_round_End",     tag = "sls_ka_ghostface_End"},
    },
    convars = {
        {name = "slashers_ghostface_door_duration", default = "3",  flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Duration (seconds) a door icon stays visible for Ghostface."},
        {name = "slashers_ghostface_door_radius",   default = "1400", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Ghostface ability radius. 0 = no radius check."},
    },
}

-----------------------------------------------------------
-- JASON
-- Active: PlayerFootstep hook (server)
-- Passive: 3D footprint rendering (client)
-----------------------------------------------------------
GM.KillerAbilities["jason"] = {
    name = "Jason",
    desc = "See survivor footsteps on the ground.",
    hooks = {
        -- Server
        {name = "PlayerFootstep",      tag = "sls_ka_jason_PlayerFootstep"},
        {name = "PlayerFootstep",      tag = "sls_ka_jason_CDisableFootsteps"}, -- suppress sound for invisible players
        {name = "sls_round_PostStart", tag = "sls_ka_jason_PostStart"},         -- spawn fusebox
        -- Client
        {name = "PostDrawTranslucentRenderables", tag = "sls_ka_jason_PostDrawTranslucentRenderables"},
        {name = "sls_round_PreStart", tag = "sls_ka_jason_PreStart"},
        {name = "sls_round_End",     tag = "sls_ka_jason_End"},
    },
    convars = {
        {name = "slashers_jason_step_duration", default = "30", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Duration (seconds) a footprint stays visible for Jason."},
    },
}

-----------------------------------------------------------
-- MYERS
-- Active: UseAbility() toggle (server) + Think + PostPlayerDeath
-- Passive: Target icon on HUD + status sounds (client)
-----------------------------------------------------------
GM.KillerAbilities["myers"] = {
    name = "Michael Myers",
    desc = "Stalk one survivor to reveal their position through walls.",
    hooks = {
        -- Server
        {name = "Think",              tag = "sls_ka_myers_Think"},
        {name = "PostPlayerDeath",    tag = "sls_ka_myers_PostPlayerDeath"},
        {name = "sls_round_PostStart", tag = "sls_ka_myers_PostStart"},
        {name = "sls_round_End",      tag = "sls_ka_myers_End"},
        -- Client
        {name = "HUDPaintBackground", tag = "sls_ka_myers_HUDPaintBackground"},
        {name = "sls_round_PreStart", tag = "sls_ka_myers_PreStart"},
        {name = "sls_round_End",      tag = "sls_ka_myers_End"},
    },
    convars = {
        {name = "slashers_myers_wallhack_cooldown", default = "10", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Myers wallhack cooldown in seconds."},
        {name = "slashers_myers_wallhack_duration", default = "10", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Myers wallhack active duration in seconds."},
    },
}

-----------------------------------------------------------
-- PROXY
-- Active: UseAbility() toggle (server) + Think
-- Passive: Invisibility post-process + killer icon for shy girl (client)
-----------------------------------------------------------
GM.KillerAbilities["proxy"] = {
    name = "The Proxy",
    desc = "Vanish from sight — reappear to strike.",
    hooks = {
        -- Server
        {name = "Think",              tag = "sls_ka_proxy_Think"},
        {name = "PostPlayerDeath",    tag = "sls_ka_proxy_ResetViewKiller"},
        {name = "sls_round_PostStart", tag = "sls_ka_proxy_ResetViewKillerAfterEnd"},
        {name = "sls_round_End",      tag = "sls_ka_proxy_ResetViewKillerAfterEnd"},

        -- Client
        {name = "RenderScreenspaceEffects", tag = "sls_ka_proxy_InvisibleVision"},
        {name = "Think",              tag = "sls_ka_proxy_CheckKillerInSight"},
        {name = "HUDPaintBackground", tag = "sls_ka_proxy_drawIconOnProxy"},
    },
    convars = {}, -- no dedicated convars for Proxy ability
}

-----------------------------------------------------------
-- BATES
-- Active: Sound loop tied to mother radar (server sends level)
-- Passive: Whisper audio at 3 volume levels (client)
-----------------------------------------------------------
GM.KillerAbilities["bates"] = {
    name = "Norman Bates",
    desc = "Your mother's corpse guides you to nearby survivors.",
    hooks = {
        -- Client
        {name = "sls_round_End", tag = "sls_ka_bates_autoEnd"},
    },
    convars = {
        {name = "slashers_bates_far_radius",    default = "400", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Bates mother radar far distance."},
        {name = "slashers_bates_medium_radius",  default = "200", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Bates mother radar medium distance."},
        {name = "slashers_bates_close_radius",   default = "100", flags = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, help = "Bates mother radar close distance."},
    },
}

-----------------------------------------------------------
-- INTRUDER
-- Active: Trap proximity Think hook (server)
-- Passive: Red halo around nearby traps for shy girl (client)
-----------------------------------------------------------
GM.KillerAbilities["intruder"] = {
    name = "The Intruder",
    desc = "Place traps and reveal them to the shy girl.",
    hooks = {
        -- Server
        {name = "Think",              tag = "sls_ka_intruder_detectProximityTraps"},
        -- Client
        {name = "PreDrawHalos",       tag = "sls_ka_intruder_AddHalos"},
    },
    convars = {}, -- no dedicated convars for Intruder ability
}
