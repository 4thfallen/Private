if game.PlaceId ~= 105788818579323 or 104685095603299 or 128870589208224 then return end
if not game.Loaded then game.Loaded:Wait() end
-- // ===========================================================================================================================
-- // ===========================================================================================================================
local HelperFunctions = {}
local VisibilityIgnore = {}
local VisibilityPoints = {}

local Game = game

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

local CachedPlayers = {}
local CachedPlayersDirty = true
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

    local FocusPart = TargetCharacter:FindFirstChild("HumanoidRootPart")

    if not FocusPart then
        local PivotCFrame = TargetCharacter:GetPivot()
        if not PivotCFrame then return true end

        FocusPart = {Position = PivotCFrame.Position}
    end

    local PointsArray = VisibilityPoints
    PointsArray[1], PointsArray[2], PointsArray[3] = nil, nil, nil
    PointsArray[1] = FocusPart.Position

    local Obstructors = Camera:GetPartsObscuringTarget(PointsArray, IgnoreArray)
    return not Obstructors or Obstructors[1] == nil
end
-- // ===========================================================================================================================
function HelperFunctions:IsAlive(CharacterTarget)
    return not HelperFunctions:IsDowned(CharacterTarget) and not HelperFunctions:IsDead(CharacterTarget)
    end
-- // ===========================================================================================================================
function HelperFunctions:GetPlayers()
    if CachedPlayersDirty then
        HelperFunctions:RebuildCachedPlayers()
    end

    return CachedPlayers
end
-- // ===========================================================================================================================
-- // ===========================================================================================================================
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)
-- // ---------------------------------------------------------------------------------------------------------------------------
function HelperFunctions:RebuildCachedPlayers()
    CachedPlayers = Players:GetPlayers()
    CachedPlayersDirty = false
end
-- // ---------------------------------------------------------------------------------------------------------------------------
Players.PlayerAdded:Connect(function()
    CachedPlayersDirty = true
end)

Players.PlayerRemoving:Connect(function()
    CachedPlayersDirty = true
end)
-- // ===========================================================================================================================
-- // ===========================================================================================================================

return HelperFunctions
