# SLASHERS — Claude 4.6 Sonnet Context Manifest

This document is the **primary context file** for working with the **Slashers** Garry's Mod gamemode. Read it before writing any code. Keep it accurate as the codebase evolves.

---

## 1. Project Overview

- **Name:** Slashers
- **Version:** 1.1.0 (from [`gamemode/shared.lua`](Slashers-master/gamemode/shared.lua))
- **Authors:** Garrus2142, Daryl_Winters, Guilhem PECH
- **Workshop:** http://steamcommunity.com/sharedfiles/filedetails/?id=1092007703
- **GitHub:** https://github.com/Garrus2142/Slashers/
- **Gamemode slug:** `Slashers-master` (folder name on disk)
- **Addon name for GMod:** `slashers` (used in `garrysmod/addons/`)

### Teams and Classes (from [`shared.lua`](Slashers-master/gamemode/shared.lua))

| Constant | Value | Team |
|---|---|---|
| `TEAM_KILLER` | `1` | Murderer (red) |
| `TEAM_SURVIVORS` | `2` | Survivors (blue) |

**Survivor Classes:**

| Constant | Class Name | Character Name |
|---|---|---|
| `CLASS_SURV_SPORTS` | Sports | Trent |
| `CLASS_SURV_POPULAR` | Popular girl | Lynda |
| `CLASS_SURV_NERD` | Nerd | Noah |
| `CLASS_SURV_FAT` | Fat boy | Franklin |
| `CLASS_SURV_SHY` | Shy girl | Sydney |
| `CLASS_SURV_JUNKY` | Junky | Marty |
| `CLASS_SURV_EMO` | Emo | Audrey |
| `CLASS_SURV_BLACK` | Black | Roland |
| `CLASS_SURV_SHERIF` | Sherif | Gale |

**Killer Classes:**

| Constant | Value |
|---|---|
| `CLASS_KILLER` | `1001` |

---

## 2. File Structure

