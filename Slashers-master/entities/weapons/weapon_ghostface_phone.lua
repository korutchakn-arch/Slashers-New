-- Utopia Games - Slashers
-- Ghostface Phone SWEP
-- A static-prop phone weapon attached to the right hand via VElements/WElements.
-- No rigged viewmodel — the base crowbar is hidden and the phone prop is
-- rendered in-place through TFA's bone-attachment (SWEP Construction Kit) system.

-- ─────────────────────────────────────────────────────────────────────────────
-- TFA base safe-stubs (prevents nil-value crashes if base methods are absent)
-- ─────────────────────────────────────────────────────────────────────────────
if not SWEP.GetHolstering      then SWEP.GetHolstering      = function(self) return self._bHolstering     or false end end
if not SWEP.GetDrawing         then SWEP.GetDrawing         = function(self) return self._bDrawing         or false end end
if not SWEP.GetReloading       then SWEP.GetReloading       = function(self) return self._bReloading       or false end end
if not SWEP.GetBashing         then SWEP.GetBashing         = function(self) return self._bBashing         or false end end
if not SWEP.GetShooting        then SWEP.GetShooting        = function(self) return self._bShooting        or false end end
if not SWEP.GetSprinting       then SWEP.GetSprinting       = function(self) return self._bSprinting       or false end end
if not SWEP.GetInspecting      then SWEP.GetInspecting      = function(self) return self._bInspecting      or false end end
if not SWEP.GetIronSights      then SWEP.GetIronSights      = function(self) return self._bIronSights      or false end end
if not SWEP.GetRunSightsRatio  then SWEP.GetRunSightsRatio  = function(self) return self._nRunSightsRatio  or 0     end end
if not SWEP.GetNearWallRatio   then SWEP.GetNearWallRatio   = function(self) return self._nNearWallRatio   or 0     end end
if not SWEP.SetShooting        then SWEP.SetShooting        = function(self, v) self._bShooting     = v end end
if not SWEP.SetShootingEnd     then SWEP.SetShootingEnd     = function(self, v) self._bShootingEnd  = v end end
if not SWEP.SetHolstering      then SWEP.SetHolstering      = function(self, v) self._bHolstering   = v end end
if not SWEP.SetHolsteringEnd   then SWEP.SetHolsteringEnd   = function(self, v) self._bHolsteringEnd = v end end
if not SWEP.SetInspecting      then SWEP.SetInspecting      = function(self, v) self._bInspecting   = v end end
if not SWEP.GetChangingSilence then SWEP.GetChangingSilence = function(self) return false end end
if not SWEP.SetChangingSilence then SWEP.SetChangingSilence = function(self, v) end end

-- ─────────────────────────────────────────────────────────────────────────────
-- SWEP Definition
-- ─────────────────────────────────────────────────────────────────────────────
SWEP.Base            = "tfa_nmrimelee_base"
SWEP.Category        = "TFA NMRIH"
SWEP.Spawnable       = false
SWEP.AdminSpawnable  = true

SWEP.PrintName       = "Phone"
SWEP.Author          = "Slashers Dev"

-- Crowbar is used as the dummy base — it has full TFA animation sequences
-- (idle, draw, holster) so the animation parser never crashes.
-- It is completely hidden at runtime (see ShowViewModel + PreDrawViewModel below).
SWEP.ViewModel       = "models/weapons/c_crowbar.mdl"
SWEP.ViewModelFOV    = 50
SWEP.WorldModel      = "models/weapons/w_crowbar.mdl"

SWEP.HoldType        = "slam"
SWEP.DefaultHoldType = "slam"

-- Tells TFA's InitMods() to call vm:SetMaterial("Debug/hsv") — hides the crowbar mesh.
SWEP.ShowViewModel   = false
SWEP.ShowWorldModel  = false

-- Disable hands parenting in TFA's ViewModelDrawn() loop.
-- UseHands=true initialises the c_model skeleton with player hands;
-- TFA needs this so SCK can resolve ValveBiped.Bip01_R_Hand bone positions.
-- The hands are kept invisible via PreDrawViewModel (Debug/hsv material).
SWEP.UseHands        = true

