local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- CONFIGURATION
local Config = {
    Name = "CHEESE WARE",
    Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        Header = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(100, 100, 100),
        Highlight = Color3.fromRGB(255, 165, 0), -- Cheese Orange
        Enabled = Color3.fromRGB(50, 255, 50),
        Disabled = Color3.fromRGB(150, 150, 150),
        EnemyColor = Color3.fromRGB(255, 50, 50),
        FriendlyColor = Color3.fromRGB(50, 150, 255),
        WallColor = Color3.fromRGB(255, 255, 255),
        NoWallColor = Color3.fromRGB(100, 100, 100),
        FOVColor = Color3.fromRGB(255, 255, 255)
    },
    Aimbot: {
        Enabled = true,
        Smoothness = 0.1,
        FieldOfView = 2000, -- Max distance in studs
        FOVRadius = 200, -- Radius in pixels for the visual circle
        ShowFOV = true, -- NEW: Toggle FOV visibility
        TargetTeam = true,
        IgnoreFriends = true,
        WallCheck = true -- NEW: Raycast check before aiming
    },
    ESP: {
        Enabled = true,
        Box = true,
        HealthBar = true,
        Distance = true,
        Name = true,
        WallCheck = false -- Separate from Aimbot
    },
    Movement: {
        Fly = false,
        NoClip = false,
        Speed = 16
    },
    CustomColors: {
        FOV = Color3.fromRGB(255, 255, 255),
        ESPEnemy = Color3.fromRGB(255, 50, 50),
        ESPFriendly = Color3.fromRGB(50, 150, 255),
        ESPHealth = Color3.fromRGB(50, 255, 50)
    }
}

-- STATE MANAGEMENT
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Camera or Workspace.CurrentCamera

-- Drawing API
local DrawingAPI = {}

function DrawingAPI:new(type, parent)
    local obj = Drawing.new(type)
    if parent then obj.Parent = parent end
    return obj
end

-- UI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheeseWareUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Main Window
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 300, 0, 500) -- Taller for new options
Window.Position = UDim2.new(0.5, -150, 0.1, 10)
Window.BackgroundColor3 = Config.Theme.Background
Window.BorderSizePixel = 0
Window.Parent = ScreenGui

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Config.Theme.Header
Header.BorderSizePixel = 0
Header.Parent = Window

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = Config.Name
Title.TextColor3 = Config.Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Header

-- Options Container
local OptionsContainer = Instance.new("ScrollingFrame")
OptionsContainer.Name = "OptionsContainer"
OptionsContainer.Size = UDim2.new(1, 0, 1, -30)
OptionsContainer.BackgroundTransparency = 1
OptionsContainer.Position = UDim2.new(0, 0, 0, 30)
OptionsContainer.Parent = Window
OptionsContainer.ScrollBarThickness = 4
OptionsContainer.ScrollBarImageColor3 = Config.Theme.Accident

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Vertical
Layout.Parent = OptionsContainer
Layout.Padding = UDim.new(0, 4)

-- Helper: Create Toggle with Status Bar
local function CreateToggle(label, initial, parent)
    local Button = Instance.new("TextButton")
    Button.Name = "Toggle_" .. label
    Button.Size = UDim2.new(1, -10, 0, 25)
    Button.BackgroundColor3 = Config.Theme.Header
    Button.BorderSizePixel = 0
    Button.Text = label .. " : " .. (initial and "ON" or "OFF")
    Button.TextColor3 = initial and Config.Theme.Enabled or Config.Theme.Disabled
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 11
    Button.Parent = parent

    local state = initial
    
    -- Status Bar (Visual Feedback)
    local Status = Instance.new("Frame")
    Status.Name = "Status"
    Status.Size = UDim2.new(1, 0, 0, 2)
    Status.Position = UDim2.new(0, 0, 1, 2)
    Status.BackgroundColor3 = initial and Config.Theme.Enabled or Config.Theme.Disabled
    Status.BorderSizePixel = 0
    Status.Parent = Button

    function Button:Toggle()
        state = not state
        self.Text = label .. " : " .. (state and "ON" or "OFF")
        self.TextColor3 = state and Config.Theme.Enabled or Config.Theme.Disabled
        Status.BackgroundColor3 = state and Config.Theme.Enabled or Config.Theme.Disabled
        return state
    end

    function Button:GetState() return state end

    Button.MouseButton1Click:Connect(function()
        Button:Toggle()
    end)

    return Button