```
Slashers-master/
├── gamemode/
│   ├── cl_init.lua          # Client init
│   ├── init.lua             # Server init
│   ├── shared.lua           # Shared constants (TEAM_*, CLASS_*)
│   ├── config.lua           # GM.CONFIG (killer_weapons, etc.)
│   ├── modulesloader.lua    # Loads all modules from gamemode/modules/
│   ├── core/
│   │   ├── _includes.lua     # All shared/core includes
│   │   ├── convars.lua      # Shared convars
│   │   ├── downloads.lua    # Resource.AddFile / AddCSLuaFile
│   │   ├── fonts.lua        # surface.CreateFont definitions
│   │   ├── format.lua       # String/number formatting helpers
│   │   ├── mapsloader.lua   # Loads map-specific config from maps/
│   │   ├── messages.lua      # HUD message helpers
│   │   ├── class/
│   │   │   ├── sh_class.lua  # GM.CLASS (shared: walkspeed, runspeed, life, stamina, model)
│   │   │   ├── sv_class.lua  # Server class setup (PlayerSpawn, SetModel, etc.)
│   │   │   └── cl_class.lua  # Client-side class data (dispname, description, icon)
│   │   ├── lang/
│   │   │   ├── cl_lang.lua  # Client language setup
│   │   │   └── sv_lang.lua  # Server language setup
│   │   ├── notification/
│   │   │   ├── cl_notification.lua  # Notification panel UI
│   │   │   └── sv_notification.lua  # notificationSlasher net sender
│   │   ├── rounds/
│   │   │   ├── sh_rounds.lua   # GM.ROUND shared table + GetSurvivorsAlive()
│   │   │   ├── cl_network.lua  # Client net.Receive handlers for all round states
│   │   │   ├── cl_rounds.lua   # Client round HUDPaint, CalcView
│   │   │   ├── sv_rounds.lua   # Server round Think, InitPostEntity
│   │   │   └── sv_choosekiller.lua  # Pure-random killer selection
│   │   ├── sounds/
│   │   │   ├── cl_sounds.lua  # Client sound hooks
│   │   │   └── sv_sounds.lua  # Server sound hooks
│   │   └── slot/
│   │       └── sv_slotcheck.lua  # Player slot reservation
│   ├── maps/
│   │   ├── slash_selvage.lua
│   │   ├── slash_highschool.lua
│   │   ├── slash_lodge.lua
│   │   ├── slash_motel.lua
│   │   ├── slash_subway.lua
│   │   └── slash_summercamp.lua
│   ├── modules/          # Plug-and-play; enable/disable via GM.CONFIG.disabled_modules
│   │   ├── antiafk/
│   │   ├── breakdoors/
│   │   ├── chasemode/    # Dynamic chase music
│   │   ├── entityindicator/
│   │   ├── f1menu/       # F1 character info (SERVER: sv_f1menu.lua)
│   │   ├── goal/         # Jerrycans → Generator → Radio progression
│   │   ├── killer_abilities/  # Centralised killer passive abilities (Ghostface, Jason, Myers, Proxy, Intruder, Bates)
│   │   │   ├── sh_abilities.lua  # GM.KillerAbilities registry + net string declarations
│   │   │   ├── sv_abilities.lua  # Server ability logic + engine hook registrations
│   │   │   └── cl_abilities.lua  # Client HUD overlays, 3D render effects, net handlers
│   │   ├── killer_setup/ # Killer character selection + weapon select pipeline
│   │   │   ├── sh_characters.lua  # GM.KillerCharacters shared table
│   │   │   ├── cl_setup.lua       # Client UI for killer char + weapon select
│   │   │   └── sv_setup.lua        # Server pipeline, watchdog, net handlers
│   │   ├── killerhelp/   # Killer anti-camp (door/exit tracking, heartbeat)
│   │   ├── observer/     # Spectator camera system
│   │   ├── postprocess/  # Post-processing effects
│   │   ├── scoreboard/   # TAB scoreboard
│   │   ├── shop/
│   │   ├── soundscape/
│   │   ├── staff/        # sls_admin panel + spectator scare sounds
│   │   ├── stamina/      # Sprint + breathing
│   │   ├── tfa/          # TFA weapon sound/cvar patches
│   │   ├── traps/        # Bear traps, door axes, alert ropes
│   │   ├── votemap/      # End-of-round map voting
│   │   └── weaponselect/ # Killer weapon loadout UI (opened by killer_setup)
│   └── languages/
│       ├── en.lua, de.lua, fr.lua, ko.lua, pl.lua, pt.lua, ru.lua, zh-hans.lua, zh-tw.lua
├── entities/
│   ├── effects/          # TFA bullet/muzzle/ricochet effects
│   ├── entities/
│   │   ├── alertropes/
│   │   ├── batesmum/
│   │   ├── beartrap/
│   │   ├── sls_generator/
│   │   ├── sls_jerrican/
│   │   ├── sls_motherbates/
│   │   ├── sls_radio/
│   │   ├── tfa_ammo_*/   # TFA ammo entities
│   │   ├── tfa_thrown_blade/
│   │   └── tfbow_arrow*  # Bow and arrow entities
│   └── weapons/
│       ├── tfa_nmrih_*/  # NMRiH melee weapons (chainsaw, fireaxe, machete, washingmachine)
│       ├── tfa_nmrih_base/  # Base melee weapon
│       ├── tfa_nmrimelee_base/  # Base melee from TFA
│       ├── weapon_flashlight.lua
│       ├── weapon_beartrap.lua
│       ├── weapon_dooraxe.lua
│       └── weapon_alertropes.lua
└── backgrounds/          # Menu backgrounds
```

---

## 3. Core Global Tables

### GM.ROUND (`core/rounds/sh_rounds.lua`)

