Citizen.CreateThread(function()	
	stealth = {}
	stealth.on = false
	stealth.initialized = true
	local playerped = PlayerPedId()
	while config == nil or config.initialized == nil or cor == nil or cor.initialized == nil do
		Citizen.Wait(0)
	end
	
	while true do
		Citizen.Wait(0)
		if stealth.on then
			SetPedStealthMovement(playerped, true, "DEFAULT_ACTION")
		else
			SetPedStealthMovement(playerped, false, "DEFAULT_ACTION")
		end
		if cor.actionmodeoff == true then
			SetPedUsingActionMode(playerped, false, -1, 0)
			SetPedUsingActionMode(playerped, false, -1, "DEFAULT_ACTION")
		end
	end
end)