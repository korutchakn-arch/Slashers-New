SWEP.Base = "tfa_nmrimelee_base"
SWEP.Category = "TFA NMRIH"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.PrintName = "Maglite"

SWEP.ViewModel			= "models/weapons/tfa_nmrih/v_item_maglite.mdl"
SWEP.ViewModelFOV = 50

SWEP.WorldModel			= "models/weapons/tfa_nmrih/w_item_maglite.mdl"
SWEP.HoldType = "slam"
SWEP.DefaultHoldType = "slam"
SWEP.Offset = {
	Pos = {
		Up = -0.5,
		Right = 2,
		Forward = 5.5,
	},
	Ang = {
		Up = -1,
		Right = 5,
		Forward = 178
	},
	Scale = 1.2
}

SWEP.Primary.Sound = Sound("Weapon_Melee.CrowbarLight")
SWEP.Secondary.Sound = Sound("Weapon_Melee.CrowbarHeavy")

SWEP.MoveSpeed = 1.0
SWEP.IronSightsMoveSpeed  = SWEP.MoveSpeed

SWEP.InspectPos = Vector(8.418, 0, 15.241)
SWEP.InspectAng = Vector(-9.146, 9.145, 17.709)

SWEP.Primary.Blunt = true
SWEP.Primary.Damage = 25
SWEP.Primary.Reach = 40
SWEP.Primary.RPM = 90
SWEP.Primary.SoundDelay = 0
SWEP.Primary.Delay = 0.3
SWEP.Primary.Window = 0.2
SWEP.Primary.Automatic = false

SWEP.Secondary.Blunt = true
SWEP.Secondary.RPM = 60
SWEP.Secondary.Damage = 60
SWEP.Secondary.Reach = 40
SWEP.Secondary.SoundDelay = 0.0
SWEP.Secondary.Delay = 0.2
SWEP.Secondary.Automatic = false

SWEP.Secondary.BashDamage = 50
SWEP.Secondary.BashDelay = 0.35
SWEP.Secondary.BashLength = 40

SWEP.MoveSpeed = 1
SWEP.AllowViewAttachment = false

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVER SIDE
-- PrimaryAttack only: toggles a networked boolean. No light entity management.
-- ─────────────────────────────────────────────────────────────────────────────
function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if !IsValid(self) || !IsValid(self.Owner) then return end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	
	if SERVER then
		self.Owner:EmitSound("slashers/effects/flashlight_toggle.wav", 75, 100, 0.6)
		self:SetNWBool("LightActive", not self:GetNWBool("LightActive"))
	end
end

function SWEP:SecondaryAttack()
	self:AltAttack()
end

function SWEP:Reload()
end

function SWEP:PrimarySlash()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LIFECYCLE CLEANUP (SERVER)
-- Nothing to clean up — client manages its own ProjectedTexture.
-- We still null the NWBool to be safe and clean.
-- ─────────────────────────────────────────────────────────────────────────────
function SWEP:Holster()
	if SERVER then
		print("[Maglite-Debug] Holster triggered — clearing LightActive NWBool")
	end
	self:SetNWBool("LightActive", false)
	return true
end

function SWEP:OnRemove()
	if SERVER then
		print("[Maglite-Debug] OnRemove triggered — clearing LightActive NWBool")
	end
	self:SetNWBool("LightActive", false)
end

function SWEP:OnDrop()
	if SERVER then
		print("[Maglite-Debug] OnDrop triggered — clearing LightActive NWBool")
	end
	self:SetNWBool("LightActive", false)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CLIENT SIDE
-- ProjectedTexture is a pure client object. It survives render.RedownloadAllLightmaps
-- because it is continuously rebuilt each frame by the client itself — no server
-- entity is involved. We use a GLOBAL Think hook (not SWEP:Think) so that
-- third-person observers of a player holding the Maglite can also see the beam.
-- ─────────────────────────────────────────────────────────────────────────────
if CLIENT then

	local Flashlights = {}

	----------------------------------------------------------------------
	-- Global Think hook: manages ProjectedTexture for ALL players.
	-- SWEP:Think() is intentionally left empty.
	----------------------------------------------------------------------
	hook.Add("Think", "sls_flashlight_global_render", function()
		for _, ply in ipairs(player.GetAll()) do
			local wep = ply:GetActiveWeapon()
			local isMaglite = IsValid(wep) and wep:GetClass() == "weapon_flashlight"
			local active = isMaglite and wep:GetNWBool("LightActive", false)

			if active then
				local isLocal = ply == LocalPlayer()
				local inFirstPerson = isLocal and not ply:ShouldDrawLocalPlayer()

				local pos, ang

				if inFirstPerson then
					-- First-person: attach to the viewmodel's "light" attachment so the
					-- beam originates from the gun barrel, not the camera.
					local vm = ply:GetViewModel()
					local attID = vm:LookupAttachment("light")
					local att = vm:GetAttachment(attID)
					if att then
						pos = att.Pos
						ang = att.Ang
					else
						pos = EyePos()
						ang = EyeAngles()
					end
				else
					-- Third-person: emit from the hand attachment, pushed slightly forward.
					local att = ply:GetAttachment(ply:LookupAttachment("anim_attachment_RH"))
					if att then
						pos = att.Pos + ply:GetAimVector() * 15
					else
						pos = ply:EyePos() + ply:GetAimVector() * 15
					end
					ang = ply:EyeAngles()
				end

				if not IsValid(Flashlights[ply]) then
					print("[Maglite-Debug] GlobalThink — creating ProjectedTexture for " .. ply:Nick())
					Flashlights[ply] = ProjectedTexture()
					Flashlights[ply]:SetTexture("effects/flashlight001")
					Flashlights[ply]:SetFarZ(1477)
					Flashlights[ply]:SetFOV(60)
					Flashlights[ply]:SetColor(Color(150, 255, 255, 255))
					Flashlights[ply]:SetEnableShadows(true)
				end

				Flashlights[ply]:SetPos(pos)
				Flashlights[ply]:SetAngles(ang)
				Flashlights[ply]:Update()
			else
				if IsValid(Flashlights[ply]) then
					print("[Maglite-Debug] GlobalThink — removing ProjectedTexture for " .. ply:Nick())
					Flashlights[ply]:Remove()
					Flashlights[ply] = nil
				end
			end
		end
	end)

	----------------------------------------------------------------------
	-- Garbage collection: clean up if a player disconnects with an active light.
	----------------------------------------------------------------------
	hook.Add("EntityRemoved", "sls_flashlight_cleanup", function(ent)
		if not ent:IsPlayer() then return end
		if IsValid(Flashlights[ent]) then
			Flashlights[ent]:Remove()
			Flashlights[ent] = nil
		end
	end)

end
