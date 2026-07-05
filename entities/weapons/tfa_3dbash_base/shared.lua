DEFINE_BASECLASS("tfa_bash_base")

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

SWEP.Secondary.ScopeZoom			= 1
SWEP.Secondary.UseACOG			= false	
SWEP.Secondary.UseMilDot			= false		
SWEP.Secondary.UseSVD			= false	
SWEP.Secondary.UseParabolic		= false	
SWEP.Secondary.UseElcan			= false
SWEP.Secondary.UseGreenDuplex		= false

SWEP.RTScopeFOV = 6

SWEP.Scoped				= false
SWEP.BoltAction		= false

SWEP.ScopeAngleTransforms = {
	--{"P",1} --Pitch, 1
	--{"Y",1} --Yaw, 1
	--{"R",1} --Roll, 1
}

SWEP.ScopeOverlayTransforms = { 0, 0 }

SWEP.ScopeOverlayTransformMultiplier = 0.8

SWEP.RTMaterialOverride = 1

SWEP.IronSightsSensitivity = 1

SWEP.ScopeShadow = nil
SWEP.ScopeReticule = nil
SWEP.ScopeDirt = nil

SWEP.ScopeReticule_CrossCol = false
SWEP.ScopeReticule_Scale = {1, 1}
--[[End of Tweakable Parameters]]--

SWEP.Scoped_3D				= true
SWEP.BoltAction_3D		= false

local scopecvar = GetConVar("cl_tfa_3dscope")
local scopeshadowcvar = GetConVar("cl_tfa_3dscope_overlay")

function SWEP:Do3DScope()
	if scopecvar then
		return scopecvar:GetBool()
	else
		if self:OwnerIsValid() and self.Owner.GetInfoNum then
			return self.Owner:GetInfoNum("cl_tfa_3dscope",1)==1
		else
			return true
		end
	end
end

function SWEP:Do3DScopeOverlay()
	if scopeshadowcvar then
		return scopeshadowcvar:GetBool()
	else
		return false
	end
end

function SWEP:UpdateScopeType()
	if self:Do3DScope() then
		self.Scoped = false
		self.Scoped_3D = true
		if !self.Secondary.ScopeZoom_Backup then
			self.Secondary.ScopeZoom_Backup = self.Secondary.ScopeZoom		
		end
		if self.BoltAction then 
			self.BoltAction_3D = true
			self.BoltAction = false
			self.DisableChambering = true
		end
		if self.Secondary.ScopeZoom and self.Secondary.ScopeZoom>0 then
			self.RTScopeFOV = 70/self.Secondary.ScopeZoom
			self.IronSightsSensitivity = 1/self.Secondary.ScopeZoom
			self.Secondary.ScopeZoom = nil
			self.Secondary.IronFOV_Backup = self.Secondary.IronFOV
			self.Secondary.IronFOV = 70
		end
	else
		self.Scoped = true
		self.Scoped_3D = false
		if self.Secondary.ScopeZoom_Backup then
			self.Secondary.ScopeZoom = self.Secondary.ScopeZoom_Backup
		else
			self.Secondary.ScopeZoom = 4
		end		
		if self.BoltAction_3D then 
			self.BoltAction = true
			self.BoltAction_3D = nil
		end
		self.Secondary.IronFOV = 70/self.Secondary.ScopeZoom	
		self.IronSightsSensitivity = 1
	end
	self.DefaultFOV = GetConVarNumber("fov_desired",90)
end

if !SWEP.Callback then
	SWEP.Callback = {}
end

SWEP.Callback.Initialize = function(self)
	self:UpdateScopeType()
	timer.Simple(0,function()
		if IsValid(self) then
			self:UpdateScopeType()
			if SERVER then
				self:CallOnClient("UpdateScopeType","")
			end
		end
	end)
end

SWEP.Callback.Deploy = function(self)
	if SERVER then self:CallOnClient("UpdateScopeType","") end
	self:UpdateScopeType()
	timer.Simple(0,function()
		if IsValid(self) then
			self:UpdateScopeType()
			if SERVER then
				self:CallOnClient("UpdateScopeType","")
			end
		end
	end)
end

local flipcv

local cd = {}

local crosscol = Color(255,255,255,255)

SWEP.RTOpaque = true