end

-- Helper: Create Slider
local function CreateSlider(label, min, max, initial, parent, callback)
    local Slider = Instance.new("TextButton")
    Slider.Name = "Slider_" .. label
    Slider.Size = UDim2.new(1, -10, 0, 25)
    Slider.BackgroundColor3 = Config.Theme.Header
    Slider.BorderSizePixel = 0
    Slider.Text = string.format("%s: %.1f", label, initial)
    Slider.TextColor3 = Config.Theme.Text
    Slider.Font = Enum.Font.Gotham
    Slider.TextSize = 11
    Slider.Parent = parent

    local value = initial
    function Slider:Update(newVal)
        value = math.clamp(newVal, min, max)
        self.Text = string.format("%s: %.1f", label, value)
        if callback then callback(value) end
    end

    Slider.MouseButton1Down:Connect(function()
        local startMouse = UserInputService:GetMouseLocation()
        local startVal = value
        local mouseMoved = false

        local connection = RunService.RenderStepped:Connect(function()
            local currentMouse = UserInputService:GetMouseLocation()
            if currentMouse.X ~= startMouse.X then
                mouseMoved = true
                local delta = currentMouse.X - startMouse.X
                local range = max - min
                local change = (delta / 100) * range
                value = math.clamp(startVal + change, min, max)
                Slider:Update(value)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)

    Slider.GetValue = function() return value end
    return Slider
end

-- Helper: Create Color Picker (Simple)
local function CreateColorPicker(label, initialColor, parent, callback)
    local Button = Instance.new("TextButton")
    Button.Name = "Color_" .. label
    Button.Size = UDim2.new(1, -10, 0, 25)
    Button.BackgroundColor3 = initialColor
    Button.BorderSizePixel = 0
    Button.Text = label
    Button.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text for contrast
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 11
    Button.Parent = parent

    local color = initialColor

    Button.MouseButton1Click:Connect(function()
        -- Cycle through a few preset colors for simplicity
        local colors = {
            Color3.fromRGB(255, 255, 255), -- White
            Color3.fromRGB(255, 0, 0),     -- Red
            Color3.fromRGB(0, 255, 0),     -- Green
            Color3.fromRGB(0, 0, 255),     -- Blue
            Color3.fromRGB(255, 255, 0),   -- Yellow
            Color3.fromRGB(255, 0, 255),   -- Magenta
            Color3.fromRGB(0, 255, 255),   -- Cyan
            Color3.fromRGB(128, 128, 128)  -- Grey
        }
        
        local currentIndex = 1
        for i, c in ipairs(colors) do
            if c == color then
                currentIndex = i
                break
            end
        end
        
        local nextIndex = (currentIndex % #colors) + 1
        color = colors[nextIndex]
        Button.BackgroundColor3 = color
        callback(color)
    end)

    return Button
end

-- UI ELEMENTS
-- Main Toggles
local EspToggle = CreateToggle("ESP", Config.ESP.Enabled, OptionsContainer)
local AimToggle = CreateToggle("Aimbot", Config.Aimbot.Enabled, OptionsContainer)
local WallToggle = CreateToggle("Wall Check (Aim)", Config.Aimbot.WallCheck, OptionsContainer)
local FlyToggle = CreateToggle("Fly", Config.Movement.Fly, OptionsContainer)
local NoClipToggle = CreateToggle("NoClip", Config.Movement.NoClip, OptionsContainer)

-- Aimbot Options
local AimSlider = CreateSlider("Aim Smooth", 0.01, 0.9, 0.1, OptionsContainer, function(v)
    Config.Aimbot.Smoothness = v
end)

local FOVSlider = CreateSlider("FOV Radius", 50, 500, 200, OptionsContainer, function(v)
    Config.Aimbot.FOVRadius = v
end)

local ShowFOVToggle = CreateToggle("Show FOV", Config.Aimbot.ShowFOV, OptionsContainer) -- NEW

-- Speed Slider
local SpeedSlider = CreateSlider("Speed", 16, 100, 16, OptionsContainer, function(v)
    Config.Movement.Speed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

-- Color Pickers
local FOVColorPicker = CreateColorPicker("FOV Color", Config.CustomColors.FOV, OptionsContainer, function(c)
    Config.CustomColors.FOV = c
end)

local ESPEnemyColorPicker = CreateColorPicker("ESP Enemy Color", Config.CustomColors.ESPEnemy, OptionsContainer, function(c)
    Config.CustomColors.ESPEnemy = c
end)

local ESPFriendlyColorPicker = CreateColorPicker("ESP Friendly Color", Config.CustomColors.ESPFriendly, OptionsContainer, function(c)
    Config.CustomColors.ESPFriendly = c
end)

local ESPHealthColorPicker = CreateColorPicker("ESP Health Color", Config.CustomColors.ESPHealth, OptionsContainer, function(c)
    Config.CustomColors.ESPHealth = c
end)

-- NEW: Config System
local SaveConfigButton = Instance.new("TextButton")
SaveConfigButton.Name = "SaveConfig"
SaveConfigButton.Size = UDim2.new(1, -10, 0, 25)
SaveConfigButton.BackgroundColor3 = Config.Theme.Header
SaveConfigButton.BorderSizePixel = 0
SaveConfigButton.Text = "Save Current Config"
SaveConfigButton.TextColor3 = Config.Theme.Text
SaveConfigButton.Font = Enum.Font.Gotham
SaveConfigButton.TextSize = 11
SaveConfigButton.Parent = OptionsContainer

local LoadConfigButton = Instance.new("TextButton")
LoadConfigButton.Name = "LoadConfig"
LoadConfigButton.Size = UDim2.new(1, -10, 0, 25)
LoadConfigButton.BackgroundColor3 = Config.Theme.Header
LoadConfigButton.BorderSizePixel = 0
LoadConfigButton.Text = "Load Saved Config"
LoadConfigButton.TextColor3 = Config.Theme.Text
LoadConfigButton.Font = Enum.Font.Gotham
LoadConfigButton.TextSize = 11
LoadConfigButton.Parent = OptionsContainer

local AutoloadToggle = CreateToggle("Autoload Config", false, OptionsContainer) -- Default to false

-- Helper to save a snapshot of the current config
local function GetCurrentConfig()
    return {
        Aimbot = {
            Enabled = Config.Aimbot.Enabled,
            Smoothness = Config.Aimbot.Smoothness,
            FOVRadius = Config.Aimbot.FOVRadius,
            ShowFOV = Config.Aimbot.ShowFOV,
            WallCheck = Config.Aimbot.WallCheck
        },
        ESP = {
            Enabled = Config.ESP.Enabled,
            WallCheck = Config.ESP.WallCheck
        },
        Movement = {
            Fly = Config.Movement.Fly,
            NoClip = Config.Movement.NoClip,
            Speed = Config.Movement.Speed
        },
        CustomColors = {
            FOV = Config.CustomColors.FOV,
            ESPEnemy = Config.CustomColors.ESPEnemy,
            ESPFriendly = Config.CustomColors.ESPFriendly,
            ESPHealth = Config.CustomColors.ESPHealth
        }
    }
end

-- Helper to apply a saved config
local function ApplyConfig(savedConfig)
    if not savedConfig then return end
    
    if savedConfig.Aimbot then
        Config.Aimbot.Enabled = savedConfig.Aimbot.Enabled
        Config.Aimbot.Smoothness = savedConfig.Aimbot.Smoothness
        Config.Aimbot.FOVRadius = savedConfig.Aimbot.FOVRadius
        Config.Aimbot.ShowFOV = savedConfig.Aimbot.ShowFOV
        Config.Aimbot.WallCheck = savedConfig.Aimbot.WallCheck
    end
    
    if savedConfig.ESP then
        Config.ESP.Enabled = savedConfig.ESP.Enabled
        Config.ESP.WallCheck = savedConfig.ESP.WallCheck
    end
    
    if savedConfig.Movement then
        Config.Movement.Fly = savedConfig.Movement.Fly
        Config.Movement.NoClip = savedConfig.Movement.NoClip
        Config.Movement.Speed = savedConfig.Movement.Speed
    end
    
    if savedConfig.CustomColors then
        Config.CustomColors.FOV = savedConfig.CustomColors.FOV
        Config.CustomColors.ESPEnemy = savedConfig.CustomColors.ESPEnemy
        Config.CustomColors.ESPFriendly = savedConfig.CustomColors.ESPFriendly
        Config.CustomColors.ESPHealth = savedConfig.CustomColors.ESPHealth
    end

    -- Update UI elements to reflect loaded config
    EspToggle:Toggle() -- Force update
    AimToggle:Toggle()
    WallToggle:Toggle()
    FlyToggle:Toggle()
    NoClipToggle:Toggle()
    ShowFOVToggle:Toggle()
    AutoloadToggle:Toggle()
    
    -- Update sliders
    AimSlider:Update(Config.Aimbot.Smoothness)
    FOVSlider:Update(Config.Aimbot.FOVRadius)
    SpeedSlider:Update(Config.Movement.Speed)
    
    -- Update color pickers
    FOVColorPicker.BackgroundColor3 = Config.CustomColors.FOV
    ESPEnemyColorPicker.BackgroundColor3 = Config.CustomColors.ESPEnemy
    ESPFriendlyColorPicker.BackgroundColor3 = Config.CustomColors.ESPFriendly
    ESPHealthColorPicker.BackgroundColor3 = Config.CustomColors.ESPHealth

    -- Apply movement logic immediately
    ApplyFly(Config.Movement.Fly)
    ApplyNoClip(Config.Movement.NoClip)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.Movement.Speed
    end
end

-- Event Connections for Config
local savedConfig = nil

SaveConfigButton.MouseButton1Click:Connect(function()
    savedConfig = GetCurrentConfig()
    -- Visual feedback
    local originalText = SaveConfigButton.Text
    SaveConfigButton.Text = "Saved!"
    wait(1)
    SaveConfigButton.Text = originalText
end)

LoadConfigButton.MouseButton1Click:Connect(function()
    if savedConfig then
        ApplyConfig(savedConfig)
        local originalText = LoadConfigButton.Text
        LoadConfigButton.Text = "Loaded!"
        wait(1)
        LoadConfigButton.Text = originalText
    else
        local originalText = LoadConfigButton.Text
        LoadConfigButton.Text = "No Config Saved"
        wait(1)
        LoadConfigButton.Text = originalText
    end
end)

AutoloadToggle.MouseButton1Click:Connect(function()
    if AutoloadToggle:GetState() and savedConfig then
        ApplyConfig(savedConfig)
    end
end)

-- Event Connections for Main Toggles
EspToggle.MouseButton1Click:Connect(function() 
    Config.ESP.Enabled = EspToggle:GetState() 
end)

AimToggle.MouseButton1Click:Connect(function() 
    Config.Aimbot.Enabled = AimToggle:GetState() 
end)

WallToggle.MouseButton1Click:Connect(function() 
    Config.Aimbot.WallCheck = WallToggle:GetState() 
end)

FlyToggle.MouseButton1Click:Connect(function() 
    Config.Movement.Fly = FlyToggle:GetState()
    ApplyFly(Config.Movement.Fly)
end)

NoClipToggle.MouseButton1Click:Connect(function() 
    Config.Movement.NoClip = NoClipToggle:GetState()
    ApplyNoClip(Config.Movement.NoClip)
end)

ShowFOVToggle.MouseButton1Click:Connect(function() 
    Config.Aimbot.ShowFOV = ShowFOVToggle:GetState()
end)

-- FLY & NOCLIP LOGIC
local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChild("Humanoid")
local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

function ApplyNoClip(enable)
    if not Character then return end
    for _, part in pairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enable
        end
    end
end

local FlyBodyVelocity = nil
local FlyConnection = nil

function ApplyFly(enable)
    if enable then
        if not RootPart then return end
        
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.Name = "CheeseWareFly"
        FlyBodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.Parent = RootPart
        
        RootPart.Anchored = true
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            local camCFrame = Camera.CFrame
            local camDir = camCFrame.LookVector
            local camRight = camCFrame.RightVector
            
            local fwd = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then fwd = 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then fwd = -1 end
            
            local rt = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then rt = -1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then rt = 1 end
            
            local up = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then up = 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = -1 end
            
            local speed = Config.Movement.Speed * 2
            
            FlyBodyVelocity.Velocity = (camDir * fwd + camRight * rt + Vector3.new(0, up, 0)) * speed
        end)
    else
        if FlyBodyVelocity then
            FlyBodyVelocity:Destroy()
            FlyBodyVelocity = nil
        end
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if RootPart then
            RootPart.Anchored = false
        end
    end
end

-- ESP & WALL CHECK LOGIC (For ESP Box)
local EspObjects = {}

function GetRaycastResult(origin, direction)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(origin, direction * 10000, params)
end

function UpdateESP()
    if not Config.ESP.Enabled then 
        -- Clear old
        for _, obj in pairs(EspObjects) do
            if obj.box then obj.box:Remove() end
            if obj.health then obj.health:Remove() end
            if obj.name then obj.name:Remove() end
            if obj.dist then obj.dist:Remove() end
        end
        EspObjects = {}
        return 
    end
    
    -- Clear old
    for _, obj in pairs(EspObjects) do
        if obj.box then obj.box:Remove() end
        if obj.health then obj.health:Remove() end
        if obj.name then obj.name:Remove() end
        if obj.dist then obj.dist:Remove() end
    end
    EspObjects = {}

    local localHead = Character and Character:FindFirstChild("Head")
    if not localHead then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local char = player.Character
        if not char or not char.Parent then continue end
        
        local head = char:FindFirstChild("Head")
        if not head then continue end
        
        -- FRIENDLY CHECK
        local isFriendly = false
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            isFriendly = true
        end
        
        -- Raycast for ESP Wall Check
        local visible = true
        if Config.ESP.WallCheck then
            local rayResult = GetRaycastResult(localHead.Position, (head.Position - localHead.Position))
            if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(char) then
                visible = false
            end
        end
        
        -- Create ESP Objects
        local screenPos = Camera:WorldToScreenPoint(head.Position)
        local dist = (head.Position - localHead.Position).Magnitude
        
        if screenPos.Z > 0 then continue end

        local box = DrawingAPI:new("Square", ScreenGui)
        box.Thickness = 1
        box.Filled = false
        
        local health = DrawingAPI:new("Square", ScreenGui)
        health.Thickness = 2
        health.Filled = true
        
        local nameTxt = DrawingAPI:new("Text", ScreenGui)
        nameTxt.Centered = true
        nameTxt.Outline = true
        
        local distTxt = DrawingAPI:new("Text", ScreenGui)
        distTxt.Centered = true
        distTxt.Outline = true

        EspObjects[player] = {
            box = box,
            health = health,
            name = nameTxt,
            dist = distTxt,
            head = head,
            friendly = isFriendly,
            visible = visible
        }
    end
end

function RenderESP()
    if not Config.ESP.Enabled then return end

    for player, data in pairs(EspObjects) do
        local head = data.head
        if not head.Parent then 
            data.box:Remove(); data.health:Remove(); data.name:Remove(); data.dist:Remove()
            EspObjects[player] = nil
            continue 
        end

        local screenPos = Camera:WorldToScreenPoint(head.Position)
        local dist = (head.Position - Character.Head.Position).Magnitude
        
        -- Wall Check Visibility for ESP Box
        if Config.ESP.WallCheck and not data.visible then
            data.box.Color = Config.Theme.NoWallColor
            data.box.Transparency = 0.5
        else
            data.box.Color = data.friendly and Config.CustomColors.ESPFriendly or Config.CustomColors.ESPEnemy
            data.box.Transparency = 0
        end

        local size = 40 + (600 / math.max(dist, 1))
        
        -- Box
        data.box.Position = Vector2.new(screenPos.X, screenPos.Y)
        data.box.Size = Vector2.new(size, size * 1.2)
        data.box.Visible = true

        -- Health Bar
        if Config.ESP.HealthBar then
            local hum = data.head.Parent:FindFirstChild("Humanoid")
            if hum then
                local hp = hum.Health
                local maxHp = hum.MaxHealth
                local ratio = hp / maxHp
                
                local hBarHeight = size * 0.8
                data.health.Position = Vector2.new(data.box.Position.X - size/2 - 10, data.box.Position.Y)
                data.health.Size = Vector2.new(5, hBarHeight)
                data.health.Color = ratio > 0.5 and Config.CustomColors.ESPHealth or Color3.fromRGB(255, 50, 50)
                data.health.Visible = true
            else
                data.health.Visible = false
            end
        else
            data.health.Visible = false
        end

        -- Name
        if Config.ESP.Name then
            data.name.Text = player.Name
            data.name.Position = Vector2.new(screenPos.X, data.box.Position.Y - size - 10)
            data.name.TextSize = 12
            data.name.Visible = true
        else
            data.name.Visible = false
        end

        -- Distance
        if Config.ESP.Distance then
            data.dist.Text = string.format("%.1fm", dist / 30)
            data.dist.Position = Vector2.new(screenPos.X, data.box.Position.Y + size + 5)
            data.dist.TextSize = 10
            data.dist.Visible = true
        else
            data.dist.Visible = false
        end
    end
end

-- AIMBOT LOGIC
local FOVCircle = DrawingAPI:new("Circle", ScreenGui)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Color = Config.Theme.FOVColor
FOVCircle.Transparency = 0.5

local function FindTarget()
    local closest = nil
    local minDist = math.huge
    local camPos = Camera.CFrame.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Friendly Check for Aim
        if Config.Aimbot.IgnoreFriends then
            local playerChar = player.Character
            local localChar = LocalPlayer.Character
            if playerChar and localChar and playerChar:FindFirstChild("Head") and localChar:FindFirstChild("Head") then
                local sameTeam = false
                if player.Team and LocalPlayer.Team then
                    sameTeam = player.Team == LocalPlayer.Team
                end
                if sameTeam then continue end
            end
        end

        local char = player.Character
        if not char or not char.Parent then continue end
        
        local head = char:FindFirstChild("Head")
        if not head then continue end

        local headPos = head.Position
        local dist = (headPos - camPos).Magnitude
        
        if dist < minDist and dist < Config.Aimbot.FieldOfView then
            minDist = dist
            closest = head
        end
    end
    return closest
end

local function AimLoop()
    if not Config.Aimbot.Enabled then 
        FOVCircle.Visible = Config.Aimbot.ShowFOV -- If aimbot is off, still show FOV if enabled
        return 
    end
    
    FOVCircle.Visible = Config.Aimbot.ShowFOV
    
    if FOVCircle.Visible then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = Config.Aimbot.FOVRadius
        FOVCircle.Color = Config.CustomColors.FOV
    end

    local targetHead = FindTarget()
    
    if targetHead then
        -- WALL CHECK FOR AIMBOT
        if Config.Aimbot.WallCheck then
            local camPos = Camera.CFrame.Position
            local rayOrigin = Camera.CFrame.p
            local rayDir = (targetHead.Position - rayOrigin).Unit
            local rayResult = Workspace:Raycast(rayOrigin, rayDir * 10000, RaycastParams.new())
            
            if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(targetHead.Parent) then
                -- Target is visible, allow aim
            else
                -- Target is behind a wall, don't aim
                return
            end
        end

        local screenPos = Camera:WorldToScreenPoint(targetHead.Position)
        if screenPos.Z > 0 then return end

        local targetX = screenPos.X
        local targetY = screenPos.Y
        local currentX, currentY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
        
        local dx = targetX - currentX
        local dy = targetY - currentY
        
        -- Apply smoothness
        UserInputService:GetMouse().X = currentX + (dx * Config.Aimbot.Smoothness)
        UserInputService:GetMouse().Y = currentY + (dy * Config.Aimbot.Smoothness)
    else
        if Config.Aimbot.ShowFOV then
            FOVCircle.Visible = true
        end
    end
end

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
    UpdateESP()
    RenderESP()
    AimLoop()
end)

-- NEW: Right Shift to Toggle UI
local UIVisible = false -- Start hidden

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- Don't toggle if typing in chat
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        UIVisible = not UIVisible
        ScreenGui.Enabled = UIVisible
    end
end)

-- Cleanup
game:GetService("Debris"):AddItem(ScreenGui, 1e9)

print("Cheese Ware Loaded. v1.4 - Right Shift to Toggle UI")