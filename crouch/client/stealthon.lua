Citizen.CreateThread(function()	
	stealth = {}
	stealth.on = false
	stealth.forced = false
	stealth.initialized = true
	local playerped = PlayerPedId()
	while config == nil or config.initialized == nil or cor == nil or cor.initialized == nil do
		Citizen.Wait(0)
	end
	
	while true do
		Citizen.Wait(0)
		
		if stealth.forced then
			SetPedStealthMovement(playerped, stealth.on, "DEFAULT_ACTION")
		end	
		
		if cor.forcedActionmode then
			SetPedUsingActionMode(playerped, cor.actionmode, -1, "DEFAULT_ACTION")
		end	
	end
end)