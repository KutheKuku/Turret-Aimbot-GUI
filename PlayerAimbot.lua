-- Place in StarterPlayer > StarterPlayerScripts as LocalScript
-- PRISON LIFE AIMBOT - WORKING SILENT AIM

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
	silentAim = false,
	lockedTarget = nil,
	isLocked = false
}

print("🔧 Prison Life Aimbot initialized")

-- Get nearest ENEMY player (NOT self)
local function getNearestEnemy()
	local nearest = nil
	local nearestDist = settings.range
	
	for _, p in pairs(Players:GetPlayers()) do
		-- Don't lock on self
		if p ~= player and p.Character then
			-- Make sure they have Head and Humanoid
			if p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
				local humanoid = p.Character.Humanoid
				if humanoid.Health > 0 then
					local head = p.Character.Head
					local dist = (head.Position - camera.CFrame.Position).Magnitude
					
					if dist < nearestDist then
						nearest = head
						nearestDist = dist
					end
				end
			end
		end
	end
	
	return nearest
end

-- Check if target is in FOV
local function isInFOV(target)
	if not target or not target.Parent then return false end
	local cameraPos = camera.CFrame.Position
	local targetPos = target.Position
	local direction = (targetPos - cameraPos).Unit
	local cameraLook = camera.CFrame.LookVector
	local angle = math.deg(math.acos(math.clamp(direction:Dot(cameraLook), -1, 1)))
	return angle < (settings.fov / 2)
end

-- Line of sight check
local function hasLineOfSight(target)
	if not target or not target.Parent then return false end
	local cameraPos = camera.CFrame.Position
	local targetPos = target.Position
	local direction = targetPos - cameraPos
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {player.Character}
	
	local rayResult = Workspace:Raycast(cameraPos, direction.Unit * 500, params)
	
	if rayResult == nil then
		return true
	end
	
	-- Check if ray hit the target or its parent
	if rayResult.Instance:IsDescendantOf(target.Parent) then
		return true
	end
	
	return false
end

-- SILENT AIM - Move mouse to target head
local function silentAim(target)
	if not target or not target.Parent then return end
	if not settings.enabled or not settings.silentAim then return end
	if not hasLineOfSight(target) or not isInFOV(target) then return end
	
	-- Get screen position of target head
	local screenPos = camera:WorldToScreenPoint(target.Position)
	
	-- Move mouse to target
	mouse.X = screenPos.X
	mouse.Y = screenPos.Y
end

-- E key to toggle lock
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.E then
		settings.isLocked = not settings.isLocked
		
		if settings.isLocked then
			settings.lockedTarget = getNearestEnemy()
			if settings.lockedTarget then
				print("🎯 LOCKED: " .. settings.lockedTarget.Parent.Name)
			else
				print("❌ No enemy found in range!")
				settings.isLocked = false
			end
		else
			print("🔓 UNLOCKED")
			settings.lockedTarget = nil
		end
	end
end)

-- Main silent aim loop
RunService.RenderStepped:Connect(function()
	if not settings.isLocked or not settings.lockedTarget then return end
	
	local target = settings.lockedTarget
	
	-- Check if target still exists
	if target and target.Parent then
		local humanoid = target.Parent:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			silentAim(target)
		else
			settings.isLocked = false
			settings.lockedTarget = nil
		end
	else
		settings.isLocked = false
		settings.lockedTarget = nil
	end
end)

-- ==================== FOV CIRCLE VISUAL ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrisonAimbotGui"
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

-- Update FOV circle
RunService.RenderStepped:Connect(function()
	local screenSize = screenGui.AbsoluteSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2
	
	local radius = (settings.fov / 180) * 200
	fovCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
	fovCircle.Position = UDim2.new(0, centerX - radius, 0, centerY - radius)
	
	-- Color based on lock status
	if settings.isLocked and settings.lockedTarget and settings.lockedTarget.Parent then
		fovStroke.Color = Color3.fromRGB(255, 0, 0)
		fovStroke.Transparency = 0.2
	else
		fovStroke.Color = Color3.fromRGB(0, 255, 100)
		fovStroke.Transparency = 0.3
	end
end)

-- ==================== CONTROL PANEL GUI ====================

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.new(0, 250, 0, 200)
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
title.Text = "PRISON AIMBOT"
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
		panel.Size = UDim2.new(0, 250, 0, 200)
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
	toggleCorner.CornerRadius = UDim.new(0, 3)
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
makeToggle("Silent Aim", "silentAim")
makeSlider("Range", "range", 10, 500)
makeSlider("FOV", "fov", 10, 180)

-- Info
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 50)
info.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
info.TextColor3 = Color3.fromRGB(180, 180, 180)
info.TextSize = 9
info.Font = Enum.Font.Gotham
info.Text = "🔑 Press E = LOCK/UNLOCK\n🎯 Turn ON Silent Aim + Shoot"
info.TextWrapped = true
info.BorderSizePixel = 0
info.Parent = content

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 4)
infoCorner.Parent = info

print("✅ Prison Life Aimbot loaded - Press E to lock!")
