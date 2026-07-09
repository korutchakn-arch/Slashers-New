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
SWEP.Slot            = 1    -- HUD Slot 2 (0-indexed); keeps the phone out of the primary weapon slot

SWEP.PrintName       = "Phone"
SWEP.Author          = "Slashers Dev"

-- Crowbar is used as the dummy base — it has full TFA animation sequences
-- (idle, draw, holster) so the animation parser never crashes.
-- It is completely hidden at runtime (see ShowViewModel + PreDrawViewModel below).
SWEP.ViewModel       = "models/weapons/c_crowbar.mdl"
SWEP.ViewModelFOV    = 70
SWEP.WorldModel      = "models/weapons/w_crowbar.mdl"

SWEP.HoldType        = "slam"
SWEP.DefaultHoldType = "slam"

-- Show the viewmodel so player hands render — the crowbar mesh is hidden
-- separately in PreDrawViewModel via Debug/hsv material override.
SWEP.ShowViewModel   = true
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
		pos              = Vector(-9.87, 3.635, -6.753),
		angle            = Angle(-8.183, -127.403, 169.481),
		size             = Vector(0.5, 0.5, 0.5),
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Phone Ability Constants
-- ─────────────────────────────────────────────────────────────────────────────
local PHONE_ABILITY_COOLDOWN    = 20   -- seconds between uses
local PHONE_WEAPON_DURATION     = 7    -- seconds the survivor holds the phone (6 s sound + 1 s margin)
local PHONE_ABILITY_SOUND       = "buttons/button14.wav"  -- played to Ghostface on success
local PHONE_RINGING_SOUND       = "ghostface_player_sound/ScaryMovie project.wav" -- played to the called survivor