-- World model offset (only affects the hidden fallback crowbar)
SWEP.Offset = {
	Pos = { Up = -0.5, Right = 2, Forward = 5.5 },
	Ang = { Up = -1,   Right = 5, Forward = 178  },
	Scale = 1.0
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Ammo / clip — mandatory for TFA arithmetic, even on melee/utility SWEPs
-- ─────────────────────────────────────────────────────────────────────────────
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo        = "none"

-- ─────────────────────────────────────────────────────────────────────────────
-- Combat stats
-- ─────────────────────────────────────────────────────────────────────────────
SWEP.Primary.Sound   = Sound("Weapon_Melee.CrowbarLight")
SWEP.Secondary.Sound = Sound("Weapon_Melee.CrowbarLight")

SWEP.MoveSpeed           = 1.0
SWEP.IronSightsMoveSpeed = SWEP.MoveSpeed

SWEP.InspectPos = Vector(0, 0, 0)
SWEP.InspectAng = Vector(0, 0, 0)

-- TFA spread safety
SWEP.FireModes                   = { "Single" }
SWEP.Primary.SpreadRecovery      = 0
SWEP.Primary.SpreadMultiplierMax = 1
SWEP.Primary.SpreadIncrement     = 1
SWEP.Primary.Spread              = 0.01
SWEP.Primary.Accuracy            = 0.01

SWEP.Primary.Reach     = 40
SWEP.Primary.RPM       = 60
SWEP.Primary.Damage    = 0   -- non-damaging utility SWEP
SWEP.Primary.SoundDelay = 0
SWEP.Primary.Delay     = 0.5
SWEP.Primary.Window    = 0.2
SWEP.Primary.Automatic = false
SWEP.Primary.Blunt     = true

SWEP.Secondary.Reach      = 40
SWEP.Secondary.RPM        = 60
SWEP.Secondary.Damage     = 0
SWEP.Secondary.SoundDelay = 0
SWEP.Secondary.Delay      = 0.5
SWEP.Secondary.Blunt      = true

SWEP.Secondary.BashDamage = 0
SWEP.Secondary.BashDelay  = 0.3
SWEP.Secondary.BashLength = 40

SWEP.AllowViewAttachment = false

-- ─────────────────────────────────────────────────────────────────────────────
-- VElements — phone prop, first-person, attached to right hand bone
-- NOTE: TFA's render key is "surpresslightning" (not "surpresslights")
-- ─────────────────────────────────────────────────────────────────────────────
SWEP.VElements = {
	["base"] = {
		type             = "Model",
		model            = "models/weapons/c_crowbar.mdl",
		bone             = "ValveBiped.Bip01_R_Hand",
		rel              = "",
		pos              = Vector(0, 0, 0),
		angle            = Angle(0, 0, 0),
		size             = Vector(1, 1, 1),
		color            = Color(255, 255, 255, 0),  -- fully transparent
		surpresslightning = false,
		material         = "Debug/hsv",              -- additional safety hide
		skin             = 0,
		bonemerge        = false,
		active           = false
	},
	["phone"] = {
		type             = "Model",
		model            = "models/weapons/slashers_phone.mdl",
		bone             = "ValveBiped.Bip01_R_Hand",
		rel              = "",
		pos              = Vector(3, -2, 4),   -- tweak in-game
		angle            = Angle(0, -90, -90), -- tweak in-game
		size             = Vector(0.2, 0.2, 0.2), -- Blender 1m→Source unit correction
		color            = Color(255, 255, 255, 255),
		surpresslightning = true,
		material         = "",
		skin             = 0,
		bonemerge        = false,
		active           = true
	}
}

-- ─────────────────────────────────────────────────────────────────────────────
-- WElements — phone prop, third-person, attached to right hand bone
-- ─────────────────────────────────────────────────────────────────────────────
SWEP.WElements = {
	["base"] = {
		type             = "Model",
		model            = "models/weapons/w_crowbar.mdl",
		bone             = "ValveBiped.Bip01_R_Hand",
		rel              = "",
		pos              = Vector(0, 0, 0),
		angle            = Angle(0, 0, 0),
		size             = Vector(1, 1, 1),
		color            = Color(255, 255, 255, 0),  -- fully transparent
		surpresslightning = false,
		material         = "Debug/hsv",
		skin             = 0,
		bonemerge        = false,
		active           = false
	},
	["phone"] = {
		type             = "Model",
		model            = "models/weapons/slashers_phone.mdl",
		bone             = "ValveBiped.Bip01_R_Hand",
		rel              = "",
		pos              = Vector(3, 0, 2),    -- tweak in-game
		angle            = Angle(0, -90, -90), -- tweak in-game
		size             = Vector(0.2, 0.2, 0.2), -- Blender 1m→Source unit correction
		color            = Color(255, 255, 255, 255),
		surpresslightning = true,
		material         = "",
		skin             = 0,
		bonemerge        = false,
		active           = true
	}
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Functions
-- ─────────────────────────────────────────────────────────────────────────────

-- Test ring — replace body with real ability trigger when ready.
function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Owner) then return end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	if SERVER then
		self.Owner:EmitSound("buttons/button14.wav", 75, 100, 1.0)
		self.Owner:ChatPrint("Ring ring!")
	end
end

function SWEP:SecondaryAttack()
	self:AltAttack()
end

function SWEP:Reload()
	-- intentionally empty
end

function SWEP:PrimarySlash()
	-- intentionally empty
end

function SWEP:Holster()
	return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Client-side rendering overrides
-- ─────────────────────────────────────────────────────────────────────────────
if CLIENT then
	-- Let TFA base natively handle ShowViewModel = false and VElements rendering.

	-- We can't leave DrawWorldModel empty, otherwise WElements never draw!
	-- TFA base requires calling the base method to render WElements.
	function SWEP:DrawWorldModel()
		if self.BaseClass and self.BaseClass.DrawWorldModel then
			self.BaseClass.DrawWorldModel(self)
		end
	end
end
