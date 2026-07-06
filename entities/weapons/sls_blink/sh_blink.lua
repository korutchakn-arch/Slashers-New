if (SERVER) then
	AddCSLuaFile();
	resource.AddSingleFile("sound/blink/enter1.wav");
	resource.AddSingleFile("sound/blink/enter2.wav");
	resource.AddSingleFile("sound/blink/exit1.wav");
	resource.AddSingleFile("sound/blink/exit2.wav");
end;

if (CLIENT) then
	hook.Add("PostDrawOpaqueRenderables", "blink_Preview", function()
		local player = LocalPlayer();

		local weapon = player:GetActiveWeapon();

		if (!IsValid(weapon) or weapon:GetClass() != "sls_blink") then return; end;

		if (weapon.Draw3D) then
			weapon:Draw3D();
		end;
	end);
end;

hook.Add("Move", "blink_Move", function(player, data)
	if (player:GetNWBool("blink", false)) then
		local weapon = player:GetWeapon("sls_blink");

		if (!IsValid(weapon)) then
			player:SetNWBool("blink", false);
			return;
		end;

		local targetPos = player:GetNWVector("blinkPos", vector_origin);
		local start = player:GetNWVector("blinkStart", data:GetOrigin());
		local travelTime = player:GetNWFloat("blinkTime", 4);
		local speed = weapon.TravelSpeed;

		if (!player.blinkNormal) then
			player.blinkNormal = (targetPos - start):GetNormalized();
			player.blinkStart = CurTime();
		end;

		local elapsed = CurTime() - player.blinkStart;

		local origin = start + player.blinkNormal * math.min((math.min(elapsed, travelTime) * speed), weapon.TravelDistance);

		data:SetOrigin(origin);
		data:SetVelocity(vector_origin);

		if (elapsed >= travelTime) then
			player:SetNWBool("blink", false);
			player:SetNotSolid(false);
			player:SetMoveType(MOVETYPE_WALK);
			data:SetVelocity(vector_origin);
			data:SetOrigin(targetPos);
			player:SetNWFloat("nextBlink", CurTime() + 15);
		end;

		return true;
	else
		player.blinkNormal = nil;
		player.blinkStart = nil;
	end;
end);

hook.Add("KeyPress", "blink_DoubleJump", function(player, key)
	if (player:OnGround() and key == IN_JUMP) then
		local weapon = player:GetWeapon("sls_blink");

		if (!IsValid(weapon)) then return; end;

		timer.Create("doubleJump_" .. player:EntIndex(), 0.25, 1, function()
			if (IsValid(player)) then
				local curVel = player:GetVelocity();
				curVel.z = player:GetJumpPower() * 1.2;

				player:SetLocalVelocity(curVel);
			end;
		end);
	end;
end);

hook.Add("KeyRelease", "blink_DoubleJump", function(player, key)
	if (key == IN_JUMP) then
		timer.Remove("doubleJump_" .. player:EntIndex());
	end;
end);