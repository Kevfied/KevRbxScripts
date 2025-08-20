local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local BaseFolder = workspace:WaitForChild("Map"):WaitForChild("Bases")

local function findPlayerBase()
	for _, baseModel in ipairs(BaseFolder:GetChildren()) do
		if baseModel:IsA("Model") and baseModel.Name == "CloneBase" then
			local userId = baseModel:GetAttribute("userId")
			if userId and tonumber(userId) == LocalPlayer.UserId then
				return baseModel
			end
		end
	end
	return nil
end

local function getTouchPart(baseModel)
	local interactables = baseModel:FindFirstChild("Interactables")
	if not interactables or not interactables:IsA("Folder") then return nil end
	local laserButton = interactables:FindFirstChild("LaserButton")
	if not laserButton or not laserButton:IsA("Folder") then return nil end
	local touchPart = laserButton:FindFirstChild("TouchPart")
	if touchPart and touchPart:IsA("BasePart") then return touchPart end
	local buttonPosition = laserButton:FindFirstChild("ButtonPosition")
	if buttonPosition and buttonPosition:IsA("BasePart") then return buttonPosition end
	return nil
end

local function getTimeLabel(touchPart)
	local lockBillboard = touchPart:FindFirstChild("LockBillboard")
	if not lockBillboard then return nil end
	local frame = lockBillboard:FindFirstChild("Frame")
	if not frame then return nil end
	local timeLabel = frame:FindFirstChild("Time")
	if timeLabel and timeLabel:IsA("TextLabel") then return timeLabel end
	return nil
end

local function teleportTo(part)
	local character = LocalPlayer.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = part.CFrame
end

local function teleportUp(hrp)
	hrp.CFrame = hrp.CFrame + Vector3.new(0, 10, 0)
end

local function restorePosition(hrp, savedCFrame)
	hrp.CFrame = savedCFrame
end

local function waitForCharacter()
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		return character, character:FindFirstChild("HumanoidRootPart")
	end
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
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
	local success = pcall(function()
		local baseModel = findPlayerBase()
		if not baseModel then
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local touchPart = getTouchPart(baseModel)
		if not touchPart then
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local timeLabel = getTimeLabel(touchPart)
		if not timeLabel then
			sendNotification("Auto Lock (SAB)", "Failed to run\nby Kevin")
			return
		end
		local _, hrp = waitForCharacter()
		if not hrp then
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
		if isLocked() then
			teleportTo(touchPart)
			teleported = true
			lastTeleportTime = tick()
		end
		while isLocked() and tick() - startTime < timeout do
			if not teleported then
				teleportTo(touchPart)
				teleported = true
				lastTeleportTime = tick()
			else
				if tick() - lastTeleportTime > 1 then
					teleportUp(hrp)
					RunService.Heartbeat:Wait()
					teleportTo(touchPart)
					lastTeleportTime = tick()
				end
			end
			RunService.Heartbeat:Wait()
		end
		restorePosition(hrp, savedCFrame)
	end)
	if not success then
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


sendNotification("Auto Lock (SAB)", "by Kevin")
loopAutoLock()

LocalPlayer.CharacterAdded:Connect(loopAutoLock)

local lastSafetyCheck = tick()
while true do
	loopAutoLock()
	if tick() - lastSafetyCheck >= 0.3 then
		lastSafetyCheck = tick()
		-- Safety logic can be added here if needed
	end
	wait(0.2)
end