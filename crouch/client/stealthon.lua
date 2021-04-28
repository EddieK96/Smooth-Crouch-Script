Citizen.CreateThread(function()	
	stealth = {}
	stealth.on = false
	stealth.forced = false
	stealth.initialized = true
	local playerped = PlayerPedId()
	local player = GetPlayerIndex()
	local function notify(text)
		SetTextComponentFormat('STRING')
		AddTextComponentString(text)
		DisplayHelpTextFromStringLabel(0, 0, 1, -1)
	end
	while config == nil or config.initialized == nil or cor == nil or cor.initialized == nil do
		Citizen.Wait(0)
	end
	
	while true do
		Citizen.Wait(0)
		playerped = PlayerPedId()
		player = GetPlayerIndex()
		if stealth.forced then
		--	if stealth.on then
				--notify("stealth")
			--	TaskForceMotionState()
		--end
			SetPedStealthMovement(playerped, stealth.on, 0)	
		end	
		
		if cor.forcedActionmode then
			SetPedUsingActionMode(playerped, cor.actionmode, 0, "DEFAULT_ACTION")
			if not cor.actionmode then
				RemoveActionModeAsset(-1)
			end
		end	
	end
end)
