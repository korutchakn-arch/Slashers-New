-- Utopia Games - Slashers
--
-- @Author: Garrus2142
-- @Date:   2017-07-25 16:15:45
-- @Last Modified by:   Garrus2142
-- @Last Modified time: 2017-08-07T18:52:51+02:00

local GM = GM or GAMEMODE
GM.CONFIG = {}

GM.CONFIG["disabled_modules"] = {
	-- ["goal"] = true, -- set true to disable module
	-- weaponselect is disabled: the killer_setup module owns the full
	-- weapon-selection pipeline (10s countdown timer, watchdog, intro,
	-- PostStart broadcast). The weaponselect module's duplicate handlers
	-- intercepted sls_killer_selectweapon and silently consumed it before
	-- sv_setup.lua could fire sls_round_PostStart / sls_killer_showintro,
	-- leaving the player frozen with no intro.
	["weaponselect"] = true,
}

-- Armes pour le tueur
GM.CONFIG["killer_weapons"] = {
	"tfa_nmrih_chainsaw",
	-- "tfa_nmrih_kknife",
	"tfa_nmrih_fireaxe",
	"tfa_nmrih_machete",
	"tfa_nmrih_washingmachine"
}
-- Armes pour les survivants
GM.CONFIG["survivors_weapons"] = {
	"weapon_flashlight"
}
-- Points ajoutés de choosekiller ajoutés à chaque manche terminée
GM.CONFIG["round_choosekiller_add"] = 10
-- Temps de démarrage de la manche (secondes)
GM.CONFIG["round_freeze_start"] = 10
-- Durée d'attente lors d'une fin de manche
GM.CONFIG["round_duration_end"] = 30

-- Entités Killerhelp porte
GM.CONFIG["killerhelp_door_entities"] = {
	"prop_door_rotating",
	"func_door_rotating"
}
-- Entités sorties
GM.CONFIG["killerhelp_exit_entities"] = {
	"brush_car_1",
	"brush_car_2",
	"door_exit_1",
	"door_exit_2",
	"door_exit_3",
	"door_exit_4"
}

-- ══════════════════════════════════════════════════════════════
--  WEAPON SELECT MODULE
-- ══════════════════════════════════════════════════════════════
-- Fallback weapon given to the killer if the weaponselect module
-- fails or if a killer somehow avoids picking (shouldn't happen
-- with the close-exploit fix, but acts as a safety net).
GM.CONFIG["weaponselect_fallback"] = "tfa_nmrih_chainsaw"
