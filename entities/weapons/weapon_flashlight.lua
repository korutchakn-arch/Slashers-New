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
-- entity is involved.
-- ─────────────────────────────────────────────────────────────────────────────
if CLIENT then

	-- Forward-declare so Think can reference it
	local matLight = Material("sprites/light_ignorez")

	-- Draw a sprite at the flashlight origin so the player can see it in-world
	-- even when looking away from the beam direction.
	local function DrawFlashlightSprite(pos)
		if not pos then return end
		render.SetMaterial(matLight)
		local viewNormal = (EyePos() - pos)
		local dist = viewNormal:Length()
		if dist < 4 then return end
		viewNormal:Normalize()
		local dot = viewNormal:Dot(EyeAngles():Forward())
		if dot < 0 then return end
		local size = math.Clamp(dist * dot * 0.4, 8, 128)
		local alpha = math.Clamp((800 - dist) * dot, 0, 180)
		render.DrawSprite(pos, size, size, Color(150, 255, 255, alpha))
	end

	function SWEP:Think()
		-- ─── Cleanup ──────────────────────────────────────────────────────────────
		-- IsValid(self) covers weapon holster and removal.
		-- self:GetNWBool("LightActive") being false covers server-side drop/holster events.
		if not IsValid(self) then
			if self.ClientLight then
				self.ClientLight:Remove()
				self.ClientLight = nil
			end
			return
		end

		if not self:GetNWBool("LightActive", false) then
			if self.ClientLight then
				print("[Maglite-Debug] Think — removing ProjectedTexture (light deactivated)")
				self.ClientLight:Remove()
				self.ClientLight = nil
			end
			return
		end

		-- ─── Create or update ───────────────────────────────────────────────────────
		if not self.ClientLight then
			print("[Maglite-Debug] Think — creating ProjectedTexture")
			self.ClientLight = ProjectedTexture()
			self.ClientLight:SetTexture("effects/flashlight001")
			self.ClientLight:SetFarZ(1477)
			self.ClientLight:SetFOV(60)
			self.ClientLight:SetColor(Color(150, 255, 255, 255))
			self.ClientLight:SetEnableShadows(true)
		end

		local pos = EyePos()
		local ang = EyeAngles()

		self.ClientLight:SetPos(pos)
		self.ClientLight:SetAngles(ang)
		self.ClientLight:Update()

		DrawFlashlightSprite(pos + ang:Forward() * 2)
	end

end
