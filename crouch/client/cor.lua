Citizen.CreateThread(function()	
	while config == nil or config.initialized == nil do
		Citizen.Wait(0)
	end
	
	cor = {}
	cor.stanceChangeCooldownRunning = false
	cor.actionmode = false
	cor.forcedActionmode = false
	cor.timer = 0
	
	cor.stanceChangeCooldown = function (ms)
		cor.stanceChangeCooldownRunning = true
		cor.timer = ms
	end
	
	cor.initialized = true
	
	while true do
		if cor.stanceChangeCooldownRunning then
			Citizen.Wait(cor.timer)
			cor.stanceChangeCooldownRunning = false
		else
			Citizen.Wait(0)
		end
	end
end)