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
        StartSurvClassWatchdog(ply)
    end

    print("[Surv-Setup] Class selection menu sent to " .. #survivors .. " survivor(s).")
end

-- Hook into the killer setup pipeline:
-- After the killer picks their character (not weapon), send the survivor menu.
-- This fires from sv_setup.lua's sls_killer_selectchar handler.
hook.Add("sls_surv_KillerCharSelected", "sls_SurvSetup_OpenMenu", function(ply)
    if not IsValid(ply) then return end
    -- Wait 5 seconds after the killer picks their character before opening survivor menus
    timer.Simple(5, function()
        OpenSurvivorCharSelect()
    end)
end)

-- ─────────────────────────────────────────────
-- Watchdog: if a survivor never picks a class in 10s, auto-assign one
-- ─────────────────────────────────────────────
local TIMER_SURV_SELECT = 10

local function StartSurvClassWatchdog(ply)
    if not IsValid(ply) then return end
    timer.Remove("sls_SurvSetup_Watchdog_" .. ply:SteamID64())

    timer.Create("sls_SurvSetup_Watchdog_" .. ply:SteamID64(), TIMER_SURV_SELECT, 1, function()
        if not IsValid(ply) then return end
        if ply:Team() ~= TEAM_SURVIVORS then return end
        if ply.HasChosenSurvClass then return end

        print("[Surv-Setup] Survivor " .. ply:Nick() .. " timed out on class selection. Auto-assigning random class.")

        local classes = table.GetKeys(GM.CLASS.Survivors)
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

    local classKey = net.ReadString()
    local classID  = GM.SurvivorClasses[classKey] and GM.SurvivorClasses[classKey].key

    if not classID or not GM.CLASS.Survivors[classID] then
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
-- Called from GM.CLASS:ApplyChosenClasses() (sv_class.lua)
-- after sls_round_PostStart to finalize each survivor's class.
-- ─────────────────────────────────────────────
function GM.CLASS:ApplyChosenClasses()
    local applied = 0
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply:Team() ~= TEAM_SURVIVORS then continue end

        local classID = ply.ChosenClass
        if not classID then
            -- Fallback: pick a random unassigned class
            local available = {}
            for class, _ in pairs(GM.CLASS.Survivors) do
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

-- ─────────────────────────────────────────────
-- Finalize survivor classes after the round officially starts.
-- Called after sls_round_PostStart so all clients have the killer's
-- chosen character data, and survivors have had a chance to pick their class.
-- ─────────────────────────────────────────────
hook.Add("sls_round_PostStart", "sls_SurvSetup_ApplyClasses", function()
    GM.CLASS:ApplyChosenClasses()
end)

-- ─────────────────────────────────────────────
-- Client-side class selection timeout — close survivor menu
-- ─────────────────────────────────────────────
net.Receive("sls_surv_classsetup_timeout", function(len)
    if IsValid(SlashersSurvCharFrame) then
        SlashersSurvCharFrame:Remove()
    end
    SlashersSurvCharFrame = nil
    hook.Remove("Think", "sls_SurvSelectTimer")
    print("[Surv-Setup] Survivor class menu auto-closed (timeout).")
end)
