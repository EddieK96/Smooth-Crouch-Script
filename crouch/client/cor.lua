Citizen.CreateThread(function()	
	while config == nil or config.initialized == nil do
		Citizen.Wait(0)
	end
	
	cor = {}
	cor.timer = 0
	cor.actionmodeoff = false
	cor.initialized = true
	
	
	while true do
		Citizen.Wait(1)
		playerped = PlayerPedId()
		if cor.timer > 0 then
			cor.timer = cor.timer - 1
		end
	end
end)