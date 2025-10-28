if not game.PlaceId ~= 105788818579323 then return end
if not game.Loaded then game.Loaded:Wait() end
-- // ===========================================================================================================================
-- // ===========================================================================================================================

local HelperFunctions = {}
local Game = game

local VisibilityIgnore = {}

local Workspace = Game.Workspace
local LocalPlayer = Game.Players.LocalPlayer

local Players = Game:GetService("Players")
local ReplicatedStorage = Game:GetService("ReplicatedStorage")

local TypeOf = typeof

local Camera = Workspace.CurrentCamera

local VisibilityRaycastParams = RaycastParams.new()
VisibilityRaycastParams.IgnoreWater = true
VisibilityRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
VisibilityRaycastParams.FilterDescendantsInstances = VisibilityIgnore

local ControllerModule = require(ReplicatedStorage.Modules.Controller)
-- // ===========================================================================================================================
-- // ===========================================================================================================================


-- // ===========================================================================================================================
-- // ===========================================================================================================================
function HelperFunctions:IsDowned(CharacterTarget)
    local Character = Workspace.Characters and Workspace.Characters:FindFirstChild(CharacterTarget)
    local Down = Character and Character:FindFirstChild("State") and Character.State:FindFirstChild("Down")

    return Down and Down.Value
end
-- // ===========================================================================================================================
function HelperFunctions:IsDead(CharacterTarget)
    local Character = Workspace.Characters and Workspace.Characters:FindFirstChild(CharacterTarget)
    local Dead = Character and Character:FindFirstChild("State") and Character.State:FindFirstChild("Dead")

    return Dead and Dead.Value
end
-- // ===========================================================================================================================
function HelperFunctions:IsFriends(CharacterTarget)
    local PlayerTarget = Players:FindFirstChild(CharacterTarget)

    return PlayerTarget and LocalPlayer:IsFriendsWith(PlayerTarget.UserId)
end
-- // ===========================================================================================================================
function HelperFunctions:IsCrew(CharacterTarget)
    local PlayerTarget = Players:FindFirstChild(CharacterTarget)

    return PlayerTarget and ControllerModule.CheckTeam(PlayerTarget, LocalPlayer)
end
-- // ===========================================================================================================================
function HelperFunctions:IsVisible(CharacterTarget)
    if not CharacterTarget then return false end

    local TargetCharacter = CharacterTarget
    local TargetType = TypeOf(CharacterTarget)

    if TargetType == "string" then
        local CharacterContainer = Workspace.Characters
        if not CharacterContainer then return false end

        TargetCharacter = CharacterContainer:FindFirstChild(CharacterTarget)
        if not TargetCharacter then return false end

    elseif TargetType ~= "Instance" then return false end

    if not TargetCharacter:IsA("Model") then return false end

    local FocusPart = TargetCharacter:FindFirstChild("HumanoidRootPart")
    if not FocusPart then return false end

    if not Camera then return false end
    local IgnoreArray = VisibilityIgnore

    IgnoreArray[1] = TargetCharacter

    local LocalCharacter = LocalPlayer.Character
    if LocalCharacter then
        IgnoreArray[2] = LocalCharacter
    else
        IgnoreArray[2] = nil
    end
    IgnoreArray[3] = nil

    local CameraCFrame = Camera.CFrame
    if not CameraCFrame then return false end

    local Origin = CameraCFrame.Position
    local Direction = FocusPart.Position - Origin

    if Direction:Dot(Direction) <= 0 then return true end

    local HitResult = Workspace:Raycast(Origin, Direction, VisibilityRaycastParams)
    return HitResult == nil
end
-- // ===========================================================================================================================
function HelperFunctions:IsAlive(CharacterTarget)
    return not HelperFunctions:IsDowned(CharacterTarget) and not HelperFunctions:IsDead(CharacterTarget)
end
-- // ===========================================================================================================================
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)
-- // ===========================================================================================================================
-- // ===========================================================================================================================

return HelperFunctions
