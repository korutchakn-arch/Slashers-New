if (SERVER) then
	AddCSLuaFile();
	AddCSLuaFile("sh_blink.lua");
end

include("sh_blink.lua");

SWEP.Slot       = 1
SWEP.SlotPos    = 1
SWEP.DrawAmmo   = false
SWEP.PrintName  = "Blink"
SWEP.DrawCrosshair = true
SWEP.Category   = "Dishonored";
SWEP.Instructions = "POOF"
SWEP.Purpose = ""
SWEP.Contact = ""
SWEP.Author = "Zombine"
SWEP.WorldModel = ""
SWEP.ViewModel = "models/weapons/v_punch.mdl"
SWEP.HoldType = "none"
SWEP.AdminSpawnable = false
SWEP.Spawnable = true;
SWEP.Primary.NeverRaised = true
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.Damage = 90
SWEP.Primary.Delay = 3
SWEP.Primary.Ammo = ""
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.Delay = 0
SWEP.Secondary.Ammo = ""
SWEP.NoIronSightFovChange = true
SWEP.NoIronSightAttack = true
SWEP.LoweredAngles = Angle(60, 60, 60)
SWEP.IronSightPos = Vector(0, 0, 0)
SWEP.IronSightAng = Vector(0, 0, 0)
SWEP.NeverRaised = true
SWEP.TravelDistance = 600
SWEP.TravelTime = 0.12
SWEP.TravelSpeed = 4000

function SWEP:Holster(switchingTo)
	return true;
end;

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Charging");
end;

function SWEP:Initialize()
	if (CLIENT) then
		self.bottomVis = util.GetPixelVisibleHandle();
		self.topVis = util.GetPixelVisibleHandle();
	end;

	self:SetHoldType("none");
end;

function SWEP:PreDrawViewModel()
	render.SetBlend(0);
end;

function SWEP:PostDrawViewModel()
	render.SetBlend(1);
end;

function SWEP:PrepBlink()
	local player = self.Owner;

	player:SetNWBool("showBlink", true);

	if (SERVER) then
		player:EmitSound("blink/enter" .. math.random(1, 2) .. ".wav");
	end;
end;

function SWEP:GetEyeHeight()
	return self.Owner:EyePos() - self.Owner:GetPos();
end;

function SWEP:DoBlink()
	local player = self.Owner;

	if (!player:GetNWBool("showBlink", false)) then return; end;
	local speed = self.TravelSpeed;
	local bFoundEdge = false;

	player:SetNWBool("showBlink", false);

	local hullTrace = util.TraceHull({
		start = player:EyePos(),
		endpos = player:EyePos() + player:EyeAngles():Forward() * self.TravelDistance,
		filter = player,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 9)
	});

	local groundTrace = util.TraceEntity({
		start = hullTrace.HitPos + Vector(0, 0, 1),
		endpos = hullTrace.HitPos - self:GetEyeHeight(),
		filter = player
	}, player);

	local edgeTrace;

	if (hullTrace.Hit and hullTrace.HitNormal.z <= 0) then
		local ledgeForward = Angle(0, hullTrace.HitNormal:Angle().y, 0):Forward();
		edgeTrace = util.TraceEntity({
			start = hullTrace.HitPos - ledgeForward * 33 + Vector(0, 0, 40),
			endpos = hullTrace.HitPos - ledgeForward * 33,
			filter = player
		}, player);

		if (edgeTrace.Hit and !edgeTrace.AllSolid) then
			local clearTrace = util.TraceHull({
				start = hullTrace.HitPos,
				endpos = hullTrace.HitPos + Vector(0, 0, 35),
				mins = Vector(-16, -16, 0),
				maxs = Vector(16, 16, 1),
				filter = player
			});

			bFoundEdge = !clearTrace.Hit;
		end;
	end;

	if (!bFoundEdge and groundTrace.AllSolid) then
		self:CancelBlink();
		return;
	end;

	local endPos = bFoundEdge and edgeTrace.HitPos or groundTrace.HitPos;
	local travelTime = (endPos - player:EyePos()):Length() / (speed);

	player:SetNWBool("blink", true);
	player:SetNWVector("blinkPos", endPos);
	player:SetNWVector("blinkStart", player:GetPos());
	player:SetNWFloat("blinkTime", travelTime);

	player:SetGroundEntity(nil);
	player:SetNotSolid(true);
	player:SetMoveType(MOVETYPE_NOCLIP);
	player:EmitSound("blink/exit" .. math.random(1, 2) .. ".wav");

	player:SetNWFloat("nextBlink", CurTime() + 15);
