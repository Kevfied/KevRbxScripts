local StarterGui = game:GetService("StarterGui")

local function makeInstant(prompt)
	if prompt:IsA("ProximityPrompt") then
		prompt.HoldDuration = 0
		print("Instant prompt:", prompt.Name)
	end
end

for _, prompt in ipairs(workspace:GetDescendants()) do
	makeInstant(prompt)
end

workspace.DescendantAdded:Connect(function(descendant)
	makeInstant(descendant)
end)

task.spawn(function()
	while true do
		for _, prompt in ipairs(workspace:GetDescendants()) do
			makeInstant(prompt)
		end
		task.wait(60)
	end
end)

StarterGui:SetCore("SendNotification", {
	Title = "Instant Prompts ✅",
	Text = "by Kevin",
	Duration = 5
})
