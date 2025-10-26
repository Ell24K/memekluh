local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().SilentAimEnabled = true
getgenv().SilentAimFOV = 150
getgenv().TargetPart = "Head"

local function NotBehindWall(targetPart)
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")) then return false end
    if not targetPart then return false end
    local origin = LocalPlayer.Character.Head.Position
    local direction = (targetPart.Position - origin).Unit * 300
    local ray = Ray.new(origin, direction)
    local ignoreList = {LocalPlayer.Character}
    local part = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    if part then
        local humanoid = part.Parent:FindFirstChildOfClass("Humanoid") or (part.Parent.Parent and part.Parent.Parent:FindFirstChildOfClass("Humanoid"))
        if humanoid and humanoid.Parent == targetPart.Parent then
            return true
        end
    end
    return false
end

local function GetClosestToCursor()
    if not getgenv().SilentAimEnabled then return nil end
    local targetPart = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local part = player.Character:FindFirstChild(getgenv().TargetPart)
            if humanoid and humanoid.Health > 0 and part and player.Team ~= LocalPlayer.Team then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDistance and dist <= getgenv().SilentAimFOV and NotBehindWall(part) then
                        shortestDistance = dist
                        targetPart = part
                    end
                end
            end
        end
    end
    return targetPart
end

local gmt = getrawmetatable(game)
setreadonly(gmt, false)
local oldNamecall = gmt.__namecall
gmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if tostring(self) == "HitPart" and method == "FireServer" and getgenv().SilentAimEnabled then
        local target = GetClosestToCursor()
        if target then
            args[1] = target
            args[2] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Color = Color3.fromRGB(0, 255, 150)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = getgenv().SilentAimFOV
FOVCircle.Filled = false

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y + 36)
    FOVCircle.Visible = getgenv().SilentAimEnabled
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Text = "Silent Aim: ON"
ToggleBtn.Size = UDim2.new(0, 150, 0, 50)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = true

local dragging = false
local dragInput, mousePos, framePos

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = ToggleBtn.Position
    end
end)

ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        ToggleBtn.Position = UDim2.new(
            framePos.X.Scale, framePos.X.Offset + delta.X,
            framePos.Y.Scale, framePos.Y.Offset + delta.Y
        )
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().SilentAimEnabled = not getgenv().SilentAimEnabled
    if getgenv().SilentAimEnabled then
        ToggleBtn.Text = "Silent Aim: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    else
        ToggleBtn.Text = "Silent Aim: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)