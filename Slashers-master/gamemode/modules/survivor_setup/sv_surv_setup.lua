-- Slashers — Survivor Setup Pipeline (Server)
-- Players choose their survivor class via a selection menu.
-- Pipeline:
--   1. sls_round_PreStart           → reset ChosenClass for all players
--   2. sls_surv_KillerCharSelected  → killer has picked their character; teams are now
--                                      fully assigned → open survivor class-select menu
--   3. sls_surv_selectclass         → survivor clicks a class → store ply.ChosenClass
--   4. sls_surv_ClassSetupComplete  → ALL survivors have chosen (or timed out) →
--                                      ApplyChosenClasses(), set SurvivorsReady=true,
--                                      call CheckSetupComplete() to potentially fire PostStart

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

-- Open the survivor class selection menu only AFTER the killer has chosen their
-- character. By this point GM.CLASS:SetupSurvivors() has already run inside
-- GM.ROUND:Start(), so ply:Team() == TEAM_SURVIVORS is guaranteed to be correct.
-- Firing on sls_round_PreStart was the wrong hook because teams aren't assigned yet.
hook.Add("sls_surv_KillerCharSelected", "sls_SurvSetup_OpenMenu", function(killer)
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

        -- Check whether every survivor is now accounted for.
        -- If so, signal the synchronisation barrier so PostStart can fire.
        local allDone = true
        local gm2 = GAMEMODE
        if gm2 and gm2.ROUND and gm2.ROUND.Survivors then
            for _, s in ipairs(gm2.ROUND.Survivors) do
                if IsValid(s) and not s.HasChosenSurvClass then
                    allDone = false
                    break
                end
            end
        end
        if allDone then
            hook.Run("sls_surv_ClassSetupComplete")
            if gm2 and gm2.ROUND then
                gm2.ROUND.SurvivorsReady = true
                gm2.ROUND:CheckSetupComplete()
            end
        end
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

    -- Cancel watchdog — this survivor chose in time
    timer.Remove("sls_SurvSetup_Watchdog_" .. ply:SteamID64())

    -- Sync chosen class to all clients for HUD/scoreboard display
    net.Start("sls_surv_sync_class")
        net.WriteEntity(ply)
        net.WriteString(classKey)
    net.Broadcast()

    print("[Surv-Setup] " .. ply:Nick() .. " chose class: " .. classKey)

    -- Check whether every survivor has now chosen. If so, trigger the
    -- synchronisation barrier so PostStart can fire once the killer is ready too.
    local allDone = true
    local gm2 = GAMEMODE
    if gm2 and gm2.ROUND and gm2.ROUND.Survivors then
        for _, s in ipairs(gm2.ROUND.Survivors) do
            if IsValid(s) and not s.HasChosenSurvClass then
                allDone = false
                break
            end
        end
    end
    if allDone then
        hook.Run("sls_surv_ClassSetupComplete")
        if gm2 and gm2.ROUND then
            gm2.ROUND.SurvivorsReady = true
            gm2.ROUND:CheckSetupComplete()
        end
    end
end)

-- ─────────────────────────────────────────────
-- ApplyChosenClasses — finalize each survivor's chosen class.
-- Called from sls_surv_ClassSetupComplete (below), which fires only once
-- ALL survivors have chosen (or their 10-second watchdog has expired).
-- This guarantees survivors always get their full selection window and the
-- cinematic can never appear on top of the still-open class-select menu.
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
-- Fired when all survivors have chosen their class (or timed out).
-- This is the survivor side of the synchronisation barrier:
--   • ApplyChosenClasses() is called here to lock in each survivor's class.
--   • SurvivorsReady is set to true.
--   • CheckSetupComplete() is called so PostStart fires only when the killer
--     is also ready — preventing cinematic/menu overlap.
-- ─────────────────────────────────────────────
hook.Add("sls_surv_ClassSetupComplete", "sls_SurvSetup_ApplyClasses", function()
    local gm = GAMEMODE
    if not gm or not gm.CLASS then
        print("[Surv-Setup] GAMEMODE.CLASS not ready at ClassSetupComplete — skipping ApplyChosenClasses.")
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
