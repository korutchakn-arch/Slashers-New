SWEP.Base = "tfa_nmrimelee_base"
SWEP.Category = "TFA NMRIH"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.PrintName = "Washing Machine"

-- Invisible base models (the washing machine prop replaces them via VElements/WElements)
SWEP.ViewModel = "models/weapons/tfa_nmrih/v_me_machete.mdl"
SWEP.ViewModelFOV = 50

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_machete.mdl"
SWEP.HoldType = "melee"
SWEP.DefaultHoldType = "melee"

-- World model offset (only matters for the invisible fallback model)
SWEP.Offset = {
	Pos = {
		Up = -10,
		Right = 2,
		Forward = 4,
	},
	Ang = {
		Up = -1,
		Right = 5,
		Forward = 178
	},
	Scale = 1.0
}

-- Sound on flesh hit — blunt, heavy
SWEP.Primary.Sound = Sound("Weapon_Melee_Blunt.Impact_Heavy")
SWEP.Secondary.Sound = Sound("Weapon_Melee_Blunt.Impact_Heavy")

-- Hot-reload safety: TFA base generates these in Initialize() if absent,
-- but they may be nil on live reinit — hardcode fallbacks here.
SWEP.FireModes                          = { "Single" }
SWEP.Primary.SpreadRecovery             = 0
SWEP.Primary.SpreadMultiplierMax        = 1
SWEP.Primary.SpreadIncrement            = 1
SWEP.Primary.Spread                     = 0.01
SWEP.Primary.Accuracy                   = 0.01

SWEP.MoveSpeed = 0.7
SWEP.IronSightsMoveSpeed = SWEP.MoveSpeed

SWEP.InspectPos = Vector(15.069, -7.437, 10.85)
SWEP.InspectAng = Vector(26.03, 43.618, 54.874)

-- Very slow, very damaging
SWEP.Primary.Reach = 120
SWEP.Primary.RPM = 30
SWEP.Primary.Damage = 150
SWEP.Primary.SoundDelay = 0.0
SWEP.Primary.Delay = 0.2

SWEP.Secondary.RPM = 20
SWEP.Secondary.Damage = 200
SWEP.Secondary.Reach = 80
SWEP.Secondary.SoundDelay = 0.0
SWEP.Secondary.Delay = 0.3

SWEP.Secondary.BashDamage = 80
SWEP.Secondary.BashDelay = 0.5
SWEP.Secondary.BashLength = 70

-- View model bone mods to make the hand grip look right
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_R_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0.254, 0.09), angle = Angle(15.968, -11.193, 1.437) },
	["ValveBiped.Bip01_R_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(3.552, 4.526, 0) },
	["Thumb04"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(6, 0, 0) },
	["Middle04"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-8.212, 1.121, 1.263) },
	["Pinky05"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(11.793, 4.677, 11.218) }
}

-- View elements — transparent base viewmodel + washing machine prop
SWEP.VElements = {
	["base"] = {
		type = "Model",
		model = SWEP.ViewModel,
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(2.5, 0, -2),
		angle = Angle(0, 0, 0),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 0),
		surpresslights = true,
		material = "",
		skin = 0,
		bonemerge = false,
		active = false
	},
	["washingmachine"] = {
		type = "Model",
		model = "models/props_wasteland/laundry_washer003.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(3, -1.5, -5),
		angle = Angle(-90, 0, 0),
		size = Vector(0.3, 0.3, 0.3),
		color = Color(255, 255, 255, 255),
		surpresslights = true,
		material = "",
		skin = 0,
		bonemerge = false,
		active = true
	}
}

-- World elements — transparent base worldmodel + washing machine prop
SWEP.WElements = {
	["base"] = {
		type = "Model",
		model = SWEP.WorldModel,
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(2.5, 0, -2),
		angle = Angle(0, 0, 0),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 0),
		surpresslights = true,
		material = "",
		skin = 0,
		bonemerge = false,
		active = false
	},
	["washingmachine"] = {
		type = "Model",
		model = "models/props_wasteland/laundry_washer003.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(3, -1.5, -5),
		angle = Angle(-90, 0, 0),
		size = Vector(0.3, 0.3, 0.3),
		color = Color(255, 255, 255, 255),
		surpresslights = true,
		material = "",
		skin = 0,
		bonemerge = false,
		active = true
	}
}

-- Hide the invisible base view/world models on client
if CLIENT then
	local oldInitialize = SWEP.Initialize
	function SWEP:Initialize()
		if oldInitialize then oldInitialize(self) end
		timer.Simple(0, function()
			if not IsValid(self) then return end
			local vm = self.Owner and self.Owner:GetViewModel()
			if IsValid(vm) then
				vm:SetColor(Color(255, 255, 255, 0))
			end
		end)
	end

	-- Suppress the base world model from rendering
	function SWEP:DrawWorldModel()
		-- Intentionally empty — the WElements handle the prop rendering
	end
end
