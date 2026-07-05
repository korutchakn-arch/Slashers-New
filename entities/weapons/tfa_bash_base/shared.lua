DEFINE_BASECLASS("tfa_gun_base")

-- Safe stub overrides to prevent nil-value crashes from missing base methods
-- Stateful stub overrides for missing Get* methods
if not SWEP.GetInspecting then SWEP.GetInspecting = function(self) return self._bInspecting or false end end
if not SWEP.GetRunSightsRatio then SWEP.GetRunSightsRatio = function(self) return self._nRunSightsRatio or 0 end end
if not SWEP.GetIronSights then SWEP.GetIronSights = function(self) return self._bIronSights or false end end
if not SWEP.GetNearWallRatio then SWEP.GetNearWallRatio = function(self) return self._nNearWallRatio or 0 end end
if not SWEP.GetDrawing then SWEP.GetDrawing = function(self) return self._bDrawing or false end end
if not SWEP.GetHolstering then SWEP.GetHolstering = function(self) return self._bHolstering or false end end
if not SWEP.GetReloading then SWEP.GetReloading = function(self) return self._bReloading or false end end
if not SWEP.GetBashing then SWEP.GetBashing = function(self) return self._bBashing or false end end
if not SWEP.GetShooting then SWEP.GetShooting = function(self) return self._bShooting or false end end
if not SWEP.GetSprinting then SWEP.GetSprinting = function(self) return self._bSprinting or false end end

-- Stateful stub overrides for missing Set* methods
if not SWEP.SetShooting then SWEP.SetShooting = function(self, val) self._bShooting = val end end
if not SWEP.SetShootingEnd then SWEP.SetShootingEnd = function(self, val) self._bShootingEnd = val end end
if not SWEP.SetInspecting then SWEP.SetInspecting = function(self, val) self._bInspecting = val end end
if not SWEP.SetInspectingRatio then SWEP.SetInspectingRatio = function(self, val) self._nInspectingRatio = val end end
if not SWEP.SetHolstering then SWEP.SetHolstering = function(self, val) self._bHolstering = val end end
if not SWEP.SetHolsteringEnd then SWEP.SetHolsteringEnd = function(self, val) self._bHolsteringEnd = val end end
if not SWEP.SetSpreadRatio then SWEP.SetSpreadRatio = function(self, val) self._nSpreadRatio = val end end
if not SWEP.SetBursting then SWEP.SetBursting = function(self, val) self._bBursting = val end end
if not SWEP.SetNextIdleAnim then SWEP.SetNextIdleAnim = function(self, val) self._nNextIdleAnim = val end end
if not SWEP.GetChangingSilence then SWEP.GetChangingSilence = function(self) return false end end
if not SWEP.SetChangingSilence then SWEP.SetChangingSilence = function(self, val) end end

SWEP.Secondary.BashDamage = 25
SWEP.Secondary.BashSound = Sound("TFA.Bash")
SWEP.Secondary.BashHitSound = Sound("TFA.BashWall")
SWEP.Secondary.BashHitSound_Flesh = Sound("TFA.BashFlesh")
SWEP.Secondary.BashLength = 54
SWEP.Secondary.BashDelay = 0.2
SWEP.Secondary.BashDamageType = DMG_SLASH

SWEP.BashBase = true

local lastresortanim = -2

--SWEP.tmptoggle = true

