-- Slashers — Survivor Setup Pipeline (Server)
-- Players choose their survivor class via a selection menu.
-- Pipeline:
--   1. sls_round_PreStart → reset ChosenClass for all players
--   2. 5s after killer opens char select → send sls_surv_opencharselect to all survivors
--   3. Survivor clicks a class → sls_surv_selectclass → store ply.ChosenClass
--   4. sls_round_PostStart (fired by killer_setup) → ApplyChosenClasses() makes everyone re-select their class

util.AddNetworkString("sls_surv_opencharselect")
util.AddNetworkString("sls_surv_selectclass")
util.AddNetworkString("sls_surv_sync_class")
util.AddNetworkString("sls_surv_classsetup_timeout")

-- ─────────────────────────────────────────────
-- Reset state at the start of each round
-- ─────────────────────────────────────────────
hook.Add("sls_round_PreStart", "sls_SurvSetup_Reset", function()
    for _, ply in ipairs(player.GetAll()) do
        ply.HasChosenSurvClass = false
        ply.ChosenClass        = nil
    end
end)

-- ─────────────────────────────────────────────
-- Forward declaration so OpenSurvivorCharSelect can call it before
-- the full definition appears below (Lua sequential-parse safety).
-- ─────────────────────────────────────────────
local StartSurvClassWatchdog