SWEP.RTCode = function( self, rt, scrw, scrh )
	
	if !self.myshadowmask then self.myshadowmask = surface.GetTextureID(self.ScopeShadow or "vgui/scope_shadowmask_test") end
	if !self.myreticule then self.myreticule = Material(self.ScopeReticule or "scope/gdcw_scopesightonly") end
	if !self.mydirt then self.mydirt = Material(self.ScopeDirt or "vgui/scope_dirt") end
	
	if !flipcv then flipcv=GetConVar("cl_tfa_viewmodel_flip") end

	local vm = self.Owner:GetViewModel()
	
	if !self.LastOwnerPos then self.LastOwnerPos = self.Owner:GetShootPos() end
	
	local owoff = self.Owner:GetShootPos() - self.LastOwnerPos
	
	self.LastOwnerPos = self.Owner:GetShootPos()
	
	
	local att = vm:GetAttachment(3)
	if !att then return end
	
	local pos = att.Pos - owoff
	
	local scrpos = pos:ToScreen()
	
	scrpos.x = scrpos.x - scrw/2 + self.ScopeOverlayTransforms[1]
	scrpos.y = scrpos.y - scrh/2 + self.ScopeOverlayTransforms[2]
	
	scrpos.x = math.Clamp(scrpos.x,-1024,1024)
	scrpos.y = math.Clamp(scrpos.y,-1024,1024)
	
	--scrpos.x = scrpos.x * ( 2 - self.CLIronSightsProgress*1 )
	--scrpos.y = scrpos.y * ( 2 - self.CLIronSightsProgress*1 )
	
	scrpos.x = scrpos.x * self.ScopeOverlayTransformMultiplier
	scrpos.y = scrpos.y * self.ScopeOverlayTransformMultiplier
	
	if !self.scrpos then self.scrpos = scrpos end
	
	self.scrpos.x = math.Approach( self.scrpos.x, scrpos.x, (scrpos.x-self.scrpos.x)*FrameTime()*10 )
	self.scrpos.y = math.Approach( self.scrpos.y, scrpos.y, (scrpos.y-self.scrpos.y)*FrameTime()*10 )
	
	scrpos = self.scrpos
	
	render.OverrideAlphaWriteEnable( true, true)
	surface.SetDrawColor(color_white)
	surface.DrawRect(-512,-512,1024,1024)
	render.OverrideAlphaWriteEnable( true, true)
	
	local ang = EyeAngles()
	
	local AngPos = self.Owner:GetViewModel():GetAttachment(3)
	
	if AngPos then
	
		ang = AngPos.Ang
		if flipcv:GetBool() then
			ang.y = -ang.y
		end
		
		for k,v in pairs(self.ScopeAngleTransforms) do
			if v[1] == "P" then
				ang:RotateAroundAxis(ang:Right(),v[2])				
			elseif v[1] == "Y" then
				ang:RotateAroundAxis(ang:Up(),v[2])			
			elseif v[1] == "R" then
				ang:RotateAroundAxis(ang:Forward(),v[2])		
			end
		end
	end
	
	cd.angles = ang
	cd.origin = self.Owner:GetShootPos()
	
	if !self.RTScopeOffset then self.RTScopeOffset = {0,0} end
	if !self.RTScopeScale then self.RTScopeScale = {1,1} end
	
	local rtow,rtoh = self.RTScopeOffset[1], self.RTScopeOffset[2]
	local rtw,rth = 512 * self.RTScopeScale[1], 512 * self.RTScopeScale[2]
	
	cd.x = 0
	cd.y = 0
	cd.w = rtw
	cd.h = rth
	cd.fov = self.RTScopeFOV
	cd.drawviewmodel = false
	cd.drawhud = false
	
	render.Clear( 0, 0, 0, 255, true, true )
	
	render.SetScissorRect(0+rtow,0+rtoh,rtw+rtow,rth+rtoh,true)
	if self.CLIronSightsProgress>0.01 and self.Scoped_3D then
		render.RenderView(cd)
	end
	render.SetScissorRect(0,0,rtw,rth,false)
	
	render.OverrideAlphaWriteEnable( false, true)	
	
	cam.Start2D()
		draw.NoTexture()
		surface.SetTexture(self.myshadowmask)
		surface.SetDrawColor(color_white)
		if self:Do3DScopeOverlay() then
			surface.DrawTexturedRect(scrpos.x+rtow-rtw/2,scrpos.y+rtoh-rth/2,rtw*2,rth*2)
		end
		if self.ScopeReticule_CrossCol then
			crosscol.r = GetConVarNumber("cl_tfa_hud_crosshair_color_r")
			crosscol.g = GetConVarNumber("cl_tfa_hud_crosshair_color_g")
			crosscol.b = GetConVarNumber("cl_tfa_hud_crosshair_color_b")
			crosscol.a = GetConVarNumber("cl_tfa_hud_crosshair_color_a")
			surface.SetDrawColor(crosscol)
		end
		surface.SetMaterial(self.myreticule)
		local tmpborderw = rtw*(1-self.ScopeReticule_Scale[1])/2
		local tmpborderh = rth*(1-self.ScopeReticule_Scale[2])/2
		surface.DrawTexturedRect(rtow+tmpborderw,rtoh+tmpborderh,rtw-tmpborderw*2,rth-tmpborderh*2)		
		surface.SetDrawColor(color_black)
		draw.NoTexture()
		if self:Do3DScopeOverlay() then
			surface.DrawRect(scrpos.x-2048+rtow, -1024+rtoh, 2048, 2048)
			surface.DrawRect(scrpos.x+rtw+rtow, -1024+rtoh, 2048, 2048)
			surface.DrawRect(-1024+rtow, scrpos.y-2048+rtoh, 2048, 2048)
			surface.DrawRect(-1024+rtow, scrpos.y+rth+rtoh, 2048, 2048)
		end
		surface.SetDrawColor(ColorAlpha(color_black,255-255*( math.Clamp( self.CLIronSightsProgress-0.75,0,0.25 )*4 ) ) )
		surface.DrawRect(-1024+rtow, -1024+rtoh,2048,2048)
		surface.SetMaterial(self.mydirt)
		surface.SetDrawColor(ColorAlpha(color_white,128))
		surface.DrawTexturedRect(0,0,rtw,rth)
		surface.SetDrawColor(ColorAlpha(color_white,64))
		surface.DrawTexturedRectUV(rtow,rtoh,rtw,rth,2,0,0,2)
	cam.End2D()
end