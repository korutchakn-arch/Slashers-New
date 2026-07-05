-- Slashers - TFA Customization Blocker
-- Blocks the TFA weapon inspection/customization menu (C key / +menu_context)
-- for players holding TFA melee weapons on the Killer team.
--
-- TFA Base intercepts +menu_context to open its customization UI, which
-- requires animation tables (kvt) that simple bash/melee weapons don't have.
-- This causes nil-index errors in BuildAnimActivities and ViewModelDrawnPostFinal.
--
-- Fix: intercept the bind at PlayerBindPress and consume it silently so TFA
-- never sees it. The killer's weapon functions normally in every other respect.

-- ─────────────────────────────────────────────
-- Helper: is the local player on the killer team?
-- ─────────────────────────────────────────────
local function IsKiller(ply)
    if not IsValid(ply) then return false end
    return ply:Team() == TEAM_KILLER
end

-- ─────────────────────────────────────────────
-- Block +menu_context when the player is on TEAM_KILLER.
-- Returning true suppresses the bind from being processed further.
-- ─────────────────────────────────────────────
hook.Add("PlayerBindPress", "sls_TFA_BlockCustomization", function(ply, bind, pressed)
    -- Only act on press (not release), and only on the killer team
    if not pressed then return end
    if not IsKiller(ply) then return end

    -- +menu_context is the C-key bind that TFA Base hooks for weapon inspection
    if string.find(bind, "menu_context") then
        return true  -- suppress — TFA never sees it, no nil errors
    end
end)

-- ─────────────────────────────────────────────
-- Defence-in-depth: if a TFA weapon somehow still gets +menu_context
-- (e.g. another addon re-injects it), set DisableCustomize on equip so
-- TFA's internal guards fire first and prevent the animation crash.
-- ─────────────────────────────────────────────
hook.Add("WeaponEquip", "sls_TFA_BlockCustomization_WeaponEquip", function(wep, ply)
    if not IsKiller(ply) then return end
    if not IsValid(wep) then return end

    -- Only touch TFA weapons (anything that inherits TFA bases)
    if not wep.IsTFAWeapon then return end

    -- TFA's own guard: when this is true TFA skips the customization flow
    wep.DisableCustomize = true
end)
