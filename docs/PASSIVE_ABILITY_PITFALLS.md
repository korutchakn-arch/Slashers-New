# Passive Ability Pitfalls — Slashers Developer Guide

## Why Check `ChosenCharacter` If the Function is Named `KA_myers_*`?

A common question: "Why do I need `if killer.ChosenCharacter ~= "myers"` inside a
function called `KA_myers_ActivateInvisibility`? The name already tells us it's
Myers-specific."

In Lua, function names are **just strings** — they carry no enforcement. Anyone
can call any function from anywhere. There are three concrete reasons this guard
is non-negotiable:

### 1. Hooks are registered by string name, not by function identity

```lua
-- RegisterAbilityHooks("myers") adds:
hook.Add("Think", "ka_myers_Think", KA_myers_Think)

-- But nothing prevents accidental or buggy registration:
hook.Add("Think", "ka_jason_Think", KA_myers_ActivateInvisibility) -- wrong func
```

A mistyped hook registration silently wires Myers' invisibility into Jason's
`Think` loop. Without the guard, every Jason player would go invisible. With
the guard, it's a harmless no-op.

### 2. `EmitSound` broadcasts to every player in range — not just the target

This is the **real-world bug from this session**:

```lua
-- WRONG: Guard placed after EmitSound
function KA_myers_ActivateInvisibility(killer)
    killer:EmitSound("slashers/effects/proxy_power_on.wav")  -- All players hear this
    if killer.ChosenCharacter ~= "myers" then return end     -- Too late!
end
```

`EmitSound` is a **server broadcast** — it plays to everyone within PVS/AudioRange
regardless of who `killer` is. The guard must be *before* it, or the sound plays
for every player even if the actual killer is not Myers.

### 3. The race condition proof — server-side guard is the only real fix

The bug in this session: `sls_kability_*` messages arrived on Client A (Jason)
*before* `sls_killer_sync_character`. At that moment `ChosenCharacter` was `nil`:

```lua
if LocalPlayer().ChosenCharacter ~= "myers" then return end  -- nil ~= "myers" → TRUE → passes through
```

Jason's client ran Myers' effect code. The client-side guard alone could not stop
this. The **server-side guard** at every `net.Send` site is the only layer that
prevents the wrong message from ever reaching the wrong player.

### Mental model: the guard is an airlock

The guard doesn't say "I expect this to be called wrong." It says "I refuse to
assume it won't be." It is the function's identity card check at the door. No
matter how the function got called — direct invocation, wrong hook registration,
race-condition message arrival — the guard rejects anything that isn't Myers.

**Rule: always guard at the top of character-specific functions, before
`EmitSound`, before `net.Start`, before any state mutation.**

---

This document covers the most common mistakes when implementing passive abilities
(triggers that run continuously, invisibility, wallhacks, etc.) across multiple
killer characters in Garry's Mod Lua (Glua).

---

## 1. The Race Condition (Root Cause of 90% of Cross-Character Bugs)

### What happens

```
Server sends: sls_kability_myers_xyz  ──────────────────────► Client A (Jason)
Server sends: sls_killer_sync_character ──────► Client A (Jason)
```

Both messages travel over the network independently. The `sls_kability_*` message
arrives **first** for Client A (Jason). At that moment:

```lua
-- Client A (Jason) executes sls_kability_myers_xyz receiver:
if LocalPlayer().ChosenCharacter ~= "myers" then return end  -- ChosenCharacter is NIL!
-- nil ~= "myers"  →  TRUE  →  the guard PASSES THROUGH
-- Jason now runs Myers' effect code — invisible, wallhack, etc.
```

`ChosenCharacter` is `nil` because `sls_killer_sync_character` hasn't arrived yet.

### Why it's so hard to catch

- It only happens when the net message ordering is unlucky (race condition)
- It works fine in solo testing (both messages arrive fast, order is consistent)
- It only breaks on a live server with latency variance
- The bug is invisible — the code looks correct

### How to fix it — choose one or combine both

**Fix A — Client-side (defense-in-depth):** Always set `LocalPlayer().ChosenCharacter`
immediately when `sls_killer_sync_character` arrives:

```lua
-- In cl_setup.lua, sls_killer_sync_character receiver:
net.Receive("sls_killer_sync_character", function()
    local charKey = net.ReadString()
    LocalPlayer().ChosenCharacter = charKey   -- ← Set BEFORE any other receiver runs
    -- ... rest of character sync logic
end)
```

**Fix B — Server-side (correct):** Guard at every single net send site on the **server**:

