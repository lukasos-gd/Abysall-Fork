local TweenService = game:GetService("TweenService")

local Splash = {}
Splash.__index = Splash

local function GetParent()
    local Success, Result = pcall(function()
        return gethui()
    end)
    if Success and Result then
        return Result
    end
    local CoreSuccess, CoreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if CoreSuccess and CoreGui then
        return CoreGui
    end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

function Splash.new()
    local self = setmetatable({}, Splash)

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "AbysallSplash"
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.DisplayOrder = 32767
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Group = Instance.new("CanvasGroup")
    Group.AnchorPoint = Vector2.new(0.5, 0.5)
    Group.Position = UDim2.fromScale(0.5, 0.5)
    Group.Size = UDim2.fromOffset(280, 92)
    Group.BackgroundColor3 = Color3.fromRGB(11, 18, 32)
    Group.GroupTransparency = 1
    Group.BorderSizePixel = 0
    Group.Parent = Gui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 14)
    Corner.Parent = Group

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(61, 220, 255)
    Stroke.Transparency = 0.6
    Stroke.Parent = Group

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.fromOffset(16, 12)
    Title.Size = UDim2.new(1, -32, 0, 22)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "Abysall Fork"
    Title.TextColor3 = Color3.fromRGB(232, 241, 255)
    Title.TextSize = 17
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Group

    local Status = Instance.new("TextLabel")
    Status.BackgroundTransparency = 1
    Status.Position = UDim2.fromOffset(16, 38)
    Status.Size = UDim2.new(1, -32, 0, 18)
    Status.Font = Enum.Font.Gotham
    Status.Text = "Starting"
    Status.TextColor3 = Color3.fromRGB(150, 170, 200)
    Status.TextSize = 12
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Group

    local Track = Instance.new("Frame")
    Track.Position = UDim2.new(0, 16, 1, -22)
    Track.Size = UDim2.new(1, -32, 0, 4)
    Track.BackgroundColor3 = Color3.fromRGB(34, 49, 73)
    Track.BorderSizePixel = 0
    Track.Parent = Group

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.fromScale(0, 1)
    Fill.BackgroundColor3 = Color3.fromRGB(61, 220, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Parent = GetParent()
    local Success = pcall(function()
        Gui.Parent = Parent
    end)
    if not Success then
        Gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    self.Gui = Gui
    self.Group = Group
    self.Status = Status
    self.Fill = Fill
    self.Closed = false

    TweenService:Create(Group, TweenInfo.new(0.3), { GroupTransparency = 0 }):Play()

    task.delay(30, function()
        self:Close()
    end)

    return self
end

function Splash:Set(Progress, Text)
    if self.Closed then
        return
    end
    self.Status.Text = Text
    TweenService:Create(self.Fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.clamp(Progress, 0, 1), 1) }):Play()
end

function Splash:Close()
    if self.Closed then
        return
    end
    self.Closed = true
    self.Fill.Size = UDim2.fromScale(1, 1)
    local Tween = TweenService:Create(self.Group, TweenInfo.new(0.4), { GroupTransparency = 1 })
    Tween:Play()
    task.delay(0.45, function()
        self.Gui:Destroy()
    end)
end

return Splash
