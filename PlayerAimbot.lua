-- Place this in StarterPlayer > StarterPlayerScripts as a LocalScript
-- AIMBOT WITH GUI - Everything in one script

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

-- Settings
local settings = {
	enabled = true,
	range = 100,
	fov = 120,
	smoothness = 0.1,
	aimAssist = false,
	silentAim = false,
	lockedTarget = nil
}

print("✓ Aimbot script loaded")

-- Get nearest player
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
	local angle = math.deg(math.acos(dot))
	return angle < settings.fov
end

-- Line of sight check
local function hasLineOfSight(target)
	if not target then return false end
	local ray = workspace:FindPartOnRay(Ray.new(camera.CFrame.Position, (target.Position - camera.CFrame.Position).Unit * 500))
	return ray == nil or ray.Parent == target.Parent
end

-- Aim at target
local function aimAtTarget(target)
	if not target or not settings.enabled then return end
	if not hasLineOfSight(target) or not isInFOV(target) then return end
	
	local targetPos = target.Position
	local newCFrame = CFrame.new(camera.CFrame.Position, targetPos)
	
	if settings.silentAim then
		-- Just store it without moving camera
		return
	end
	
	camera.CFrame = camera.CFrame:Lerp(newCFrame, settings.smoothness)
end

-- E key to lock
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		settings.lockedTarget = getNearestPlayer()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E then
		settings.lockedTarget = nil
	end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
	if not settings.enabled then return end
	
	local target = settings.lockedTarget or getNearestPlayer()
	if target and settings.aimAssist then
		aimAtTarget(target)
	end
end)

-- ==================== GUI ====================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main panel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 250, 0, 350)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 6)
panelCorner.Parent = panel

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 35)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.Text = "AIMBOT"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.Parent = title

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "−"
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

local isMinimized = false
closeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		panel.Size = UDim2.new(0, 250, 0, 35)
		closeBtn.Text = "+"
		content.Visible = false
	else
		panel.Size = UDim2.new(0, 250, 0, 350)
		closeBtn.Text = "−"
		content.Visible = true
	end
end)

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

-- Helper to make toggles
local function makeToggle(name, key, onChange)
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
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
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
		if onChange then onChange(settings[key]) end
		print("✓ " .. name .. ": " .. tostring(settings[key]))
	end)
	
	return container
end

-- Helper to make sliders
local function makeSlider(name, key, min, max, onChange)
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
		
		if onChange then onChange(value) end
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

-- Info text
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 40)
info.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
info.TextColor3 = Color3.fromRGB(180, 180, 180)
info.TextSize = 9
info.Font = Enum.Font.Gotham
info.Text = "Press E to lock target\nHold E to keep lock"
info.TextWrapped = true
info.BorderSizePixel = 0
info.Parent = content

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 4)
infoCorner.Parent = info

print("✓ GUI created successfully")
