local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local BaseFolder = game.Workspace:WaitForChild("Map"):WaitForChild("Bases")

local function findPlayerBase()
	print("[AutoLock] Searching for player's base...")
	for _, baseModel in ipairs(BaseFolder:GetChildren()) do
		if baseModel:IsA("Model") and baseModel.Name == "CloneBase" then
			local userId = baseModel:GetAttribute("userId")
			print("[AutoLock] Checking base:", baseModel.Name, "userId:", userId)
			if userId and tonumber(userId) == LocalPlayer.UserId then
				print("[AutoLock] Found matching base for userId:", userId)
				return baseModel
			end
		end
	end
	print("[AutoLock] No matching base found.")
	return nil
end

local function getTouchPart(baseModel)
	print("[AutoLock] Locating TouchPart/ButtonPosition...")
	local interactables = baseModel:FindFirstChild("Interactables")
	if not interactables or not interactables:IsA("Folder") then
		print("[AutoLock] Interactables folder not found.")
		return nil
	end
	local laserButton = interactables:FindFirstChild("LaserButton")
	if not laserButton or not laserButton:IsA("Folder") then
		print("[AutoLock] LaserButton folder not found.")
		return nil
	end
	local touchPart = laserButton:FindFirstChild("TouchPart")
	if touchPart and touchPart:IsA("BasePart") then
		print("[AutoLock] Found TouchPart.")
		return touchPart
	end
	local buttonPosition = laserButton:FindFirstChild("ButtonPosition")
	if buttonPosition and buttonPosition:IsA("BasePart") then
		print("[AutoLock] TouchPart not found, using ButtonPosition.")
		return buttonPosition
	end
	print("[AutoLock] Neither TouchPart nor ButtonPosition found.")
	return nil
end

local function getTimeLabel(touchPart)
	print("[AutoLock] Searching for TimeLabel...")
	local lockBillboard = touchPart:FindFirstChild("LockBillboard")
	if not lockBillboard then
		print("[AutoLock] LockBillboard not found.")
		return nil
	end
	local frame = lockBillboard:FindFirstChild("Frame")
	if not frame then
		print("[AutoLock] Frame not found in LockBillboard.")
		return nil
	end
	local timeLabel = frame:FindFirstChild("Time")
	if timeLabel and timeLabel:IsA("TextLabel") then
		print("[AutoLock] Found TimeLabel.")
		return timeLabel
	end
	print("[AutoLock] TimeLabel not found in Frame.")
	return nil
end

local function teleportTo(part)
	print("[AutoLock] Teleporting player to part:", part and part.Name)
	local character = LocalPlayer.Character
	if not character then
		print("[AutoLock] Character not found.")
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print("[AutoLock] HumanoidRootPart not found.")
		return
	end
	hrp.CFrame = part.CFrame
end

local function teleportUp(hrp)
	print("[AutoLock] Teleporting player up 10 studs.")
	hrp.CFrame = hrp.CFrame + Vector3.new(0, 10, 0)
end

local function restorePosition(hrp, savedCFrame)
	print("[AutoLock] Restoring player position.")
	hrp.CFrame = savedCFrame
end

local function waitForCharacter()
	print("[AutoLock] Waiting for character and HumanoidRootPart...")
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		print("[AutoLock] Character and HumanoidRootPart found.")
		return character, character:FindFirstChild("HumanoidRootPart")
	end
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	print("[AutoLock] Character and HumanoidRootPart ready.")
	return character, hrp
end

local function sendNotification(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 4
		})
	end)
end

local function autoLock()
	print("[AutoLock] Starting autoLock routine...")
	local success, err = pcall(function()
		local baseModel = findPlayerBase()
		if not baseModel then
			print("[AutoLock] ERROR: Could not find player base.")
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local touchPart = getTouchPart(baseModel)
		if not touchPart then
			print("[AutoLock] ERROR: Could not find TouchPart or ButtonPosition.")
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local timeLabel = getTimeLabel(touchPart)
		if not timeLabel then
			print("[AutoLock] ERROR: Could not find TimeLabel.")
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local _, hrp = waitForCharacter()
		if not hrp then
			print("[AutoLock] ERROR: Could not find HumanoidRootPart.")
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local savedCFrame = hrp.CFrame
		local teleported = false
		local timeout = 5
		local startTime = tick()
		local lastTeleportTime = 0
		local function isLocked()
			return timeLabel.Text == "0:00"
		end
		print("[AutoLock] Lock state:", isLocked() and "LOCKED" or "UNLOCKED")
		-- Check immediately on start
		if isLocked() then
			print("[AutoLock] Initial lock detected, teleporting...")
			teleportTo(touchPart)
			teleported = true
			lastTeleportTime = tick()
		end
		while isLocked() and tick() - startTime < timeout do
			print("[AutoLock] Still locked, time:", timeLabel.Text)
			if not teleported then
				print("[AutoLock] Teleporting to TouchPart...")
				teleportTo(touchPart)
				teleported = true
				lastTeleportTime = tick()
			else
				if tick() - lastTeleportTime > 1 then
					print("[AutoLock] Lock stuck, teleporting up and retrying...")
					teleportUp(hrp)
					RunService.Heartbeat:Wait()
					teleportTo(touchPart)
					lastTeleportTime = tick()
				end
			end
			RunService.Heartbeat:Wait()
		end
		print("[AutoLock] Lock released or timeout, restoring position.")
		restorePosition(hrp, savedCFrame)
	end)
	if not success then
		print("[AutoLock] ERROR: Exception in autoLock routine:", err)
		sendNotification("Auto Lock (SAB)", "Failed to run\nDESCRIPTION: There was an error\nby Kevin")
	end
end

-- Event-driven and periodic check for best accuracy
local running = false
local function loopAutoLock()
	if running then return end
	running = true
	autoLock()
	running = false
end



print("[AutoLock] Script started. Sending notification.")
sendNotification("Auto Lock (SAB)", "by Kevin")
loopAutoLock()


LocalPlayer.CharacterAdded:Connect(function()
	print("[AutoLock] Character respawned. Running autoLock.")
	loopAutoLock()
end)



local lastSafetyCheck = tick()
while true do
	print("[AutoLock] Loop tick.")
	loopAutoLock()
	if tick() - lastSafetyCheck >= 0.3 then
		lastSafetyCheck = tick()
		print("[AutoLock] Safety timer check.")
		-- Safety logic can be added here if needed (e.g., force restore, error notification, etc.)
	end
	wait(0.2)
end