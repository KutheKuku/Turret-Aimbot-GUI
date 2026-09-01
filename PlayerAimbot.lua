-- Place this in StarterPlayer > StarterPlayerScripts
-- Complete client-side aimbot with GUI in one script

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Default settings
local settings = {
	RANGE = 100,
	SMOOTH = 6,
	FOV = 100,
	AIM_ASSIST = false,
	ASSIST_STRENGTH = 0.5,
	SILENT_AIM = false,
	LOCK_KEY = Enum.KeyCode.E,
	LOCKED_PLAYER = nil,
	ENABLED = true
}

-- ==================== AIMBOT LOGIC ====================

local function getNearestTarget()
	local best, bestDist
	local cameraPos = Camera.CFrame.Position
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local targetPart = player.Character:FindFirstChild("Head")
			if targetPart then
				local dist = (targetPart.Position - cameraPos).Magnitude
				if dist <= settings.RANGE and (not bestDist or dist < bestDist) then
					best = targetPart
					bestDist = dist
				end
			end
		end
	end
	return best
end

local function hasLineOfSight(target)
	local origin = Camera.CFrame.Position
	local direction = target.Position - origin
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {localCharacter}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local result = Workspace:Raycast(origin, direction, params)
	return result == nil
end

local function isInFOV(target)
	local cameraPos = Camera.CFrame.Position
	local targetPos = target.Position
	local direction = (targetPos - cameraPos).Unit
	local cameraForward = Camera.CFrame.LookVector
	local angle = math.deg(math.acos(math.clamp(direction:Dot(cameraForward), -1, 1)))
	return angle <= settings.FOV / 2
end

local function aimAssist(target)
	if not settings.AIM_ASSIST or not target then return end
	
	local targetPos = target.Position
	local cameraPos = Camera.CFrame.Position
	local newCFrame = CFrame.new(cameraPos, targetPos)
	
	if settings.SILENT_AIM then
		_G.SilentAimTarget = newCFrame
	else
		local t = math.clamp(settings.ASSIST_STRENGTH, 0, 1)
		Camera.CFrame = Camera.CFrame:Lerp(newCFrame, t)
	end
end

-- Handle lock key press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == settings.LOCK_KEY and settings.ENABLED then
		settings.LOCKED_PLAYER = getNearestTarget()
	end
end)

-- Handle lock key release
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == settings.LOCK_KEY then
		settings.LOCKED_PLAYER = nil
	end
end)

-- Update character on respawn
localPlayer.CharacterAdded:Connect(function(character)
	localCharacter = character
end)

-- Main aimbot loop
RunService.Heartbeat:Connect(function(dt)
	if not settings.ENABLED then return end
	
	local target = settings.LOCKED_PLAYER or getNearestTarget()
	
	if target and hasLineOfSight(target) and isInFOV(target) then
		if settings.AIM_ASSIST then
			aimAssist(target)
		else
			local cameraPos = Camera.CFrame.Position
			local targetPos = target.Position
			local desired = CFrame.new(cameraPos, targetPos)
			local t = math.clamp(dt * settings.SMOOTH, 0, 1)
			Camera.CFrame = Camera.CFrame:Lerp(desired, t)
		end
	end
end)

-- ==================== GUI CREATION ====================

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main frame (minimizable)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 420)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(0.7, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 14
titleText.Font = Enum.Font.GothamBold
titleText.Text = "Aimbot"
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 30, 1, 0)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 14
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "−"
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar

local isMinimized = false

minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		mainFrame.Size = UDim2.new(0, 300, 0, 30)
		minimizeBtn.Text = "+"
		contentFrame.Visible = false
	else
		mainFrame.Size = UDim2.new(0, 300, 0, 420)
		minimizeBtn.Text = "−"
		contentFrame.Visible = true
	end
end)

-- Content frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- List layout for content
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = contentFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = contentFrame

-- ==================== GUI FUNCTIONS ====================

-- Function to create a slider control
local function createSlider(name, min, max, default, onChanged)
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.new(1, 0, 0, 50)
	container.BackgroundTransparency = 1
	container.Parent = contentFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.Text = name .. ": " .. tostring(math.floor(default))
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local slider = Instance.new("Frame")
	slider.Name = "Slider"
	slider.Size = UDim2.new(1, 0, 0, 6)
	slider.Position = UDim2.new(0, 0, 0, 25)
	slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	slider.BorderSizePixel = 0
	slider.Parent = container

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 3)
	sliderCorner.Parent = slider

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	fill.BorderSizePixel = 0
	fill.Parent = slider

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = fill

	local function updateSlider(inputSize)
		local ratio = math.clamp(inputSize.X / slider.AbsoluteSize.X, 0, 1)
		local newValue = min + (ratio * (max - min))
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		label.Text = name .. ": " .. tostring(math.floor(newValue))
		onChanged(newValue)
	end

	local dragging = false
	fill.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	fill.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	slider.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(slider.AbsoluteSize * (input.Position - slider.AbsolutePosition))
		end
	end)

	slider.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input, gameProcessed)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(slider.AbsoluteSize * (input.Position - slider.AbsolutePosition))
		end
	end)

	return container
end

-- Function to create a toggle button
local function createToggle(name, default, onToggled)
	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.new(1, 0, 0, 35)
	container.BackgroundTransparency = 1
	container.Parent = contentFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.Text = name
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.Size = UDim2.new(0, 40, 0, 25)
	toggle.Position = UDim2.new(1, -40, 0.5, -12.5)
	toggle.BackgroundColor3 = default and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(60, 60, 60)
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.TextSize = 10
	toggle.Font = Enum.Font.GothamBold
	toggle.Text = default and "ON" or "OFF"
	toggle.BorderSizePixel = 0
	toggle.Parent = container

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 5)
	toggleCorner.Parent = toggle

	local state = default

	toggle.MouseButton1Click:Connect(function()
		state = not state
		toggle.BackgroundColor3 = state and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(60, 60, 60)
		toggle.Text = state and "ON" or "OFF"
		onToggled(state)
	end)

	return container
end

-- ==================== CREATE GUI CONTROLS ====================

createToggle("Enable", settings.ENABLED, function(state)
	settings.ENABLED = state
end)

createSlider("Range", 10, 300, settings.RANGE, function(value)
	settings.RANGE = value
end)

createSlider("Smoothness", 1, 15, settings.SMOOTH, function(value)
	settings.SMOOTH = value
end)

createSlider("FOV", 10, 180, settings.FOV, function(value)
	settings.FOV = value
end)

createToggle("Aim Assist", settings.AIM_ASSIST, function(state)
	settings.AIM_ASSIST = state
end)

createToggle("Silent Aim", settings.SILENT_AIM, function(state)
	settings.SILENT_AIM = state
end)

createSlider("Assist Strength", 0, 1, settings.ASSIST_STRENGTH, function(value)
	settings.ASSIST_STRENGTH = value
end)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 50)
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Press E to lock onto nearest target\n(Hold E to maintain lock)"
statusLabel.TextWrapped = true
statusLabel.BorderSizePixel = 0
statusLabel.Parent = contentFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusLabel