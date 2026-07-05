# Migration Guide: Killer Abilities Module

**For map authors adding new maps or customising existing ones.**

---

## Architecture Overview

Ability logic has been centralised into `gamemode/modules/killer_abilities/`:

| File | Purpose |
|------|---------|
| `sh_abilities.lua` | Shared `GM.KillerAbilities` registry (hook metadata, net string declarations) |
| `sv_abilities.lua` | Server-side ability functions + engine hook registrations at module load + per-round custom hook activation |
| `cl_abilities.lua` | Client-side HUD overlays, 3D render effects, and net handlers |

**Map files no longer contain killer ability logic.** They only hold map-specific metadata (name, goals, killer properties, convars).

### How Routing Works

1. Killer presses menu key → `sls_mapsloader_UseAbility` net message fires
2. `mapsloader.lua` server handler calls `GM.MAP.Killer:UseAbility(ply)` (empty stub, intentionally left in place)
3. `sv_abilities.lua` `sls_mapsloader_UseAbility` receiver reads `ply.ChosenCharacter` and routes to `GM.KillerAbilities[charKey].UseAbility(ply)`
4. Engine hooks (`PlayerUse`, `Think`, `PlayerFootstep`, etc.) are registered **once at module load time** — all functions guard themselves with `ChosenCharacter` checks and are safe no-ops for other killers
5. Custom round hooks (`sls_round_PostStart`, `sls_round_End`) are activated/deactivated per round via `ActivateHooksOnRoundStart` / `DeactivateAllCustomHooks`

---

## Hook Registration Model

### Engine Hooks (registered once at module load)

These are registered in `sv_abilities.lua` at the end of the file (after all `local function` definitions) so Lua resolves the references correctly:

```lua
-- All these functions guard themselves with ChosenCharacter checks
hook.Add("PlayerUse",        "sls_ka_ghostface_PlayerUse",        KA_ghostface_PlayerUse)
hook.Add("PlayerFootstep",   "sls_ka_jason_PlayerFootstep",        KA_jason_PlayerFootstep)
hook.Add("PlayerFootstep",   "sls_ka_jason_CDisableFootsteps",     KA_jason_CDisableFootsteps)
hook.Add("Think",            "sls_ka_myers_Think",                KA_myers_Think)
hook.Add("PostPlayerDeath",  "sls_ka_myers_PostPlayerDeath",      KA_myers_PostPlayerDeath)
hook.Add("Think",            "sls_ka_proxy_UpdateKillerInView",  KA_proxy_UpdateKillerInView)
hook.Add("PostPlayerDeath",  "sls_ka_proxy_ResetViewKiller",      KA_proxy_ResetViewKiller)
hook.Add("Think",            "sls_ka_proxy_sendPosWhenInvisible",KA_proxy_sendPosWhenInvisible)
hook.Add("InitPostEntity",   "sls_ka_proxy_initCol",              KA_proxy_initCol)
hook.Add("ShouldCollide",    "sls_ka_proxy_ShouldCollide",        KA_proxy_ShouldCollide)
hook.Add("Think",            "sls_ka_intruder_detectProximityTraps", KA_intruder_detectProximityTraps)
```

Each function starts with:
```lua
local function KA_ghostface_PlayerUse(ply, ent)
    if not IsValid(GM.ROUND.Killer) or not GM.ROUND.Active then return end
    if GM.ROUND.Killer.ChosenCharacter ~= "ghostface" then return end
    -- ability logic...
end
```

### Custom Round Hooks (registered per round)

These use a registration table in `sv_abilities.lua` and are activated/deactivated by `ActivateHooksOnRoundStart` / `DeactivateAllCustomHooks`:

```lua
local registeredCustomHooks = {
    ghostface = {"sls_round_PreStart", "sls_round_End"},
    jason     = {"sls_round_PreStart", "sls_round_End"},
    myers     = {"sls_round_PostStart", "sls_round_End"},
    proxy     = {"sls_round_PostStart", "sls_round_End"},
    bates     = {"sls_round_End"},
    intruder  = {},
}
```

---

## What Map Files Must Still Provide

### Map Metadata (unchanged)

```lua
GM.MAP.Name = "My Map"
GM.MAP.EscapeDuration = 60
GM.MAP.StartMusic = "slashers_start_game.wav"
GM.MAP.ChaseMusic = "slashers/chase.wav"
GM.MAP.Goal = { Jerrican = {...}, Generator = {...}, Radio = {...} }
```

### Killer Properties (unchanged)

```lua
GM.MAP.Killer.Name = "Ghostface"
GM.MAP.Killer.Model = "models/player/ghostface.mdl"
GM.MAP.Killer.WalkSpeed = 200
GM.MAP.Killer.RunSpeed = 280
GM.MAP.Killer.ExtraWeapons = {}
```