```lua
GM.ROUND.Count           -- int: current round number
GM.ROUND.Active         -- bool: round is in progress
GM.ROUND.WaitingPlayers -- bool: waiting for players
GM.ROUND.CameraEnable    -- bool: spectator camera active
GM.ROUND.WaitingPolice   -- bool: police called (escape phase)
GM.ROUND.Escape          -- bool: escape phase active
GM.ROUND.Survivors       -- table<Player>: alive survivors this round
GM.ROUND.Killer          -- Player: the killer entity
GM.ROUND.EndTime         -- int: CurTime() when round ends
GM.ROUND.CameraPos       -- Vector: spectator camera position
GM.ROUND.CameraAng       -- Angle: spectator camera angle
```

**Methods:**
- `GM.ROUND:GetSurvivorsAlive() → table<Player>` — returns only `IsValid(v) && v:Alive()` survivors

### GM.CONFIG (`gamemode/config.lua`)

```lua
GM.CONFIG.disabled_modules    -- table: module names to disable
GM.CONFIG.killer_weapons       -- table<string>: allowed killer weapon classnames
GM.CONFIG.survivors_weapons    -- table<string>: allowed survivor weapon classnames
GM.CONFIG.round_choosekiller_add  -- int: points added to choosekiller per round
GM.CONFIG.round_freeze_start   -- int: freeze time at round start (seconds)
GM.CONFIG.round_duration_end   -- int: end-of-round wait (seconds)
GM.CONFIG.killerhelp_door_entities    -- table<string>: door entity classes
GM.CONFIG.killerhelp_exit_entities     -- table<string>: exit/van entity classes
GM.CONFIG.weaponselect_fallback -- string: fallback weapon if weaponselect fails
```

### GM.CLASS (`core/class/sh_class.lua`)

```lua
GM.CLASS.Survivors[CLASS_SURV_*] = {
    name       = "Sports",
    walkspeed  = 150,
    runspeed   = 240,
    life       = 120,
    stamina    = 210,
    model      = "models/steinman/slashers/sport_pm.mdl",
    die_sound  = "slashers/effects/scream_man_1.wav",
    weapons    = {},         -- additional weapons given on spawn
    keysNumber = 3,         -- some classes (CLASS_SURV_BLACK) have extra keys
}
GM.CLASS.Killers[CLASS_KILLER] = { ... }
```

**Client-only fields** (inside `if CLIENT then` block):
```lua
dispname    = "Trent"         -- display name in UI
description = GM.LANG:GetString("class_desc_sports")
icon        = Material("icons/icon_sportif.png")
```

### GM.KillerCharacters (`modules/killer_setup/sh_characters.lua`)

```lua
GM.KillerCharacters["ghostface"] = {
    name  = "Ghostface",
    model = "models/player/screamplayermodel/scream/scream.mdl",
    walk  = 190,
    run   = 240,
    desc  = "You can see doors opening and closing. Strike from the shadows."
}
-- Also: "jason", "myers", "proxy", "intruder", "bates"
```

### GM.KillerAbilities (`modules/killer_abilities/sh_abilities.lua`)

```lua
GM.KillerAbilities["ghostface"] = {
    hooks = {"PlayerUse", "HUDPaintBackground", "sls_round_PreStart", "sls_round_End"},
    UseAbility = function(ply) ... end,
}
-- Also: "jason" (PlayerFootstep, PostDrawTranslucentRenderables),
--       "myers" (Think, PostPlayerDeath, HUDPaintBackground),
--       "proxy" (Think ×3, PostPlayerDeath, InitPostEntity, ShouldCollide, RenderScreenspaceEffects, HUDPaintBackground),
--       "intruder" (Think, PreDrawHalos),
--       "bates" (sls_round_End only)
```

---

## 4. Custom Hooks (Round Lifecycle)

All hooks are raised via `hook.Run("hook_name", ...)`.