-- ─────────────────────────────────────────────────────────────────────────────
-- PrimaryAttack — Ghostface Phone Ability
--
-- On left-click (SERVER side only):
--   1. Cooldown gate — prevents spam.
--   2. Iterates GM.ROUND:GetSurvivorsAlive() to find the furthest alive
--      survivor from Ghostface (O(n) single pass, no heavy per-tick work).
--   3. Gives that survivor a temporary instance of this phone SWEP.
--   4. Sends the survivor's position to Ghostface via sls_ghostface_phone_reveal
--      (mirrors Myers' sls_kability_Wallhack pattern with a dedicated net string
--      to avoid colliding with Myers' client-side HUD handler).
-- ─────────────────────────────────────────────────────────────────────────────
function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Owner) then return end

	-- Always advance fire timer so the SWEP click doesn't feel broken on client
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not SERVER then return end

	local killer = self.Owner
	if killer:Team() ~= TEAM_KILLER then return end

	-- ── 1. Cooldown gate ──────────────────────────────────────────────────────
	local lastUse = self._phoneAbilityLastUse or 0
	if CurTime() - lastUse < PHONE_ABILITY_COOLDOWN then
		local remaining = math.ceil(PHONE_ABILITY_COOLDOWN - (CurTime() - lastUse))
		net.Start("notificationSlasher")
			net.WriteTable({"killerhelp_cant_use_ability"})
			net.WriteString("cross")
		net.Send(killer)
		killer:ChatPrint("[Phone] Ability on cooldown — " .. remaining .. "s remaining.")
		return
	end

	-- ── 2. Round sanity check ─────────────────────────────────────────────────
	local GM = GM or GAMEMODE
	if not GM.ROUND or not GM.ROUND.Active then
		killer:ChatPrint("[Phone] No active round.")
		return
	end

	-- ── 3. Find the furthest alive survivor from Ghostface ────────────────────
	-- Cache killer position — called once, not per-player per-tick.
	local killerPos    = killer:GetPos()
	local furthestSurv = nil
	local furthestDist = -1

	local survivors = GM.ROUND:GetSurvivorsAlive()
	for _, surv in ipairs(survivors) do
		if IsValid(surv) and surv:Alive() and surv ~= killer then
			local dist = killerPos:DistToSqr(surv:GetPos()) -- DistToSqr: cheaper than Distance (no sqrt)
			if dist > furthestDist then
				furthestDist = dist
				furthestSurv = surv
			end
		end
	end

	if not IsValid(furthestSurv) then
		killer:ChatPrint("[Phone] No survivors found.")
		return
	end

	-- ── 4. Stamp cooldown now that we have a valid target ─────────────────────
	self._phoneAbilityLastUse = CurTime()

	-- ── 5. Give the survivor the phone SWEP (server-only) ────────────────────
	-- Strip any previous leftover copy to avoid stacking.
	furthestSurv:StripWeapon("weapon_ghostface_phone")
	furthestSurv:Give("weapon_ghostface_phone")
	
	local phoneWep = furthestSurv:GetWeapon("weapon_ghostface_phone")
	if IsValid(phoneWep) then
		furthestSurv:SetActiveWeapon(phoneWep)
	end
	
	furthestSurv:EmitSound(PHONE_RINGING_SOUND, 75, 100, 1.0)
	furthestSurv:ChatPrint("Your phone is ringing... Pick up!")

	-- Auto-strip the phone after PHONE_WEAPON_DURATION seconds
	local survRef = furthestSurv -- upvalue capture for the timer closure
	timer.Simple(PHONE_WEAPON_DURATION, function()
		if IsValid(survRef) then
			survRef:StripWeapon("weapon_ghostface_phone")
			survRef:StopSound(PHONE_RINGING_SOUND)
		end
	end)

	-- ── 6. Reveal the survivor's position to Ghostface ───────────────────────
	-- Mirrors Myers' sls_kability_Wallhack pattern but uses a dedicated net
	-- string so Myers' client HUD handler is not triggered for Ghostface.
	local revealPos = furthestSurv:GetPos() + Vector(0, 0, 50) -- offset to head-level (same as Myers)
	net.Start("sls_ghostface_phone_reveal")
		net.WriteVector(revealPos)
		net.WriteString(furthestSurv:Nick())
	net.Send(killer)

	-- ── 7. Ghostface feedback ─────────────────────────────────────────────────
	killer:EmitSound(PHONE_ABILITY_SOUND, 75, 100, 1.0)
	killer:ChatPrint("[Phone] Called " .. furthestSurv:Nick() .. " — tracking their position!")
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
	if IsValid(self.Owner) and self.Owner:Team() ~= TEAM_KILLER then
		return false -- Survivors cannot switch away from the phone!
	end

	if SERVER and IsValid(self.Owner) then
		self.Owner:StopSound(PHONE_RINGING_SOUND)
	end
	return true
end

function SWEP:OnRemove()
	if SERVER and IsValid(self.Owner) then
		self.Owner:StopSound(PHONE_RINGING_SOUND)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Client-side rendering overrides
-- ─────────────────────────────────────────────────────────────────────────────
if CLIENT then
	-- Let TFA base natively handle VElements rendering.

	-- Apply an invisible material to the crowbar mesh every frame so it stays invisible,
	-- but do NOT return true — returning true would suppress ViewModelDrawn,
	-- which is the hook TFA uses to render VElements.
	function SWEP:PreDrawViewModel(vm, wep, ply)
		if IsValid(vm) then
			vm:SetMaterial("engine/occlusionproxy")
			vm:SetColor(Color(255, 255, 255, 0))
			vm:SetRenderMode(RENDERMODE_TRANSALPHA)
		end
		-- No return value — lets the engine proceed so ViewModelDrawn fires.
	end

	-- Reset the material immediately after the weapon draws, 
	-- so the player's c_hands (which draw right after) don't turn invisible!
	function SWEP:PostDrawViewModel(vm, wep, ply)
		if IsValid(vm) then
			vm:SetMaterial("")
			vm:SetColor(Color(255, 255, 255, 255))
			vm:SetRenderMode(RENDERMODE_NORMAL)
		end
	end

	-- TFA requires calling the base method here to render WElements.
	function SWEP:DrawWorldModel()
		if self.BaseClass and self.BaseClass.DrawWorldModel then
			self.BaseClass.DrawWorldModel(self)
		end
	end
end
