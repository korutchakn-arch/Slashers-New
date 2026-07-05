-- Slashers — Killer Weapon Selection Module (Server)

util.AddNetworkString("sls_killer_openweaponselect")
util.AddNetworkString("sls_killer_selectweapon")

-- Reset HasChosenWeapon at the start of each round
hook.Add("sls_round_PreStart", "sls_Weaponselect_Reset", function()
	for _, ply in ipairs(player.GetAll()) do
		ply.HasChosenWeapon = false
	end
end)

-- Handle weapon selection from the client
net.Receive("sls_killer_selectweapon", function(len, ply)
	local weaponClass = net.ReadString()

	-- Validate: player must be a valid killer who hasn't chosen yet
	if not IsValid(ply) then return end
	if ply:Team() ~= TEAM_KILLER then return end
	if ply.HasChosenWeapon then return end

	-- Validate: weapon must be in the allowed config list
	local allowedWeapons = GAMEMODE.CONFIG["killer_weapons"]
	local valid = false
	for _, class in ipairs(allowedWeapons) do
		if class == weaponClass then
			valid = true
			break
		end
	end
	if not valid then return end

	-- Give the weapon and finalize
	ply:Give(weaponClass)
	ply:SelectWeapon(weaponClass)
	ply.InitialWeapon = weaponClass
	ply.HasChosenWeapon = true
end)