function SWEP:AltAttack()
	if !self:OwnerIsValid() then return end

	if ( self:GetHolstering() ) then
		if (self.ShootWhileHolster==false) then
			return
		else
			self:SetHolsteringEnd(CurTime()-0.1)
			self:SetHolstering(false)
		end
	end

	if (self:GetReloading() and self.Shotgun and !self:GetShotgunPumping() and !self:GetShotgunNeedsPump()) then
		self:SetShotgunCancel( true )
		--[[
		self:SetShotgunInsertingShell(true)
		self:SetShotgunPumping(false)
		self:SetShotgunNeedsPump(true)
		self:SetReloadingEnd(CurTime()-1)
		]]--
		return
	end

	if self:IsSafety() then return end

	if (self:GetChangingSilence()) then return end

	if self:GetNextSecondaryFire()>CurTime() then return end

	if self:GetReloading() then
		self:CompleteReload()
	end

	local vm = self.Owner:GetViewModel()

	--if SERVER then
		self:SendWeaponAnim(ACT_VM_HITCENTER)
	--else
		self:SendWeaponAnim(ACT_VM_HITCENTER)
	--end


	if !game.SinglePlayer() then
		timer.Simple(vm:SequenceDuration()-0.05,function()
			if IsValid(self) and self:OwnerIsValid() then
				self:SendWeaponAnim(ACT_VM_IDLE)
			end
		end)

		timer.Simple(vm:SequenceDuration()-0.01,function()
			if IsValid(self) and self:OwnerIsValid() then
				if lastresortanim and lastresortanim>-2 then
					self:SendWeaponAnim(lastresortanim)
				end
			end
		end)
	end

	self.tmptoggle = !self.tmptoggle

	self:SetNextPrimaryFire(CurTime()+(self.SequenceLengthOverride[ACT_VM_HITCENTER] or vm:SequenceDuration()))
	self:SetNextSecondaryFire(CurTime()+(self.SequenceLengthOverride[ACT_VM_HITCENTER] or vm:SequenceDuration()))

	if CLIENT then
		self:EmitSound(self.Secondary.BashSound )
	end

	timer.Simple(self.Secondary.BashDelay,function()
		if IsValid(self) and self.OwnerIsValid and self:OwnerIsValid() then
			if (SERVER) then
				local pos = self.Owner:GetShootPos()
				local av = self.Owner:EyeAngles():Forward()

				local slash = {}
				slash.start = pos
				slash.endpos = pos + (av * self.Secondary.BashLength)
				slash.filter = self.Owner
				slash.mins = Vector(-10, -5, 0)
				slash.maxs = Vector(10, 5, 5)
				local slashtrace = util.TraceHull(slash)
				local pain = self.Secondary.BashDamage



				if slashtrace.Hit then
					/*if slashtrace.Entity:GetClass() == "func_door_rotating" or slashtrace.Entity:GetClass() == "prop_door_rotating" then
						local ply = self.Owner
						ply:EmitSound("ambient/materials/door_hit1.wav", 100, math.random(80, 120))

						ply.oldname = ply:GetName()

						ply:SetName( "bashingpl" .. ply:EntIndex() )

						slashtrace.Entity:SetKeyValue( "Speed", "500" )
						slashtrace.Entity:SetKeyValue( "Open Direction", "Both directions" )
						slashtrace.Entity:SetKeyValue( "opendir", "0" )
						slashtrace.Entity:Fire( "unlock", "", .01 )
						slashtrace.Entity:Fire( "openawayfrom", "bashingpl" .. ply:EntIndex() , .01 )

						timer.Simple(0.02, function()
							if IsValid(ply) then
								ply:SetName(ply.oldname)
							end
						end)

						timer.Simple(0.3, function()
							if IsValid(slashtrace.Entity) then
								slashtrace.Entity:SetKeyValue( "Speed", "100" )
							end
						end)

					end*/
					self:EmitSound( (slashtrace.MatType == MAT_FLESH or slashtrace.MatType == MAT_ALIENFLESH) and self.Secondary.BashHitSound_Flesh or self.Secondary.BashHitSound  )
					if game.GetTimeScale()>0.99 then
						self.Owner:FireBullets({
							Attacker = self.Owner,
							Inflictor = self,
							Damage = pain,
							Force = pain,
							Distance = self.Secondary.BashLength + 10,
							HullSize = 10,
							Tracer = 0,
							Src = self.Owner:GetShootPos(),
							Dir = slashtrace.Normal,
							Callback = function(a,b,c)
								if c then c:SetDamageType(self.Secondary.BashDamageType) end
							end
						})
					else
						local dmg = DamageInfo()
						dmg:SetAttacker(self.Owner)
						dmg:SetInflictor(self)
						dmg:SetDamagePosition(self.Owner:GetShootPos())
						dmg:SetDamageForce(self.Owner:GetAimVector()*(pain))
						dmg:SetDamage(pain)
						dmg:SetDamageType(self.Secondary.BashDamageType)
						slashtrace.Entity:TakeDamageInfo(dmg)
					end

					local ent = slashtrace.Entity
					if IsValid(ent) and ent.GetPhysicsObject then

						local phys

						if ent:IsRagdoll() then
							phys = ent:GetPhysicsObjectNum(slashtrace.PhysicsBone or 0)
						else
							phys = ent:GetPhysicsObject()
						end

						if IsValid(phys) then
							if ent:IsPlayer() or ent:IsNPC() then
								ent:SetVelocity(ent:GetVelocity()+self.Owner:GetAimVector()*self.Secondary.BashDamage)
								phys:SetVelocity(phys:GetVelocity()+self.Owner:GetAimVector()*self.Secondary.BashDamage)
							else
								phys:ApplyForceOffset(self.Owner:GetAimVector()*self.Secondary.BashDamage/4,slashtrace.HitPos)
							end
						end

					end
				end
			end
		end
	end)
end

function SWEP:GetBashing()
	if !self:OwnerIsValid() then return false end
	local bash,vm,seq,actid

	vm = self.Owner:GetViewModel()
	if !IsValid(vm) then return end
	seq = vm:GetSequence()
	actid = vm:GetSequenceActivity(seq)
	bash = (actid==ACT_VM_HITCENTER) and vm:GetCycle()>0 and vm:GetCycle()<0.65
	return bash
end