### Character-Specific Descriptions (client block, unchanged pattern)

```lua
if CLIENT then
    GM.MAP.Killer.Desc = GM.LANG:GetString("class_desc_ghostface")
    GM.MAP.Killer.Icon = Material("icons/icon_ghostface.png")
end
```

### Map-Scoped Convars (unchanged)

Ability-specific convars belong in the map file, not the ability module:

```lua
CreateConVar("slashers_ghostface_door_range", 200, {...}, "Ghostface door tracking range.")
```

---

## How to Add a New Map

Create `gamemode/maps/slash_mymap.lua` with only:

1. Map metadata (`GM.MAP.Name`, `GM.MAP.EscapeDuration`, etc.)
2. Map goals (`GM.MAP.Goal`)
3. Killer properties (`GM.MAP.Killer.*`)
4. Optional: map-scoped convars

**Do not add `if CLIENT`/`else` blocks for killer abilities.** The `killer_abilities` module handles all ability logic automatically based on `ply.ChosenCharacter`.

---

## How to Add a New Killer Character

### 1. `sh_abilities.lua` — shared definition

Add the entry to `GM.KillerAbilities`:

```lua
GM.KillerAbilities["mychar"] = {
    hooks = {"Think", "PlayerUse"},   -- used only for reference docs
    UseAbility = function(ply) ... end,
}
```

Also add net strings in the `if SERVER then` block if the new killer needs custom net messages.

### 2. `sv_abilities.lua` — server logic

- Add the ability function with `ChosenCharacter` guard at the bottom of the file
- Add engine hook `hook.Add()` call for it (if applicable)
- Add entry to `registeredCustomHooks[charKey]` table for round-based hooks
- Implement `sls_round_*` handler functions as needed

### 3. `cl_abilities.lua` — HUD/visuals

Add client-side hooks with unique namespacing (`sls_ka_cl_mychar_*`).

### 4. `sh_characters.lua` — character registry

Add the entry to `GM.KillerCharacters["mychar"]` with an `icon` field.

---

## Convar Handling

Convars stay in map files because:
- `CreateConVar` must be called when the map file is included
- Each map may have different values (different maps = different convar defaults)
- The ability module reads convars via `GetConVar()` at runtime — no changes needed in map files for existing convars

---

## Round Lifecycle (automatic)

The `sv_abilities.lua` module hooks into these events:

| Hook | Action |
|------|--------|
| `sls_round_PostStart` | Calls `ActivateHooksOnRoundStart()` — activates custom round hooks for the current killer's `ChosenCharacter` |
| `sls_round_End` | Calls `DeactivateAllCustomHooks()` — removes all custom round hooks |
| `PostPlayerDeath` | Calls `GM.KillerAbilities[charKey].OnCleanUp(ply)` via `sv_abilities.lua` handler |
| `PlayerDisconnected` | Same as `PostPlayerDeath` |

No map files need to register these hooks themselves.

---

## Common Bugs Fixed

### `return` instead of `continue` in hook registration loop

In `sv_abilities.lua`, the `RegisterCustomHooks` loop must use `continue` to skip entries without GMod hook tables, not `return` (which would exit the entire function early):

```lua
-- WRONG: exits the function entirely, skipping remaining characters
for charKey, hooks in pairs(customHooks) do
    if not hooks then return end  -- ← breaks out of RegisterCustomHooks!
    ...
end

-- CORRECT: skips this iteration, continues with next character
for charKey, hooks in pairs(customHooks) do
    if not hooks then continue end  -- ← skips to next charKey
    ...
end
```

### `_G[funcName]` lookup for local functions

Never use `_G[funcName]` to look up functions defined as `local function`. Always use the direct function reference. The module registers hooks at the **end of the file** (after all `local function` definitions) so Lua resolves them correctly.

---

## File Deltas Summary

| File | Change |
|------|--------|
| `modules/killer_abilities/sh_abilities.lua` | **Created** — shared registry |
| `modules/killer_abilities/sv_abilities.lua` | **Created** — ability logic + hook registrations |
| `modules/killer_abilities/cl_abilities.lua` | **Created** — HUD/overlays |
| `core/mapsloader.lua` | **Modified** — stub comment updated, empty `UseAbility` stub kept |
| `maps/slash_highschool.lua` | **Modified** — ability block removed |
| `maps/slash_summercamp.lua` | **Modified** — ability block removed |
| `maps/slash_selvage.lua` | **Modified** — ability block removed |
| `maps/slash_subway.lua` | **Modified** — ability block removed |
| `maps/slash_motel.lua` | **Modified** — ability block removed |
| `maps/slash_lodge.lua` | **Modified** — ability block removed |
| `modules/killer_setup/sh_characters.lua` | **Modified** — `icon` field added per character |
