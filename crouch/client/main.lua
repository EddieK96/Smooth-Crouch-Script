Citizen.CreateThread(function()
	while config == nil or config.initialized == nil or cor == nil or cor.initialized == nil or stealth == nil or stealth.initialized == nil do
		Citizen.Wait(0)
	end
	
	local smoothStanceChange = false
	local stanceModifier = false
	local stealthAim = true -- config.stealthAi
	local stanceChangeCooldownDuration = 220 -- config.stanceChangeCooldownDuration
	
	local toggleCrouchWithDuckBind = true
	local persistentCrouchStance = false --Stance does not reset after ragdolling/falling/jumping.
	
	
	local proneEnabled = false -- config.proneEnabled
	local persistentProneStance = true --Stance does not reset after ragdolling/falling.
	local holdDuckBindToProne = false
	
	local enableStealthStance= false
	local persistentStealthStance = false --Stance does not reset after ragdolling/falling/jumping.
	
	Crouch = {}
	Crouch.blendRatio = 10.0
	Crouch.maxMoveSpeed = 10.0
	Crouch.moveSpeedCrouched = 10.0
	Crouch.moveSpeedCrouchedADS = 0.2
	Crouch.moveSpeedCrouchedFreeaim = 0.2
	Crouch.crouchSpeed = 0.35
	Crouch.freeAimMaxMoveSpeed = 10.0
	Crouch.adsMaxMoveSpeed = 10.0
	Crouch.moveSpeedProne = 0.2
	Crouch.moveSpeedProneADS = 0.0
	Crouch.moveSpeedProneFreeaim = 0.0
	Crouch.proneSpeed = 0.5
	Crouch.stealthfreeAimMaxMoveSpeed = 10.0
	Crouch.stealthadsMaxMoveSpeed = 10.0
	
	local workaround = 3 	--Workaround mode (1-3, 0 | >3 = off) for a bug where the player model starts floating while crouched and aiming.
				-- I recommend not touching this unless you want sniper scopes/aim-zoom to work at the cost of a buggy crouch transition.
	
	local debugMode = false
	
	--END OF CONFIG--
	local stance = 3 	-- 3 = standing; 
						-- 2* = stealth; 
						-- 1 = crouched; 
						-- 0* = prone.
	local clippingDistance = -10.0
	local lastHighStance = 3
	local lastLowStance = 1
	local playerped = PlayerPedId() --PLAYER.
	local player = GetPlayerIndex() --PLAYER.
	local weaponType = GetWeapontypeGroup(GetSelectedPedWeapon(playerped)) --WEAPON TYPE
	local altCam = false
	local forcedAimOn = false
	local camMode = 0
	local playerAiming = false
	
	--Crouch.crouchSpeedActionMode = 1.0 
	
	--AddEventHandler("Crouch:getSharedObject", function (newCrouch)
	--	Crouch = newCrouch
	--end)
	
	--AddEventHandler("Crouch:setSharedObject", function ()
		--return Crouch
	--end)
	
	local function notify(text)
		if debugMode then
			SetTextComponentFormat('STRING')
			AddTextComponentString(text)
			DisplayHelpTextFromStringLabel(0, 0, 1, -1)
		end
	end
	
	local function refreshPlayerData ()
		playerped = PlayerPedId() --PLAYER.
		player = GetPlayerIndex() --PLAYER.
	end
	
	local chEnabled = true
	local function aimHudThisTick ()
		if chEnabled then
			EnableCrosshairThisFrame()
			DisplaySniperScopeThisFrame()
		end
	end
	
	defcam = GetRenderingCam()
	defcamcoords = GetCamCoord(defcam)
	cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", defcamcoords.x, defcamcoords.y, defcamcoords.z, 0.0, 0.0, 0.0, GetGameplayCamFov(), false, 0)
	SetCamAffectsAiming(cam, true)
	local function enableAltCam (b)
		if b then
			altCam = true
			if workaround == 1 then
				RenderScriptCams(true, true, 500, true, false)
				SetCamActive(cam, true)
			end
		else
			SetCamActive(cam, false)
			RenderScriptCams(false, true, 500, true, false)
			--notify("cam Off")
			altCam = false
		end
	end
	
	local function thisStealth (b)
		SetPedStealthMovement(playerped, b, "DEFAULT_ACTION")
		stealth.on = b
	end
	
	local function forcedStealth (b)
		stealth.forced = b
	end
	
	local function actionmode (b)
		SetPedUsingActionMode(playerped, b, -1, "DEFAULT_ACTION")
		cor.actionmode = b
	end
	
	local function forcedActionmode (b)
		cor.forcedActionmode = b
	end
	
	local isReset = false
	local function reset()
		if not isReset then
			enableAltCam(false)
			notify("RESETTING SCRIPT")
			SetPedMaxMoveBlendRatio(playerped, 10.0)
			Crouch.blendRatio = 10.0
			ResetPedWeaponMovementClipset(playerped)
			SetPedWeaponMovementClipset(playerped, 'Ballistic')
			ResetPedStrafeClipset(playerped)
			SetPedCoverClipsetOverride(playerped, 'Ballistic')
			ResetPedMovementClipset(playerped, Crouch.crouchSpeed)
			SetPedCanPlayAmbientAnims(playerped, true)
			SetPedCanPlayAmbientBaseAnims(playerped, true)

			actionmode(false)
			forcedActionmode(false)
			
			if (not persistentProneStance) and stance == 0 then
				stance = 1
			end
			
			if (not persistentCrouchStance) and stance == 1 then
				if enableStealthStance then
					stance = 2
				else
					stance = 3
				end
			end
			
			if (not persistentStealthStance) and stance == 2 then
				stance = 3
			end
			
			isReset = true
		end
	end
	
	local function duckBindPressed ()
		return IsControlJustReleased(0, 36)
	end
	
	local function stanceChangeCooldown (ms)
		cor.stanceChangeCooldown(ms)
	end
	
	local function stanceChangeCooldownRunning ()
		return cor.stanceChangeCooldownRunning
	end
	
	local function upStance ()
		-- 3 = standing; 
		-- 2* = stealth; 
		-- 1 = crouched; 
		-- 0* = prone.
		
		if stance == 0 or stance == 2 then
			if stance == 0 then
				lastLowStance = 0
			else
				lastHighStance = 2
			end
			stance = stance + 1
			return stance
		
		else
			if stance == 1 then
				lastLowStance = stance
				if enableStealthStance then
					stance = 2
					return stance
				else
					stance = 3
					return stance
				end
			else
				return stance
			end
		end	
	end
	
	local function downStance ()
		-- 3 = standing; 
		-- 2* = stealth; 
		-- 1 = crouched; 
		-- 0* = prone.
		
		if stance == 2 then
			lastHighStance = stance
			stance = 1
			return stance
		
		else
			if stance == 1 then
				if proneEnabled then
					lastLowStance = stance
					stance = 0
					return stance
				else
					return stance
				end
			else	
				if stance == 3 then
					lastHighStance = stance
					if enableStealthStance then
						stance = 2
						return stance
					end

					stance = 1
					return stance
				else
					return stance
				end
			end
		end	
	end
	
	local function toggleCrouch ()
		if stance == 1 then
			lastLowStance = stance
			stance = lastHighStance
			return stance
		else
			if not stance == 0 then
				lastHighStance = stance
				stance = 1
				return stance
			else
				lastLowStance = stance
				stance = 1
				return stance
			end
		end
	end
	
	local function stand ()
		reset()
		thisStealth (false)
		forcedStealth(true)
	end
	
	local function tickStanding ()
		if IsPlayerFreeAiming(player) then
			SetPedMaxMoveBlendRatio(playerped, Crouch.adsMaxMoveSpeed)
			Crouch.blendRatio = Crouch.adsMaxMoveSpeed
			aimHudThisTick ()
			if stealthAim then
				--notify("stealthaim")
				thisStealth(true)
				forcedStealth(true)
			else
				thisStealth (false)
				forcedStealth(true)
			end

		else
			thisStealth(false)
			forcedStealth(true)
			if IsAimCamActive() or IsAimCamThirdPersonActive() or GetPedConfigFlag(playerped, 78, 1) then
				aimHudThisTick ()
				SetPedMaxMoveBlendRatio(playerped, Crouch.freeAimMaxMoveSpeed)	
				Crouch.blendRatio = Crouch.freeAimMaxMoveSpeed
				--notify("PLAYER FREE-AIMING")
			else
				SetPedMaxMoveBlendRatio(playerped, Crouch.maxMoveSpeed)
				Crouch.blendRatio = Crouch.maxMoveSpeed
			end
		end
	end
	
	local function goStealthy ()
		enableAltCam(false)
		thisStealth(true)
		forcedStealth(true)
	end
	
	local function tickStealthy ()
		if IsPlayerFreeAiming(player) then
			SetPedMaxMoveBlendRatio(playerped, Crouch.stealthadsMaxMoveSpeed)
			Crouch.blendRatio = Crouch.stealthadsMaxMoveSpeed
			--notify("PLAYER AIMING STEALTHY")
			if workaround == 3 then
				SetThirdPersonAimCamNearClipThisUpdate(clippingDistance)
			end
			aimHudThisTick ()
		else
			if IsAimCamActive() or IsAimCamThirdPersonActive() or GetPedConfigFlag(playerped, 78, 1) then
				SetPedMaxMoveBlendRatio(playerped, Crouch.stealthfreeAimMaxMoveSpeed)	
				Crouch.blendRatio = Crouch.stealthfreeAimMaxMoveSpeed
				--notify("PLAYER FREE-AIMING STEALTHY")
				aimHudThisTick ()
			end
		end
	end
	
	local function refreshWeaponAnimCrouched ()
		if weaponType == 970310034 or weaponType == -957766203 or weaponType == 1159398588 or weaponType == -1212426201 or weaponType == 860033945 or weaponType == -1569042529then
			animGroupWeaponMovementClipset = "move_stealth@p_m_one@2h_short@upper"
			while not HasAnimSetLoaded(animGroupWeaponMovementClipset) do
				Citizen.Wait(0)
				RequestAnimSet(animGroupWeaponMovementClipset)
				--notify("LOADING ANIM SET")
			end
			SetPedWeaponMovementClipset(playerped, animGroupWeaponMovementClipset)
		else
			ResetPedWeaponMovementClipset(playerped)
		end
	end
	
	local function crouch ()
		--notify("CROUCHING")
		RequestAnimSet('move_ped_crouched')
		thisStealth(false)
		forcedStealth(true)
		actionmode(false)
		forcedActionmode(true)
		SetPedCanPlayAmbientAnims(playerped, false)
		SetPedCanPlayAmbientBaseAnims(playerped, false)
		
		animGroupMovementClipset = "move_ped_crouched" --move_ped_crouched
		while not HasAnimSetLoaded(animGroupMovementClipset) do
			Citizen.Wait(0)
			RequestAnimSet(animGroupMovementClipset)
			--notify("LOADING ANIM SET")
		end
		SetPedMovementClipset(playerped, animGroupMovementClipset, Crouch.crouchSpeed)
		
		refreshWeaponAnimCrouched()
		
		animGroupStrafeMovementClipset = "move_ped_crouched_strafing"
		while not HasAnimSetLoaded(animGroupStrafeMovementClipset) do
			Citizen.Wait(0)
			RequestAnimSet(animGroupStrafeMovementClipset)
			--notify("LOADING ANIM SET")
		end
		SetPedStrafeClipset(playerped, animGroupStrafeMovementClipset)
		--ResetPedStrafeClipset(playerped)
		
		animGroupCoverMovementClipset = "move_ped_crouched"
		while not HasAnimSetLoaded(animGroupStrafeMovementClipset) do
			Citizen.Wait(0)
			RequestAnimSet(animGroupStrafeMovementClipset)
			--notify("LOADING ANIM SET")
		end
		--SetPedCoverClipsetOverride(playerped, animGroupCoverMovementClipset, Crouch.crouchSpeed)
		--ClearPedCoverClipsetOverride(playerped)
		--while not HasAnimSetLoaded('Ballistic') do
		--	Citizen.Wait(0)
			--RequestAnimSet('Ballistic')
			--notify("LOADING ANIM SET")
		--end
		--notify("CROUCHED")
	end


	local function tickCam ()
		if altCam and workaround == 1 then
			defcamcoords = GetGameplayCamCoord()
			SetCamCoord(cam, defcamcoords.x, defcamcoords.y, defcamcoords.z)
			defcamrot = GetGameplayCamRot(0)
			SetCamRot(cam, defcamrot.x, defcamrot.y, defcamrot.z, 0)
			playercoords = GetEntityCoords(playerped)
			--PointCamAtCoord(cam, playercoords.x, playercoords.y, playercoords.z)
			SetCamActive(cam, true)
			RenderScriptCams(true, false, 3000, true, false)
			SetFollowPedCamThisUpdate("DEFAULT_SCRIPTED_CAMERA", 10000)
			SetCinematicModeActive(false)
			--notify(GetRenderingCam() .. " " .. cam .. " " .. GetFollowPedCamViewMode())
			--notify(defcamcoords.x .. " " .. defcamcoords.y .. " " .. defcamcoords.z)
			--notify(GetFollowPedCamZoomLevel())
		end
		
		--if altCam and workaround == 4 then
			--AnimateGameplayCamZoom(10.0, 10.0)
		--end
	end
	

	local function tickCrouched ()
		DisableFirstPersonCamThisFrame()
		refreshWeaponAnimCrouched()
		if IsPedUsingActionMode(playerped) and ((not IsPedInCover(playerped, false)) or (IsPedAimingFromCover(playerped) and not forcedAimOn)) and not IsPedGoingIntoCover(playerped) then
			notify("actionmode")
			SetPlayerSimulateAiming(player, true)
			forcedAimOn = true
		else
			forcedAimOn = false
			--SetPlayerSimulateAiming(player, false)
		end
		
		if IsPedReloading(playerped) then
			SetPlayerSprint(player, false)
			DisableControlAction(0, 21, true)
			notify("Sprinting is forced off.")
		end
		
		if workaround == 2 then
			DisableAimCamThisUpdate()
		end
		
		if IsPlayerFreeAiming(player) then
			if not altCam then
				enableAltCam(true)
			end
			--SetFollowPedCamThisUpdate(string camName, int p1)
			--Cam CreateCamWithParams(string camName, float posX, float posY, float posZ, float rotX, float rotY, float rotZ, float fov, bool p8, int p9)
			--DisableAimCamThisUpdate()
			--SetGameplayCamRelativePitch(0, 1.0)
			--SetThirdPersonAimCamNearClip(0)
			--EnableCrosshairThisFrame()
			aimHudThisTick ()
			if workaround == 3 then
				SetThirdPersonAimCamNearClipThisUpdate(clippingDistance)
			else
				if workaround == 4 then
					DisableAimCamThisUpdate()
				end
			end
			SetPedMaxMoveBlendRatio(playerped, Crouch.moveSpeedCrouchedADS)
			Crouch.blendRatio = Crouch.moveSpeedCrouchedADS
			--notify("PLAYER AIMING CROUCHED")
			--InvalidateIdleCam
			--SetGameplayCamRelativeHeading(0)
			--SetPlayerForcedZoom(player, true)
		else
			enableAltCam(false)
			--SetPlayerForcedZoom(player, false)
			if IsAimCamActive() or IsAimCamThirdPersonActive() or GetPedConfigFlag(playerped, 78, 1) then
				SetPedMaxMoveBlendRatio(playerped, Crouch.moveSpeedCrouchedFreeaim)
				Crouch.blendRatio = Crouch.moveSpeedCrouchedFreeaim
				aimHudThisTick ()
				--notify("PLAYER FREEAIMING CROUCHED")
			else
				SetPedMaxMoveBlendRatio(playerped, Crouch.moveSpeedCrouched)
				Crouch.blendRatio = Crouch.moveSpeedCrouched
				--notify("PLAYER CROUCHED")
			end
		end
	end
	
	local function prone ()
		enableAltCam(false)
		--notify("PLAYER PRONE")
	end
	
	local function tickProne ()
		Citizen.Wait(notify("PLAYER STILL PRONE"))
	end
	
	local function updateStance ()
		if stance == 3 then
			stand()
		end
		
		if stance == 2 then
			goStealthy()
		end
		
		if stance == 1 then
			crouch()
		end
		
		if stance == 0 then
			prone()
		end
		isReset = false
	end
	
	local function updateTickStance ()
		--notify(stance)
		if stance == 3 then
			tickStanding()
		end
		
		if stance == 2 then
			tickStealthy()
		end
		
		if stance == 1 then
			tickCrouched()
		end
		
		if stance == 0 then
			tickProne()
		end
		isReset = false
	end
	
	Citizen.Trace("initialized!\n")
	while true do
		Citizen.Wait(0)
		weaponType = GetWeapontypeGroup(GetSelectedPedWeapon(playerped)) --WEAPON TYPE
		--notify("Type: " .. GetWeapontypeGroup(GetSelectedPedWeapon(playerped)))
		tickCam()
		--SetPedStealthMovement(playerped, true, 0)	
		
		if IsControlPressed(0,25) then
			SetPlayerForcedZoom(player, true)
			playerAiming = true
		else
			playerAiming = false
		end
		--notify(GetFollowPedCamViewMode().." yes")
		--DisableControlAction(0, 21, true)
		if workaround == 3 then
			DisableAimCamThisUpdate()
		end
		refreshPlayerData()
		if IsPedOnFoot(playerped) and not IsPedJumping(playerped) and not IsPedFalling(playerped) and not IsPlayerDead(player)  then
			if not stanceChangeCooldownRunning() then
				if  toggleCrouchWithDuckBind and duckBindPressed() then
					stanceChangeCooldown(stanceChangeCooldownDuration)
					toggleCrouch()
					updateStance()
				end
			else
				DisableControlAction(2, 36, true)
			end
			updateTickStance()
		else
			reset()
		end
	end
end)

GetWeapontypeGroup(GetSelectedPedWeapon(playerped))