```lua
-- WRONG: Guard on client, after EmitSound
function KA_myers_ActivateInvisibility(killer)
    killer:EmitSound("slashers/effects/proxy_power_on.wav")  -- Fires for everyone!
    if killer.ChosenCharacter ~= "myers" then return end     -- Too late
    -- ...
end

-- CORRECT: Guard at top, before EmitSound
function KA_myers_ActivateInvisibility(killer)
    if killer.ChosenCharacter ~= "myers" then return end     -- Guard first
    if killer.MyersIsInvisible then return end               -- Then early returns
    killer:EmitSound("slashers/effects/proxy_power_on.wav")  -- Now safe
    -- ...
end
```

**The rule:** The server must never send a message to the wrong player in the first
place. Client-side guards are defense-in-depth only.

---

## 2. Net Message Guards — Order Matters

When you add a `ChosenCharacter` guard, it must be:

1. **Before** `EmitSound` (sounds play to all players, not just the target)
2. **Before** `net.Start` (don't waste bandwidth on a message nobody should receive)
3. **Before** any state mutation (`killer.MyersIsInvisible = true`, etc.)

```lua
function KA_myers_ActivateInvisibility(killer)
    -- 1. Validity check
    if not IsValid(killer) then return end

    -- 2. ChosenCharacter guard — BEFORE everything else
    if killer.ChosenCharacter ~= "myers" then return end

    -- 3. State guards (is it already invisible? ability on cooldown?)
    if killer.MyersIsInvisible then return end

    -- 4. NOW safe to mutate state and emit effects
    killer.MyersIsInvisible = true
    killer:EmitSound("slashers/effects/proxy_power_on.wav")
    net.Start("sls_kability_Invisible")
        net.WriteBool(true)
    net.Send(killer)
end
```

### Common mistake: double `net.ReadInt`

```lua
-- WRONG: Reading the same value twice consumes two different bytes
util.AddNetworkString("sls_kability_myers")
net.Receive("sls_kability_myers", function()
    local status = net.ReadInt(2)   -- Reads byte 1
    local status2 = net.ReadInt(2)  -- Reads byte 2 → completely wrong value
    -- ...
end)

-- CORRECT: Read once, reuse
net.Receive("sls_kability_myers", function()
    local status = net.ReadInt(2)   -- Read once
    if status == 1 then
        -- use status here
    elseif status == 0 then
        -- use status again here
    end
end)
```

---

## 3. Passive Ability Logic — Think Hook Timing

Passive abilities typically use a `Think` hook that runs every frame (or every
server tick). The most common bugs:

### Bug: Using a stale timestamp for cooldown tracking

```lua
-- WRONG: MyersLastMoveTime is set at round start, never updated
function KA_myers_Think(killer)
    if killer.MyersIsInvisible then return end
    -- Every frame, check: "has player been still for 3 seconds?"
    if CurTime() - killer.MyersLastMoveTime >= 3 then
        KA_myers_ActivateInvisibility(killer)  -- Activates every tick once condition met!
    end
end

-- FIX: KA_myers_PlayerButtonDown must also update MyersLastMoveTime on attack
local function KA_myers_PlayerButtonDown(ply, button)
    if button ~= KEY_ATTACK then return end
    if ply.MyersIsInvisible then
        KA_myers_DeactivateInvisibility(ply, "attack_button")
    end
    ply.MyersLastMoveTime = CurTime()  -- ← Reset the 3-second timer on attack
end
```

### Bug: Think hook re-triggers immediately after deactivation

```lua
-- WRONG: After deactivation, the next Think tick sees the same stale timestamp
-- and immediately re-activates invisibility.
function KA_myers_DeactivateInvisibility(killer, reason)
    killer.MyersIsInvisible = false
    -- No reset of MyersLastMoveTime → next Think tick sees curtime - stale >= 3
    -- → re-cloaks instantly
end

-- FIX: Reset the timer whenever the player takes any action
ply.MyersLastMoveTime = CurTime()
```

---

## 4. EmitSound Plays to Everyone — Even Non-Targets

`Entity:EmitSound` plays to all players in range (typically PVS/AudioRange), not
just the killer. This is a **server-side broadcast**, not a directed message.

```lua
-- WRONG: Sound plays for Jason even though he's not Myers
function KA_myers_ActivateInvisibility(killer)
    killer:EmitSound("slashers/effects/proxy_power_on.wav")  -- Everyone hears it
    -- ... guard too late ...
end

-- CORRECT: Guard BEFORE EmitSound
function KA_myers_ActivateInvisibility(killer)
    if killer.ChosenCharacter ~= "myers" then return end  -- Blocks sound entirely
    killer:EmitSound("slashers/effects/proxy_power_on.wav")
end
```

---

## 5. `EntityTakeDamage` Only Fires on Actual Damage

A common misconception: "I can detect an attack by listening for `EntityTakeDamage`."

This is **false** for melee weapons:
- Air swings (whiffed attacks) → `EntityTakeDamage` does NOT fire
- Attacks that deal 0 damage → `EntityTakeDamage` does NOT fire

```lua
-- WRONG: Only detects successful hits
hook.Add("EntityTakeDamage", "ka_myers_uncloak_on_hit", function(ent, dmginfo)
    if ent.ChosenCharacter == "myers" and ent:IsPlayer() then
        KA_myers_DeactivateInvisibility(ent, "damage_taken")
    end
end)

-- CORRECT: Use PlayerButtonDown for attack detection (covers ALL attacks)
hook.Add("PlayerButtonDown", "ka_myers_uncloak_on_attack", function(ply, button)
    if button ~= KEY_ATTACK then return end
    if ply.ChosenCharacter ~= "myers" then return end
    if ply.MyersIsInvisible then
        KA_myers_DeactivateInvisibility(ply, "attack_button")
    end
    ply.MyersLastMoveTime = CurTime()  -- Reset standing-still timer
end)
```

**Note:** `PlayerButtonDown` fires when the player **presses** the attack key — it
doesn't care if the attack hits, misses, or deals zero damage. It is the correct
hook for "player tried to attack."

---

## 6. Hook Lifecycle — Always Clean Up Between Rounds

Hooks registered in `sls_round_PostStart` must be unregistered in `sls_round_End`,
otherwise:

- A player who played Myers in round 1 still has Myers hooks active in round 2
  when they're playing Jason
- `Think` hooks keep running for a disconnected player's entity

```lua
local function RegisterAbilityHooks(charKey)
    if registeredHooks[charKey] then return end

    if charKey == "myers" then
        hook.Add("Think", "ka_myers_Think", KA_myers_Think)
        hook.Add("EntityTakeDamage", "ka_myers_dmg", KA_myers_EntityTakeDamage)
        hook.Add("PlayerButtonDown", "ka_myers_attack", KA_myers_PlayerButtonDown)
        -- ...
    elseif charKey == "jason" then
        hook.Add("Think", "ka_jason_Think", KA_jason_Think)
        -- ...
    end

    registeredHooks[charKey] = true
end

local function DeactivateAllAbilityHooks()
    for charKey, _ in pairs(registeredHooks) do
        UnregisterAbilityHooks(charKey)
    end
end
```

---

## 7. Client vs Server — Where Does Each Type of Logic Belong?

| What | Client (cl_*.lua) | Server (sv_*.lua) |
|---|---|---|
| Visual effects (`Draw`, `HUDPaint`, `PostDraw*`) | ✅ Yes | ❌ No |
| Sound effects (`EmitSound`) | ❌ No (unreliable) | ✅ Yes |
| Net receivers (reading data from server) | ✅ Yes | ❌ No |
| Net sends (writing data to client) | ❌ No | ✅ Yes |
| Cooldown timers, ability state | ❌ No (exploitable) | ✅ Yes |
| `ChosenCharacter` guard (defense-in-depth) | ✅ Yes | ✅ Yes (required) |
| `ChosenCharacter` guard (before EmitSound) | N/A | ✅ Yes (required) |

---

## 8. Active vs Passive Abilities — Why Passive Needs Extra Guards

Jason's fusebox doesn't need `ChosenCharacter` guards. Myers' invisibility does.
Here's the difference:

### Jason's Fusebox — Entity-based (no guard needed)

```lua
-- Jason activates ability → spawns a named entity
function KA_jason_UseAbility(ply)
    local fusebox = ents.Create("sls_fusebox")
    fusebox:SetPos(randomPosition)
    fusebox:Spawn()
end

-- The entity has its own class and hooks — they ONLY run when the entity exists
function ENT:Use(activator, caller)
    if self.Destroyed then return end
    self.Destroyed = true
    TriggerBlackout(activator)
end
```

**No guard needed:** The fusebox entity only exists if Jason spawned it. No entity →
no code runs → nothing to guard. Isolation is **structural**: the ability is a
physical object that either exists or doesn't.

### Myers' Invisibility — Player-based (guard required)

```lua
-- Myers activates ability → modifies the PLAYER entity itself
function KA_myers_ActivateInvisibility(killer)
    killer.MyersIsInvisible = true
    killer:AddEffects(EF_NOSHADOW)
    killer:EmitSound("slashers/effects/proxy_power_on.wav")
end

-- The Think hook runs EVERY FRAME for EVERY PLAYER on the server
hook.Add("Think", "ka_myers_Think", function()
    for _, ply in ipairs(player.GetAll()) do
        -- This loop runs for EVERY player — including Jason
        if ply.MyersIsInvisible then
            KA_myers_ApplyInvisibilityEffects(ply)  -- Applies to Jason too without a guard!
        end
    end
end)
```

**Guard required:** The ability is baked into the player entity. Every `Think` tick
runs for every player. There's no "Jason's player doesn't have this code" — it does.
The code just needs a runtime check to verify the player is actually Myers.

### Proxy vs Myers — why Proxy doesn't need `ChosenCharacter` guards

This is the key insight that answers your question. Look at how Proxy's server `Think` validates:

```lua
-- Proxy's KA_proxy_Think (sv_abilities.lua:657)
function KA_proxy_Think()
    local proxy = GM.ROUND.Killer        -- Direct reference to the actual killer entity
    if not IsValid(proxy) then return end
    if proxy.ChosenCharacter ~= "proxy" then return end  -- ← Guard checks GM.ROUND.Killer
    -- ...
end
```

It checks `GM.ROUND.Killer` — the authoritative killer entity tracked by the round system.
This is set by `sls_round_PostStart` which fires **synchronously** on the server when the
round begins. There's no race condition because the round system doesn't rely on an
asynchronous network message to know who the killer is.

Myers' `KA_myers_Think` checks `ply` (the player passed to the hook), which comes from
`player.GetAll()` — every player on the server. If the round system doesn't guard this
properly, Myers' code can run for non-Myers players.

**Why Proxy's client-side hooks are also safe:**

```lua
-- Proxy's RenderScreenspaceEffects (cl_abilities.lua:228)
function KA_proxy_InvisibleVision()
    local proxy = LocalPlayer()
    if not IsValid(proxy) then return end
    if proxy.ChosenCharacter ~= "proxy" then return end
    if not proxy.InvisibleActive then return end
    -- Apply post-process effect only for Proxy
end
```

Proxy's client-side code checks `LocalPlayer().ChosenCharacter` too — but it works because
`cl_setup.lua` sets `LocalPlayer().ChosenCharacter` immediately when `sls_killer_sync_character`
arrives. Myers had the same guard, but the **race condition** (message ordering) broke it.

### The fundamental difference

| Character | What it checks | Race condition? | Needs `ChosenCharacter` guard? |
|---|---|---|---|
| Proxy | `GM.ROUND.Killer` (set synchronously at round start) | No | Client-side only (defense-in-depth) |
| Myers | `ply` from `player.GetAll()` or `LocalPlayer().ChosenCharacter` (set async via network) | Yes — `nil ~= "myers"` passes through | **Yes — both server and client** |

The guard is not about "is this function named correctly." It's about compensating for the
fact that the identity data comes from an **asynchronous network message** that can arrive
in any order relative to other messages. Proxy sidesteps this by using a **synchronous**
source of truth (`GM.ROUND.Killer`). Myers doesn't have that option because its ability
affects every player tick.

---

### The rule of thumb

| Ability type | Isolation mechanism | Needs `ChosenCharacter` guard? |
|---|---|---|
| Entity-based (fusebox, bear trap, door axe) | Entity either exists or doesn't → code only runs when entity exists | No |
| Player-based + synchronous identity check (`GM.ROUND.Killer`) | Round system sets identity at round start, no async message needed | Client-side only |
| Player-based + asynchronous identity check (`LocalPlayer().ChosenCharacter` via net msg) | Identity arrives via async network message → race condition possible | **Yes — both server and client** |

---

## 9. Checklist Before Shipping a Passive Ability

- [ ] `ChosenCharacter` guard on the server at **every** net send site
- [ ] `ChosenCharacter` guard at the **top** of the function, before `EmitSound`
- [ ] `ChosenCharacter` guard on the client as defense-in-depth
- [ ] `sls_killer_sync_character` receiver sets `LocalPlayer().ChosenCharacter` first
- [ ] Attack detection uses `PlayerButtonDown`, not only `EntityTakeDamage`
- [ ] Every state mutation resets any associated timer variables
- [ ] Hooks are registered on `sls_round_PostStart` and removed on `sls_round_End`
- [ ] Net message values read once and reused, not read twice
- [ ] Test on a live server with at least 2 players on different characters

---

## 9. The Golden Rule

> **Trust nothing on the client. Guard everything on the server.**

The server is the single source of truth. If a `sls_kability_*` message should only
be received by Myers, the **server must never send it to anyone else**. Client-side
guards are useful for debugging and as a fallback, but they cannot prevent sounds
from playing, state from mutating, or network traffic from being sent.