end;

function SWEP:CancelBlink()
	self:SetCharging(false);
	self.Owner:SetNWBool("showBlink", false);
end;

do
	local cyan = Color(150, 210, 255);

	function SWEP:Think()
		local player = self.Owner;
		local bCharging = self:GetCharging();

		if (!player:KeyDown(IN_ATTACK) and bCharging) then
			if (SERVER) then
				self:DoBlink();
			end;

			self:SetCharging(false);
		end;

		if (bCharging) then
			local bFoundEdge = false;

			local hullTrace = util.TraceHull({
				start = player:EyePos(),
				endpos = player:EyePos() + player:EyeAngles():Forward() * self.TravelDistance,
				filter = player,
				mins = Vector(-16, -16, 0),
				maxs = Vector(16, 16, 9)
			});

			self.groundTrace = util.TraceHull({
				start = hullTrace.HitPos + Vector(0, 0, 1),
				endpos = hullTrace.HitPos - Vector(0, 0, 1000),
				filter = player,
				mins = Vector(-16, -16, 0),
				maxs = Vector(16, 16, 1)
			});

			local edgeTrace;

			if (hullTrace.Hit and hullTrace.HitNormal.z <= 0) then
				local ledgeForward = Angle(0, hullTrace.HitNormal:Angle().y, 0):Forward();
				edgeTrace = util.TraceEntity({
					start = hullTrace.HitPos - ledgeForward * 33 + Vector(0, 0, 40),
					endpos = hullTrace.HitPos - ledgeForward * 33,
					filter = player
				}, player);

				if (edgeTrace.Hit and !edgeTrace.AllSolid) then
					local clearTrace = util.TraceHull({
						start = hullTrace.HitPos,
						endpos = hullTrace.HitPos + Vector(0, 0, 35),
						mins = Vector(-16, -16, 0),
						maxs = Vector(16, 16, 1),
						filter = player
					});

					if (!clearTrace.Hit) then
						self.groundTrace.HitPos = edgeTrace.HitPos;
						bFoundEdge = true;
					end;
				end;
			end;

			if (CLIENT) then
				if (!bFoundEdge) then
					local topLight = DynamicLight(1);

					if (topLight) then
						topLight.pos = hullTrace.HitPos;
						topLight.brightness = 0.5;
						topLight.Size = 200;
						topLight.Decay = 1000
						topLight.r = cyan.r;
						topLight.g = cyan.g;
						topLight.b = cyan.b;
						topLight.DieTime = CurTime() + 0.2;
						topLight.style = 0;
					end;
				end;

				local bottomLight = DynamicLight(2);

				if (bottomLight) then
					bottomLight.pos = self.groundTrace.HitPos;
					bottomLight.brightness = 0.5;
					bottomLight.Size = 200;
					bottomLight.Decay = 1000
					bottomLight.r = cyan.r;
					bottomLight.g = cyan.g;
					bottomLight.b = cyan.b;
					bottomLight.DieTime = CurTime() + 0.2;
					bottomLight.style = 0;
				end;
			end;
		end;

		self:NextThink(CurTime());

		return true;
	end;

	if (CLIENT) then
		local mat = CreateMaterial("blinkGlow7", "UnlitGeneric", {
			["$basetexture"] = "particle/particle_glow_05",
			["$basetexturetransform"] = "center .5 .5 scale 1 1 rotate 0 translate 0 0",
			["$additive"] = 1,
			["$translucent"] = 1,
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
			["$ignorez"] = 0
		});

		local mat2 = CreateMaterial("blinkBottom", "UnlitGeneric", {
			["$basetexture"] = "particle/particle_glow_05",
			["$basetexturetransform"] = "center .5 .5 scale 1 1 rotate 0 translate 0 0",
			["$additive"] = 1,
			["$translucent"] = 1,
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
			["$ignorez"] = 1
		});

		function SWEP:Draw3D()
			if (!self:GetCharging()) then return; end;
			local player = LocalPlayer();
			local bFoundEdge = false;

			local hullTrace = util.TraceHull({
				start = player:EyePos(),
				endpos = player:EyePos() + player:EyeAngles():Forward() * self.TravelDistance,
				filter = player,
				mins = Vector(-16, -16, 0),
				maxs = Vector(16, 16, 9)
			});

			local groundTrace = util.TraceHull({
				start = hullTrace.HitPos + Vector(0, 0, 1),
				endpos = hullTrace.HitPos - Vector(0, 0, 1000),
				filter = player,
				mins = Vector(-16, -16, 0),
				maxs = Vector(16, 16, 1)
			});

			local edgeTrace;

			if (hullTrace.Hit and hullTrace.HitNormal.z <= 0) then
				local ledgeForward = Angle(0, hullTrace.HitNormal:Angle().y, 0):Forward();
				edgeTrace = util.TraceEntity({
					start = hullTrace.HitPos - ledgeForward * 33 + Vector(0, 0, 40),
					endpos = hullTrace.HitPos - ledgeForward * 33,
					filter = player
				}, player);

				if (edgeTrace.Hit and !edgeTrace.AllSolid) then
					local clearTrace = util.TraceHull({
						start = hullTrace.HitPos,
						endpos = hullTrace.HitPos + Vector(0, 0, 35),
						mins = Vector(-16, -16, 0),
						maxs = Vector(16, 16, 1),
						filter = player
					});

					if (!clearTrace.Hit) then
						groundTrace.HitPos = edgeTrace.HitPos;
						bFoundEdge = true;
					end;
				end;
			end;

			local distToGround = math.abs(hullTrace.HitPos.z - groundTrace.HitPos.z);
			local upDist = vector_up * 1.1;
			local quadPos = groundTrace.HitPos + upDist;

			local quadTrace = util.TraceLine({
				start = EyePos(),
				endpos = quadPos,
				filter = player
			});

			local bottomVis = util.PixelVisible(quadPos, 3, self.bottomVis);

			if (bottomVis and bottomVis >= 0.1) then
				local visAlpha = math.Clamp(bottomVis * 255, 0, 255);

				if (visAlpha > 0 and !quadTrace.Hit) then
					render.SetMaterial(mat2);
					render.DrawSprite(quadPos, 150, 150, ColorAlpha(cyan, visAlpha), bottomVis);
				end;
			end;

			render.SetMaterial(mat);
			render.DrawQuadEasy(quadPos, vector_up, 150, 150, cyan, 0);
			render.DrawQuadEasy(quadPos + upDist, -vector_up, 150, 150, cyan, 0);

			if (distToGround >= 10 and !bFoundEdge) then
				local mappedAlpha = math.Remap(distToGround, 0, 400, 255, 0);
				local mappedUV = math.max(math.Remap(distToGround - 100, 0, 700, 0.5, 1), 0);
				local midPoint = LerpVector(0.5, hullTrace.HitPos, quadPos);

				render.DrawBeam(hullTrace.HitPos, midPoint, 50, 0.5, mappedUV, ColorAlpha(cyan, math.Clamp(mappedAlpha, 0, 255)));
				render.DrawBeam(midPoint, quadPos, 50, mappedUV, 0.5, ColorAlpha(cyan, math.Clamp(mappedAlpha, 0, 255)));

				local topVis = util.PixelVisible(hullTrace.HitPos, 3, self.topVis);

				if (topVis and topVis >= 0.1) then
					local visAlpha = math.Clamp(topVis * 255, 0, 255);

					if (visAlpha > 0) then
						local newCol = ColorAlpha(cyan, visAlpha);
						render.SetMaterial(mat2);
						render.DrawSprite(hullTrace.HitPos, 100, 100, newCol);
						render.DrawSprite(hullTrace.HitPos, 100, 100, newCol);
					end;
				end;
			else
				render.SetMaterial(mat);
				render.DrawBeam(quadPos, groundTrace.HitPos + Vector(0, 0, 300), 50, 0.5, 1, cyan);
			end;
		end;
	end;
end;

function SWEP:PrimaryAttack()
	if (self.Owner:GetNWBool("blink", false)) then return; end;

	local nextBlink = self.Owner:GetNWFloat("nextBlink", 0)
	if (nextBlink > CurTime()) then
		if (SERVER) then
			local remaining = math.ceil(nextBlink - CurTime())
			net.Start("notificationSlasher")
				net.WriteTable({"killerhelp_cant_use_ability"})
				net.WriteString("cross")
			net.Send(self.Owner)
			self.Owner:ChatPrint("[Blink] Ability on cooldown — " .. remaining .. "s remaining.")
		end
		return
	end

	self:PrepBlink();

	self:SetCharging(true);
end;

function SWEP:SecondaryAttack()
	self:CancelBlink();
end;

function SWEP:Reload()

end;