| Hook Name | When | Client | Server |
|---|---|---|---|
| `sls_round_PreStart` | Before round starts — `Active = false`, roles cleared | ✅ | ✅ |
| `sls_round_PostStart` | After roles assigned, round active | ✅ | ✅ |
| `sls_round_StartWaitingPolice` | Police called, escape phase | ✅ | ✅ |
| `sls_round_StartEscape` | Escape phase begins | ✅ | ✅ |
| `sls_round_OnTeamWin(winner)` | Team wins (winner = `TEAM_KILLER` or `TEAM_SURVIVORS`) | ✅ | ✅ |
| `sls_round_End(winner)` | Round ends (before results/restart) | ✅ | ✅ |
| `sls_round_WaitingPlayers` | Waiting for players state changed | ✅ | ✅ |
| `sls_round_PlayerConnect` | Player connects during active round | ✅ | ✅ |
| `sls_round_SetupCamera` | Spectator camera position set | ✅ | ✅ |
| `sls_NextObjective` | Objective progression changes (Jerrycans → Gen → Radio) | ✅ | ✅ |

---

## 5. Network Strings

### Round & Core (defined in `core/rounds/cl_network.lua`)

| Net String | Direction | Payload |
|---|---|---|
| `sls_round_PreStart` | Server → Client | — |
| `sls_round_PostStart` | Server → Client | count(Int16), endTime(Int16), survivors(Table), killer(Entity), classAssignments(Table) |
| `sls_round_StartWaitingPolice` | Server → Client | endTime(Int16) |
| `sls_round_StartEscape` | Server → Client | endTime(Int16) |
| `sls_round_OnTeamWin` | Server → Client | winnerTeam(Int4) |
| `sls_round_End` | Server → Client | winnerTeam(Int4) |
| `sls_round_Update` | Server → Client | survivors(Table) |
| `sls_round_WaitingPlayers` | Server → Client | waiting(Bool) |
| `sls_round_PlayerConnect` | Server → Client | full state snapshot |
| `sls_round_SetupCamera` | Server → Client | cameraPos(Vector), cameraAng(Angle) |

### Notifications & Objectives

| Net String | Direction | Payload |
|---|---|---|
| `notificationSlasher` | Server → Client | text(Table of lang keys), type(String) |
| `objectiveSlasher` | Server → Client | text(Table of lang keys), type(String) |
| `activateProgressionSlasher` | Server → Client | value(Float, 0.0–1.0) |
| `modifyObjectiveSlasher` | Server → Client | text(Table of lang keys) |

### Killer Setup Pipeline

| Net String | Direction | Payload |
|---|---|---|
| `sls_killer_opencharselect` | Server → Killer | charKey(String) |
| `sls_killer_selectchar` | Killer → Server | charKey(String) |
| `sls_killer_openweaponselect` | Server → Killer | — |
| `sls_killer_selectweapon` | Killer → Server | weaponClass(String) |
| `sls_round_PostStart` | Server → All Clients | *(fires globally after weapon select)* |
| `sls_killer_showintro` | Server → Killer | charKey(String) |
| `sls_killer_intro_finished` | Killer → Server | — |
| `sls_killer_sync_character` | Server → All Clients | charKey(String) |

### Killer Abilities (`modules/killer_abilities/`)

| Net String | Direction | Payload |
|---|---|---|
| `sls_kability_AddDoor` | Server → Killer Client | pos(Vector), ang(Angle), doorEnt(Entity) |
| `sls_kability_AddStep` | Server → Killer Client | pos(Vector), foot(Int4), volume(Float) |
| `sls_trapspos` | Server → Intruder | traps(Table of entities) |
| `sls_motherbates` | Server → Bates | — |
| `sls_proxy_invisible` | Server → All Clients | toggle(Bool) |
| `sls_proxy_vulnerable` | Server → All Clients | toggle(Bool) |
| `sls_proxy_setvisible` | Server → All Clients | toggle(Bool) |

