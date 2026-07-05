-- Slashers — Survivor Classes Registry (Shared)
-- Mirrors the pattern of GM.KillerCharacters / killer_setup/sh_characters.lua

if SERVER then AddCSLuaFile() end

-- Map survivor CLASS_* constants to display metadata for the selection menu.
-- The class data itself lives in GM.CLASS.Survivors (core/class/sh_class.lua).
-- This registry adds UI-specific fields (icon, short_desc).

GM.SurvivorClasses = {
    ["sports"] = {
        key      = CLASS_SURV_SPORTS,
        icon     = "icons/icon_sportif.png",
        short_desc = "High stamina. Fast runner.",
    },
    ["popular"] = {
        key      = CLASS_SURV_POPULAR,
        icon     = "icons/icon_popular.png",
        short_desc = "Average stats. Popular.",
    },
    ["nerd"] = {
        key      = CLASS_SURV_NERD,
        icon     = "icons/icon_nerd.png",
        short_desc = "Starts with detector.",
    },
    ["fat"] = {
        key      = CLASS_SURV_FAT,
        icon     = "icons/icon_fat.png",
        short_desc = "High health. Low stamina.",
    },
    ["shy"] = {
        key      = CLASS_SURV_SHY,
        icon     = "icons/icon_shy.png",
        short_desc = "Low health. High stamina.",
    },
    ["junky"] = {
        key      = CLASS_SURV_JUNKY,
        icon     = "icons/icon_junky.png",
        short_desc = "Balanced stats.",
    },
    ["emo"] = {
        key      = CLASS_SURV_EMO,
        icon     = "icons/icon_emo.png",
        short_desc = "Balanced stats.",
    },
    ["black"] = {
        key      = CLASS_SURV_BLACK,
        icon     = "icons/icon_black.png",
        short_desc = "Starts with extra keys.",
    },
    ["sherif"] = {
        key      = CLASS_SURV_SHERIF,
        icon     = "icons/icon_sherif.png",
        short_desc = "Starts with stun gun.",
    },
}
