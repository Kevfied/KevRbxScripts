-- LocalScript in StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local VehiclesFolder = workspace:WaitForChild("Vehicles")

-- Notification helper
local function notify(title, text, duration)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 2
		})
	end)
end

-- Max values
local MAX_FRICTION = 1e6
local MAX_WEIGHT = 1e6

-- Downforce settings
local DOWNFORCE_MULTIPLIER = 25 -- higher = more stick at speed

-- Anti-flip settings
local UPRIGHT_STRENGTH = 20000
local UPRIGHT_DAMPING = 200

-- Apply wheel friction buff
local function boostWheels(vehicle)
	local wheels = vehicle:FindFirstChild("Wheels")
	if not wheels then return false end

	for _, wheel in ipairs(wheels:GetDescendants()) do
		if wheel:IsA("BasePart") then
			local props = wheel.CustomPhysicalProperties or PhysicalProperties.new(
				wheel.Material, 0.7, 0.3, 1, 1, 1
			)
			local newProps = PhysicalProperties.new(
				props.Density,
				MAX_FRICTION,
				props.Elasticity,
				MAX_WEIGHT,
				props.ElasticityWeight
			)
			wheel.CustomPhysicalProperties = newProps
		end
	end
	return true
end

-- Add downforce + anti-flip onto the seat
local function applyExtras(car, seat)
	-- Downforce
	if not seat:FindFirstChild("DF_Att") then
		local att = Instance.new("Attachment")
		att.Name = "DF_Att"
		att.Parent = seat

		local vf = Instance.new("VectorForce")
		vf.Name = "Downforce"
		vf.RelativeTo = Enum.ActuatorRelativeTo.World
		vf.Attachment0 = att
		vf.Force = Vector3.zero
		vf.Parent = seat
	end

	-- Anti-flip gyro
	if not seat:FindFirstChild("AntiFlip") then
		local gy = Instance.new("BodyGyro")
		gy.Name = "AntiFlip"
		gy.MaxTorque = Vector3.new(UPRIGHT_STRENGTH, 0, UPRIGHT_STRENGTH)
		gy.D = UPRIGHT_DAMPING
		gy.P = UPRIGHT_STRENGTH
		gy.Parent = seat
	end

	-- Update forces
	local root = car.PrimaryPart or seat
	local velocity = root.AssemblyLinearVelocity
	local speed = velocity.Magnitude

	local df = seat:FindFirstChild("Downforce")
	if df then
		df.Force = Vector3.new(0, -speed * DOWNFORCE_MULTIPLIER, 0)
	end

	local anti = seat:FindFirstChild("AntiFlip")
	if anti then
		-- Keep car upright, but allow yaw (rotation left/right)
		local cf = root.CFrame
		local goalCF = CFrame.lookAt(cf.Position, cf.Position + cf.LookVector, Vector3.yAxis)
		anti.CFrame = goalCF
	end
end

-- Run every physics step
RunService.Heartbeat:Connect(function()
	local ok, err = pcall(function()
		for _, car in ipairs(VehiclesFolder:GetChildren()) do
			if car:IsA("Model") then
				local seat = car:FindFirstChild("DriveSeat")
				if seat and seat:IsA("VehicleSeat") and seat.Occupant then
					local humanoid = seat.Occupant
					local char = humanoid.Parent
					local plr = Players:GetPlayerFromCharacter(char)
					if plr == player then
						boostWheels(car)
						applyExtras(car, seat)
					end
				end
			end
		end
	end)

	if not ok then
		notify("Traction Booster Error", tostring(err), 3)
	end
end)
-- ] To Open And Close Gui
loadstring(game:HttpGet('https://raw.githubusercontent.com/Documantation12/Universal-Vehicle-Script/main/Main.lua'))()
notify("Traction Booster", "Running at max speed (Heartbeat)", 3)