### Staff Module

| Net String | Direction | Payload |
|---|---|---|
| `sls_staff_open` | Server → Client | — |
| `sls_staff_action` | Client → Server | action(String), target(Option) |

### Spectator

| Net String | Direction | Payload |
|---|---|---|
| `sls_spectator_scare` | Server → Client | survivorSteamID(String) |

---

## 6. Killer Weapon Select Pipeline

The killer weapon selection is a **4-stage deferred pipeline**. Critically, `sls_round_PostStart` is **NOT** sent at the start of `GM.ROUND:Start()` in `sv_rounds.lua`. It is deliberately deferred and fired only when the killer finishes the entire setup (character + weapon), ensuring all clients receive the correct character data synchronously.

**Pipeline Flow:**

| Stage | Who | Action | Result |
|---|---|---|---|
| 0 | `sv_rounds.lua:Start()` | Picks killer via `sv_choosekiller.lua`, freezes survivors | Killer chosen, survivors frozen |
| 1 | Server → Killer | Sends `sls_killer_opencharselect` (0.5s delay) | Killer's client calls `OpenCharSelectMenu()` |
| 2 | Killer's Client | Killer clicks character → sends `sls_killer_selectchar` | Server sets model/speed, sends `sls_killer_openweaponselect`, starts 30s watchdog |
| 3 | Killer's Client | Killer clicks weapon → sends `sls_killer_selectweapon` | Server gives weapon, **fires `sls_round_PostStart` globally**, sends `sls_killer_showintro`, starts freeze timer |
| 4 | Server | After `round_freeze_start` seconds | Survivors unfreeze |
| 4 | Killer's Client | Killer's intro finishes → sends `sls_killer_intro_finished` | Killer unfrozen |

**Key detail:** `sls_round_PostStart` is fired from `sv_setup.lua` (inside `net.Receive("sls_killer_selectweapon")` and from the watchdog fallback) — **NOT** from `sv_rounds.lua:Start()`. All clients only receive `sls_round_PostStart` after the killer has finished selecting both their character and weapon.

**Watchdog fallback (`sv_setup.lua:StartWeaponSelectWatchdog`):**
- 30-second timer starts when character is selected
- If killer never picks a weapon, auto-gives `GM.CONFIG.killer_weapons[1]` (or `tfa_nmrih_machete`)
- Fires `sls_round_PostStart` globally + sends `sls_killer_showintro` to the killer

**Network strings for this pipeline:**
```lua
sls_killer_opencharselect    -- Server → Killer: open char select UI
sls_killer_selectchar        -- Killer → Server: char key (e.g. "ghostface")
sls_killer_openweaponselect  -- Server → Killer: open weapon select UI
sls_killer_selectweapon      -- Killer → Server: weapon classname
sls_killer_showintro         -- Server → Killer: show cinematic intro
sls_killer_intro_finished    -- Killer → Server: intro done, unfreeze me
sls_killer_sync_character    -- Server → All: broadcast chosen char to all clients
```

**Files involved:**
- [`core/rounds/sv_rounds.lua`](Slashers-master/gamemode/core/rounds/sv_rounds.lua) — `Start()` picks killer, sends `sls_killer_opencharselect`
- [`modules/killer_setup/cl_setup.lua`](Slashers-master/gamemode/modules/killer_setup/cl_setup.lua) — `OpenCharSelectMenu()`, `OpenWeaponSelectMenu()`, `ShowCustomIntro()`
- [`modules/killer_setup/sv_setup.lua`](Slashers-master/gamemode/modules/killer_setup/sv_setup.lua) — all net.Receive handlers, watchdog, PostStart broadcast
- [`modules/killer_setup/sh_characters.lua`](Slashers-master/gamemode/modules/killer_setup/sh_characters.lua) — `GM.KillerCharacters` shared table

