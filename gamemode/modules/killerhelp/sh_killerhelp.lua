-- Utopia Games - Slashers
--
-- @Author: Garrus2142
-- @Date:   2017-07-25 16:15:50
-- @Last Modified by:   Daryl_Winters
-- @Last Modified time: 2017-08-09T17:20:41+02:00

hook.Add( "PlayerFootstep", "CDisableSoundFootStepsUnique", function( ply, pos, foot, sound, volume, filter )
	if ply:GetColor().a == 0  then
		return true
	else
		return
	end
end )