-- ─────────────────────────────────────────────
-- Open the survivor class selection menu for all survivors.
-- Called after a short delay from sls_round_PostStart so the killer's
-- character selection phase gives survivors time to browse.
-- ─────────────────────────────────────────────
local function OpenSurvivorCharSelect()
    local survivors = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SURVIVORS and IsValid(ply) then
            table.insert(survivors, ply)
        end
    end

    if #survivors == 0 then return end

    for _, ply in ipairs(survivors) do
        net.Start("sls_surv_opencharselect")
        net.Send(ply)
        StartSurvClassWatchdog(ply)  -- safe: forward-declared above
    end

    print("[Surv-Setup] Class selection menu sent to " .. #survivors .. " survivor(s).")
end

-- Open survivor class selection menu at the same time as the killer's menu —
-- both fire from sls_round_PreStart, each with their own internal timer.
hook.Add("sls_round_PreStart", "sls_SurvSetup_OpenMenu", function()
    OpenSurvivorCharSelect()
end)

-- ─────────────────────────────────────────────
-- Watchdog: if a survivor never picks a class in 10s, auto-assign one
-- ─────────────────────────────────────────────
local TIMER_SURV_SELECT = 10

-- Full definition assigned to the forward-declared upvalue.
StartSurvClassWatchdog = function(ply)
    if not IsValid(ply) then return end
    timer.Remove("sls_SurvSetup_Watchdog_" .. ply:SteamID64())

    timer.Create("sls_SurvSetup_Watchdog_" .. ply:SteamID64(), TIMER_SURV_SELECT, 1, function()
        if not IsValid(ply) then return end
        if ply:Team() ~= TEAM_SURVIVORS then return end
        if ply.HasChosenSurvClass then return end

        -- GAMEMODE is the correct runtime reference; GM may be nil at hook-fire time.
        local gm = GAMEMODE
        if not gm or not gm.CLASS or not gm.CLASS.Survivors then
            print("[Surv-Setup] GAMEMODE.CLASS not ready — skipping auto-assign for " .. ply:Nick())
            return
        end

        print("[Surv-Setup] Survivor " .. ply:Nick() .. " timed out on class selection. Auto-assigning random class.")

        local classes = table.GetKeys(gm.CLASS.Survivors)
        if #classes == 0 then return end
        local chosen  = classes[math.random(#classes)]
        ply.ChosenClass        = chosen
        ply.HasChosenSurvClass = true

        -- Notify client to close menu
        net.Start("sls_surv_classsetup_timeout")
        net.Send(ply)
    end)
end

-- ─────────────────────────────────────────────
-- Net: survivor selects a class
-- ─────────────────────────────────────────────
net.Receive("sls_surv_selectclass", function(len, ply)
    if not IsValid(ply) then return end
    if ply:Team() ~= TEAM_SURVIVORS then return end
    if ply.HasChosenSurvClass then return end

    -- Use GAMEMODE (not GM) — GM can be nil at net-receive time.
    local gm = GAMEMODE
    if not gm or not gm.CLASS or not gm.CLASS.Survivors then
        print("[Surv-Setup] GAMEMODE.CLASS not ready — ignoring class selection from " .. ply:Nick())
        return
    end

    local classKey = net.ReadString()
    local classID  = gm.SurvivorClasses and gm.SurvivorClasses[classKey] and gm.SurvivorClasses[classKey].key

    if not classID or not gm.CLASS.Survivors[classID] then
        print("[Surv-Setup] Invalid class key from " .. ply:Nick() .. ": " .. tostring(classKey))
        return
    end

    ply.ChosenClass        = classID
    ply.HasChosenSurvClass = true

    -- Cancel watchdog
    timer.Remove("sls_SurvSetup_Watchdog_" .. ply:SteamID64())

    -- Sync chosen class to all clients for HUD/scoreboard display
    net.Start("sls_surv_sync_class")
        net.WriteEntity(ply)
        net.WriteString(classKey)
    net.Broadcast()

    print("[Surv-Setup] " .. ply:Nick() .. " chose class: " .. classKey)
end)

-- ─────────────────────────────────────────────
-- ApplyChosenClasses — finalize each survivor's chosen class.
-- Defined on GAMEMODE.CLASS (the live table at runtime) rather than GM
-- (which is only valid during the file-load phase).
-- Called from the sls_round_PostStart hook below.
-- ─────────────────────────────────────────────
local function ApplyChosenClasses(self)
    local gm = GAMEMODE
    if not gm or not gm.CLASS or not gm.CLASS.Survivors then
        print("[Surv-Setup] GAMEMODE.CLASS not ready — cannot apply survivor classes.")
        return
    end

    local applied = 0
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply:Team() ~= TEAM_SURVIVORS then continue end

        local classID = ply.ChosenClass
        if not classID then
            -- Fallback: pick a random unassigned class
            local available = {}
            for class, _ in pairs(gm.CLASS.Survivors) do
                local taken = false
                for _, other in ipairs(player.GetAll()) do
                    if IsValid(other) and other ~= ply and other.ChosenClass == class then
                        taken = true
                        break
                    end
                end
                if not taken then
                    table.insert(available, class)
                end
            end
            classID = available[math.random(#available)] or CLASS_SURV_SPORTS
            ply.ChosenClass = classID
            print("[Surv-Setup] No class chosen by " .. ply:Nick() .. ", auto-assigned: " .. tostring(classID))
        end

        ply:SetSurvClass(classID)
        applied = applied + 1
    end

    print("[Surv-Setup] Applied chosen classes to " .. applied .. " survivor(s).")
end

-- Attach to GAMEMODE.CLASS at load-time if it already exists;
-- otherwise defer to a hook so the table is guaranteed to exist at call-time.
if GAMEMODE and GAMEMODE.CLASS then
    GAMEMODE.CLASS.ApplyChosenClasses = ApplyChosenClasses
end

-- ─────────────────────────────────────────────
-- Finalize survivor classes after the round officially starts.
-- GAMEMODE is the correct runtime reference — GM can be nil by the time
-- this hook fires asynchronously during play.
-- ─────────────────────────────────────────────
hook.Add("sls_round_PostStart", "sls_SurvSetup_ApplyClasses", function()
    local gm = GAMEMODE
    if not gm or not gm.CLASS then
        print("[Surv-Setup] GAMEMODE.CLASS not ready at PostStart — skipping ApplyChosenClasses.")
        return
    end

    -- Ensure the method is present regardless of load order.
    if not gm.CLASS.ApplyChosenClasses then
        gm.CLASS.ApplyChosenClasses = ApplyChosenClasses
    end

    gm.CLASS:ApplyChosenClasses()
end)

-- NOTE: The client-side sls_surv_classsetup_timeout net.Receive (which
-- closes SlashersSurvCharFrame) belongs in a cl_*.lua file. It has been
-- removed from this server-only module to prevent a server-side nil-panel crash.