**Current killer weapons in config:**
```lua
GM.CONFIG.killer_weapons = {
    "tfa_nmrih_chainsaw",
    "tfa_nmrih_fireaxe",
    "tfa_nmrih_machete",
    "tfa_nmrih_washingmachine"
}
GM.CONFIG.weaponselect_fallback = "tfa_nmrih_chainsaw"
```

---

## 7. Map Configuration (GM.MAP)

Each map file (`maps/slash_*.lua`) sets `GM.MAP`:

```lua
GM.MAP = {
    Name              = "Selvage",
    EscapeDuration    = 180,   -- seconds for escape phase
    StartMusic        = "slashers/music/round_start.mp3",
    ChaseMusic        = "slashers/music/chase.mp3",
    Goal              = {      -- objective progression
        jerrican = { pos = Vector(...), ang = Angle(...) },
        generator = { pos = Vector(...), ang = Angle(...) },
        radio     = { pos = Vector(...), ang = Angle(...) },
    },
    Killer = {
        Name          = "Ghostface",
        Model         = "models/player/screamplayermodel/scream/scream.mdl",
        WalkSpeed     = 190,
        RunSpeed      = 240,
        ExtraWeapons  = {},    -- additional weapons given at spawn
        UseAbility    = function(ply) ... end,  -- custom ability callback
    }
}
```

---

## 8. Objective Progression (sls_NextObjective Hook)

The game follows a fixed 3-stage objective chain:

1. **Jerrycans** — survivors must collect and fill generator
2. **Generator** — survivors must activate generator
3. **Radio** — survivors must activate radio to call police

When the objective changes, the `sls_NextObjective` hook fires with the new objective name.

---

## 9. TFA Weapon Conventions

### Base Classes
- `tfa_nmrih_base` — base for NMRiH-style weapons
- `tfa_nmrimelee_base` — base for all custom melee weapons
- `tfa_nmrimelee_basesafe2` — safe variant used for washing machine
- `tfa_bash_base` — bash/knockback melee base
- `tfa_scoped_base` — scoped weapon base
- `tfa_shotty_base` — shotgun base

### Required Patterns for Custom Melee Weapons

Every custom TFA melee weapon **must** follow these conventions:

```lua
-- 1. Always declare TFA base stubs FIRST (before any SWEP assignment)
local SWEP = {}
SWEP.Base = "tfa_nmrimelee_base"
if SERVER then AddCSLuaFile("shared.lua") end

-- 2. Required TFA base stubs (prevent crashes on clients without the full TFA module)
function SWEP:GetHolstering() return false end
function SWEP:GetChangingSilence() return false end
function SWEP:SetShooting(b) self.Shooting = b end
function SWEP:GetShooting() return false end
function SWEP:IsSilenced() return false end
function SWEP:GetStatus() return 0 end
function SWEP:GetStatusHoldTime() return 0 end

-- 3. Use SWEP.VElements and SWEP.WElements for custom models on ValveBiped.Bip01_R_Hand
SWEP.Spawnable       = true
SWEP.AdminSpawnable   = true
SWEP.Kind            = WEAPON_MELEE
SWEP.PrintName       = "Custom Weapon"
SWEP.Slot            = 0
SWEP.ViewModel        = "models/weapons/v_sten.mdl"
SWEP.WorldModel       = "models/props_c17/oildrum001.mdl"
SWEP.ShowViewModel    = false  -- hide view model, use VElements
SWEP.ShowWorldModel   = false  -- hide world model, use WElements
SWEP.VElements = {
    ["custom_model"] = { type = "Model", model = "models/your/model.mdl",
        bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(0,0,0),
        angle = Angle(0,0,0), size = Vector(1,1,1), color = Color(255,255,255,255) }
}
```

---

## 10. Localization

**All user-facing strings must use `GM.LANG:GetString("key")`. No hardcoded strings in client UI.**

