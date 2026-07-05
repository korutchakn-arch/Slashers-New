SWEP.Base = "tfa_nmrimelee_base"
SWEP.Category = "TFA NMRIH"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.PrintName = "Maglite"

SWEP.ViewModel            = "models/weapons/tfa_nmrih/v_item_maglite.mdl"
SWEP.ViewModelFOV = 50

SWEP.WorldModel           = "models/weapons/tfa_nmrih/w_item_maglite.mdl"
SWEP.HoldType = "slam"
SWEP.DefaultHoldType = "slam"
SWEP.Offset = {
    Pos = {
        Up    = -0.5,
        Right = 2,
        Forward = 5.5,
    },
    Ang = {
        Up    = -1,
        Right = 5,
        Forward = 178,
    },
    Scale = 1.2,
}

SWEP.Primary.Sound       = Sound("Weapon_Melee.CrowbarLight")
SWEP.Secondary.Sound     = Sound("Weapon_Melee.CrowbarHeavy")

SWEP.MoveSpeed           = 1.0
SWEP.IronSightsMoveSpeed = SWEP.MoveSpeed

SWEP.InspectPos = Vector(8.418, 0, 15.241)
SWEP.InspectAng = Vector(-9.146, 9.145, 17.709)

SWEP.Primary.Blunt       = true
SWEP.Primary.Damage      = 25
SWEP.Primary.Reach       = 40
SWEP.Primary.RPM         = 90
SWEP.Primary.SoundDelay  = 0
SWEP.Primary.Delay       = 0.3
SWEP.Primary.Window      = 0.2
SWEP.Primary.Automatic   = false

SWEP.Secondary.Blunt          = true
SWEP.Secondary.RPM            = 60
SWEP.Secondary.Damage         = 60
SWEP.Secondary.Reach          = 40
SWEP.Secondary.SoundDelay     = 0.0
SWEP.Secondary.Delay          = 0.2
SWEP.Secondary.Automatic      = false

SWEP.Secondary.BashDamage = 50
SWEP.Secondary.BashDelay  = 0.35
SWEP.Secondary.BashLength = 40

SWEP.AllowViewAttachment = false

------------------------------------------------------------
-- PrimaryAttack: toggle GMod's native flashlight system.
-- The engine handles positioning, shadows, and visibility
-- automatically — no env_projectedtexture management needed.
------------------------------------------------------------
function SWEP:PrimaryAttack()
    if not IsValid(self) or not IsValid(self.Owner) then return end
    if not self.Owner:AllowFlashlight() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local isOn = self.Owner:FlashlightIsOn()
    self.Owner:Flashlight(not isOn)
end

function SWEP:SecondaryAttack()
    self:AltAttack()
end

function SWEP:Reload()
    -- no-op
end

function SWEP:PrimarySlash()
    -- no-op
end

------------------------------------------------------------
-- Holster: ensure flashlight is off when weapon is put away.
------------------------------------------------------------
function SWEP:Holster()
    if IsValid(self.Owner) and self.Owner:FlashlightIsOn() then
        self.Owner:Flashlight(false)
    end
    return true
end

function SWEP:OnDrop()
    if IsValid(self.Owner) and self.Owner:FlashlightIsOn() then
        self.Owner:Flashlight(false)
    end
end
