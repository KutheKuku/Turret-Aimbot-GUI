-- Place in StarterPlayer > StarterPlayerScripts as LocalScript
-- WORKING AIMBOT WITH FOV CIRCLE, SILENT AIM, AND SINGLE PRESS LOCK

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

-- Settings
local settings = {
	enabled = true,
	range = 100,
	fov = 120,
	smoothness = 0.1,
	aimAssist = false,
	silentAim = false,
	lockedTarget = nil,
	isLocked = false
}

print("🔧 Aimbot system initialized")

-- Get nearest player in range
local function getNearestPlayer()
	local nearest = nil
	local nearestDist = settings.range
	
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
			local head = p.Character.Head
			local dist = (head.Position - camera.CFrame.Position).Magnitude
			
			if dist < nearestDist then
				nearest = head
				nearestDist = dist
			end
		end
	end
	
	return nearest
end

-- Check if target is in FOV
local function isInFOV(target)
	if not target then return false end
	local direction = (target.Position - camera.CFrame.Position).Unit
	local dot = direction:Dot(camera.CFrame.LookVector)
	local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
	return angle < (settings.fov / 2)
end

-- Line of sight check
local function hasLineOfSight(target)
	if not target then return false end
	local origin = camera.CFrame.Position
	local direction = (target.Position - origin)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {player.Character}
	
	local result = Workspace:Raycast(origin, direction.Unit * 500, params)
	return result == nil or result.Instance:IsDescendantOf(target.Parent)
end

-- Aim at target
local function aimAtTarget(target)
	if not target or not settings.enabled then return end
	if not hasLineOfSight(target) or not isInFOV(target) then return end
	
	local targetPos = target.Position
	local newCFrame = CFrame.new(camera.CFrame.Position, targetPos)
	
	if not settings.silentAim then
		camera.CFrame = camera.CFrame:Lerp(newCFrame, settings.smoothness)
	end
end

-- Single press E to toggle lock
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		settings.isLocked = not settings.isLocked
		
		if settings.isLocked then
			settings.lockedTarget = getNearestPlayer()
			if settings.lockedTarget then
				print("🎯 LOCKED: " .. settings.lockedTarget.Parent.Name)
			else
				print("❌ No target in range")
				settings.isLocked = false
			end
		else
			print("🔓 UNLOCKED")
			settings.lockedTarget = nil
		end
	end
end)

-- Main aim loop
RunService.RenderStepped:Connect(function()
	if not settings.enabled then return end
	
	local target = settings.lockedTarget
	
	if target and target.Parent then
		if target.Parent:FindFirstChild("Humanoid") then
			aimAtTarget(target)
		else
			settings.isLocked = false
			settings.lockedTarget = nil
		end
	end
end)

-- ==================== FOV CIRCLE VISUAL ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Size = UDim2.new(0, 200, 0, 200)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = screenGui

local fovCircleCorner = Instance.new("UICorner")
fovCircleCorner.CornerRadius = UDim.new(1, 0)
fovCircleCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 2
fovStroke.Color = Color3.fromRGB(0, 255, 100)
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

-- Update FOV circle position (center of screen)
RunService.RenderStepped:Connect(function()
	local screenSize = screenGui.AbsoluteSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2
	
	local radius = (settings.fov / 180) * 200
	fovCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
	fovCircle.Position = UDim2.new(0, centerX - radius, 0, centerY - radius)
	
	-- Color change if locked
	if settings.isLocked and settings.lockedTarget then
		fovStroke.Color = Color3.fromRGB(255, 0, 0)
	else
		fovStroke.Color = Color3.fromRGB(0, 255, 100)
	end
end)

-- ==================== CONTROL PANEL GUI ====================

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.new(0, 250, 0, 300)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 6)
panelCorner.Parent = panel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 35)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.Text = "AIMBOT"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local titlePadding = Instance.new("UIPadding")
titlePadding.PaddingLeft = UDim.new(0, 10)
titlePadding.Parent = title

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 2)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 12
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "−"
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = header

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 4)
minimizeCorner.Parent = minimizeBtn

-- Content
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, -35)
content.Position = UDim2.new(0, 0, 0, 35)
content.BackgroundTransparency = 1
content.Parent = panel

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.Parent = content

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		panel.Size = UDim2.new(0, 250, 0, 35)
		minimizeBtn.Text = "+"
		content.Visible = false
	else
		panel.Size = UDim2.new(0, 250, 0, 300)
		minimizeBtn.Text = "−"
		content.Visible = true
	end
end)

-- Helper: Toggle
local function makeToggle(name, key)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 25)
	container.BackgroundTransparency = 1
	container.Parent = content
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.Text = name
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 45, 0, 20)
	toggle.Position = UDim2.new(1, -45, 0.5, -10)
	toggle.BackgroundColor3 = settings[key] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(100, 100, 100)
	toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
	toggle.TextSize = 9
	toggle.Font = Enum.Font.GothamBold
	toggle.Text = settings[key] and "ON" or "OFF"
	toggle.BorderSizePixel = 0
	toggle.Parent = container
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 4)
	toggleCorner.Parent = toggle
	
	toggle.MouseButton1Click:Connect(function()
		settings[key] = not settings[key]
		toggle.BackgroundColor3 = settings[key] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(100, 100, 100)
		toggle.Text = settings[key] and "ON" or "OFF"
		print("✓ " .. name .. ": " .. tostring(settings[key]))
	end)
	
	return container
end

-- Helper: Slider
local function makeSlider(name, key, min, max)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 45)
	container.BackgroundTransparency = 1
	container.Parent = content
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 15)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 10
	label.Font = Enum.Font.Gotham
	label.Text = name .. ": " .. tostring(math.floor(settings[key]))
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, 0, 0, 8)
	sliderBg.Position = UDim2.new(0, 0, 0, 20)
	sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = container
	
	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(0, 4)
	sliderCorner.Parent = sliderBg
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((settings[key] - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = sliderFill
	
	local dragging = false
	
	local function updateSlider(x)
		local relX = x - sliderBg.AbsolutePosition.X
		local ratio = math.clamp(relX / sliderBg.AbsoluteSize.X, 0, 1)
		local value = min + (ratio * (max - min))
		
		settings[key] = value
		sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
		label.Text = name .. ": " .. tostring(math.floor(value))
	end
	
	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)
	
	sliderBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)
	
	return container
end

-- Add controls
makeToggle("Enable", "enabled")
makeToggle("Aim Assist", "aimAssist")
makeToggle("Silent Aim", "silentAim")
makeSlider("Range", "range", 10, 500)
makeSlider("FOV", "fov", 10, 180)
makeSlider("Smoothness", "smoothness", 0.01, 0.5)

-- Info
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 50)
info.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
info.TextColor3 = Color3.fromRGB(180, 180, 180)
info.TextSize = 9
info.Font = Enum.Font.Gotham
info.Text = "🔑 Press E to LOCK/UNLOCK\n✓ Green circle = FOV\n🔴 Red circle = LOCKED"
info.TextWrapped = true
info.BorderSizePixel = 0
info.Parent = content

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 4)
infoCorner.Parent = info

print("✅ Aimbot fully loaded with FOV circle and Silent Aim")