Language files are in [`gamemode/languages/`](Slashers-master/gamemode/languages/).

Usage:
```lua
-- Server & Client
GM.LANG:GetString("class_desc_sports")
GM.LANG:GetString("objective_jerrican")
```

Safe pattern when `GM.LANG` may not exist yet:
```lua
GM.LANG and GM.LANG:GetString("key") or "fallback string"
```

---

## 11. Claude 4.6 Sonnet — Hard Rules (ALWAYS FOLLOW)

### 🔴 Critical Safety Rules

1. **Server-Side Damage:** Any `DamageInfo()` or `TakeDamageInfo()` calls **MUST** be wrapped in `if SERVER then ... end` and `if IsValid(entity) then ... end`. Clients cannot deal damage.
2. **API Rate Limits:** If any API returns **503, 429, or "Concurrency Limit"**, stop immediately. Do not retry. Tell the user the API is overloaded.
3. **Module-First Architecture:** Before modifying core files, ask: "Can this be done as a standalone module?" If yes, create it in `gamemode/modules/`. Only touch core when absolutely necessary.
4. **Round State Guards:** When accessing `GM.ROUND.Active`, always check `if GM.ROUND and GM.ROUND.Active then` — `GM.ROUND` may be nil on first load.

### 🔧 Code Quality Rules

5. **UI Loop Closures:** When creating UI buttons inside a loop over `player.GetAll()`, always capture the loop variable with a local:
   ```lua
   -- ✅ CORRECT
   for _, v in ipairs(player.GetAll()) do
       local targetPly = v
       btn.DoClick = function()
           RunConsoleCommand("sls_admin", "kick", targetPly:Nick())
       end
   end

   -- ❌ WRONG — closure captures `v` by reference
   for _, v in ipairs(player.GetAll()) do
       btn.DoClick = function()
           RunConsoleCommand("sls_admin", "kick", v:Nick()) -- v may have changed!
       end
   end
   ```

6. **Nil Checks on Player Entities:** Always use `IsValid(ply)` before calling methods on player entities from net messages or hooks. Players can disconnect mid-frame.
7. **TFA Base Stubs:** When creating or modifying TFA weapons, always include the full stub block at the top of the file (see Section 9).
8. **Network String Registration:** Always use `util.AddNetworkString("...")` on both server and client (typically at the top of the file, before any `net.Receive` calls).
9. **File Naming Conventions:**
   - Shared files: `sh_*.lua` — add `if SERVER then AddCSLuaFile() end` at the top
   - Server files: `sv_*.lua` — no AddCSLuaFile needed
   - Client files: `cl_*.lua` — no AddCSLuaFile needed
   - Never create a file that mixes client/server logic without proper `if SERVER then` guards

### 📁 File Path Conventions

10. **Always use relative paths from workspace root.** For example: `Slashers-master/gamemode/modules/killer_setup/sh_characters.lua`
11. **When creating new modules**, put them in `gamemode/modules/<module_name>/` with `cl_`, `sv_`, `sh_` files as needed. Add the module folder to `modulesloader.lua` if it uses a non-standard naming pattern.
12. **Map-specific code** goes in `gamemode/maps/slash_<mapname>.lua`.

---

## 12. Staff Module — sls_admin

The staff module (`modules/staff/`) provides admin controls via `sls_admin` console command.

**Actions:** `force_start`, `force_end`, `set_killer <steamid>`, `noclip <steamid>`, `kick <steamid>`

Network strings: `sls_staff_open`, `sls_staff_action`

Spectator scare: `sls_spectator_scare` (survivor hears scare sound when dead player spectates them)

---

## 13. Disabled Module Pattern

To disable a module without deleting it:

```lua
-- In gamemode/config.lua:
GM.CONFIG["disabled_modules"] = {
    -- ["goal"] = true,
    -- ["weaponselect"] = true,
}
```

The `modulesloader.lua` reads this table and skips loading those modules.
