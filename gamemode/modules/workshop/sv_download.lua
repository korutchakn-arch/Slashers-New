-- Utopia Games - Slashers
--
-- @Author: Guilhem PECH
-- @Date:   2017-07-26T18:35:23+02:00
-- @Last Modified by:   Guilhem PECH
-- @Last Modified time: 2017-07-26 22:32:22


util.AddNetworkString("slash_WorkShopCheck")
function WSDLCheckOpen(ply)
	-- Guard: only send once per player to avoid conflicts with other addons
	-- that also call net.Start("slash_WorkShopCheck") on PlayerInitialSpawn.
	if ply._wsdlChecked then return end
	ply._wsdlChecked = true

	net.Start("slash_WorkShopCheck")
	net.Send(ply)
end
hook.Add("PlayerInitialSpawn", "WSDLCheckOpen", WSDLCheckOpen)
