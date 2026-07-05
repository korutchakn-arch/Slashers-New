-- Utopia Games - Slashers
--
-- @Author: Garrus2142
-- @Date:   2017-07-25 16:15:48
-- @Last Modified by:   Garrus2142
-- @Last Modified time: 2017-07-26 14:45:37

local GM = GM or GAMEMODE

function GM.ROUND:ChooseKiller()
	local allPlayers = player.GetAll()

	if #allPlayers == 0 then return nil end

	return table.Random(allPlayers)
end