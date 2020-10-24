Citizen.CreateThread(function()
	local playerped = PlayerPedId() --PLAYER.
	local player = GetPlayerIndex() --PLAYER.
	local togglecrouch = false
	local timer = 0
	--TODO
	--clean up unused code
	--set custom action mode timer/anim
	--make release-ready + readable config
	--???
	--profit
	while config == nil or config.initialized == nil or cor == nil or cor.initialized == nil or stealth == nil or stealth.initialized == nil do
		Citizen.Wait(0)
	end
	
	local function notify(text)
		SetTextComponentFormat('STRING')
		AddTextComponentString(text)
		DisplayHelpTextFromStringLabel(0, 0, 1, -1)
	end
	
	local function reset()
		ResetPedMovementClipset(playerped, 0.55)
		--while not HasAnimSetLoaded("move_action@generic@idle@variations") do
			--Citizen.Wait(0)
			--RequestAnimSet("move_action@generic@idle@variations")
		--end
		--SetPedMovementClipset(playerped, "move_action@generic@idle@variations", 0.55)
		ResetPedStrafeClipset(playerped)
		SetPedCanPlayAmbientAnims(playerped, true)
		SetPedCanPlayAmbientBaseAnims(playerped, true)
		ResetPedWeaponMovementClipset(playerped)
	end
	
	Citizen.Trace("initialized!\n")
	while true do
		Citizen.Wait(0)
		playerped = PlayerPedId() --PLAYER.
		player = GetPlayerIndex() --PLAYER.
		if IsPedOnFoot(playerped) and not IsPedJumping(playerped) and not IsPedFalling(playerped) and not IsPlayerDead(player) then
			if IsControlJustReleased(0,  36) and cor.timer == 0 then
				cor.timer = 35
				reset()
				if togglecrouch then
					togglecrouch = false
				else		
					togglecrouch = true
					RequestAnimSet('move_ped_crouched')
				end
			end	
			
			if togglecrouch then
				--notify(tostring(playerped))
				SetPedCanPlayAmbientAnims(playerped, false)
				SetPedCanPlayAmbientBaseAnims(playerped, false)
				SetPedStealthMovement(playerped, false, "DEFAULT_ACTION")
				stealth.on = false
				if (GetFollowPedCamViewMode() == 4) then
					SetFollowPedCamViewMode(0)
				end
				while not HasAnimSetLoaded('move_ped_crouched') do
					Citizen.Wait(0)
					RequestAnimSet('move_ped_crouched')
					--notify("LOADING ANIM SET")
				end
				cor.actionmodeoff = true
				SetPedUsingActionMode(playerped, false, -1, "DEFAULT_ACTION")
				SetPedMovementClipset(playerped, 'move_ped_crouched', 0.55)
				SetPedStrafeClipset(playerped, 'move_ped_crouched_strafing')
				SetWeaponAnimationOverride(playerped, "Ballistic")
				
				if IsPlayerFreeAiming(player) or IsAimCamActive() or IsAimCamThirdPersonActive() then
					SetPedMaxMoveBlendRatio(playerped, 0.2)
					--notify("PLAYER AIMING")
				else
					SetPedMaxMoveBlendRatio(playerped, 10.0)
				end
			else
				cor.actionmodeoff = true
				SetPedUsingActionMode(playerped, false, -1, "DEFAULT_ACTION")
				if IsPlayerFreeAiming(player) then
					SetPedMaxMoveBlendRatio(playerped, 1.0)
					SetPedStealthMovement(playerped, true, "DEFAULT_ACTION")
					stealth.on = true
					--notify("PLAYER AIMING")
				else
					SetPedStealthMovement(playerped, false, "DEFAULT_ACTION")
					stealth.on = false
					if IsAimCamActive() or IsAimCamThirdPersonActive() then
						--notify("PLAYER FREE-AIMING")
						SetPedMaxMoveBlendRatio(playerped, 10.0)
					else
						SetPedMaxMoveBlendRatio(playerped, 10.0)	
					end
				end
			end
        
		else
			togglecrouch = false
			reset()
		end
	end
end)