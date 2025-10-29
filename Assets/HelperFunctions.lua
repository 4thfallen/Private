if game.PlaceId ~= 105788818579323 then return end
if not game.Loaded then game.Loaded:Wait() end

local HelperFunctions = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/4thfallen/Private/refs/heads/main/Assets/HelperFunctions.lua"))()
-- // ==================================================================================================================================================================================
-- // ==================================================================================================================================================================================
local DrawingNew = Drawing.new
local MouseMoveRelease = mousemoverel

local Game = game
local Workspace = Game.Workspace

local UserInputService = Game:GetService("UserInputService")
local RunService = Game:GetService("RunService")
local Players = Game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ToNumber = tonumber
local TypeOf = typeof

local MathHuge = math.huge
local MathClamp = math.clamp
local MathFloor = math.floor

local Vector3New = Vector3.new
local CFrameNew = CFrame.new

local Color3FromRGB = Color3.fromRGB

local RedRGB = Color3FromRGB(255, 0, 0)
local BlackRGB = Color3FromRGB(0, 0, 0)
-- // ==================================================================================================================================================================================
-- // ==================================================================================================================================================================================





-- // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local AimbotFunctions = {}
local AimbotModule = {
    Enabled = true;
    LockBind = "Q";


    TargetPart = "Head";
    Method = "CFrame";


    DeadCheck = false;
    CrewCheck = false;
    DownedCheck = true;
    FriendsCheck = false;
    VisibleCheck = true;


    PredictionEnabled = false;
    PredictionX = 0;
    PredictionY = 0;
    PredictionZ = 0;


    SmoothnessEnabled = false;
    SmoothnessThreshold = 0;


    FOVVisible = true;
    FOVFilled = false;

    FOVColor = RedRGB;
    FOVOutlineColor = BlackRGB;

    FOVRadius = 250;
    FOVNumSides = 60;
    FOVThickness = 1;
    FOVTransparency = 1;
}

AimbotFunctions.SmoothFactor = 1

local AimbotState = {LockedTarget = nil, IsActive = false, PendingAcquire = false, RequireVisibilityCheck = false}

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Camera = Workspace.CurrentCamera end)
LocalPlayer.CharacterAdded:Connect(function() if AimbotState then AimbotState.LockedTarget = nil end end)
LocalPlayer.CharacterRemoving:Connect(function() if AimbotState then AimbotState.LockedTarget = nil end end)
-- // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




















-- // ==================================================================================================================================================================================
-- // ==================================================================================================================================================================================
local AimbotCircleOutline = DrawingNew("Circle")
local AimbotCircle = DrawingNew("Circle")

AimbotCircle.Visible, AimbotCircle.Filled, AimbotCircle.Color = false, AimbotModule.FOVFilled, AimbotModule.FOVColor
AimbotCircle.Radius, AimbotCircle.NumSides, AimbotCircle.Thickness, AimbotCircle.Transparency = 0, AimbotModule.FOVNumSides, AimbotModule.FOVThickness, AimbotModule.FOVTransparency

AimbotCircleOutline.Visible, AimbotCircleOutline.Filled, AimbotCircleOutline.Color = false, false, AimbotModule.FOVOutlineColor
AimbotCircleOutline.Radius, AimbotCircleOutline.Thickness, AimbotCircleOutline.Transparency = 0, 0, AimbotModule.FOVTransparency
-- // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





-- // ==================================================================================================================================================================================
function AimbotFunctions:ResolveCharacter(Player)
    if not Player then return nil end

    local Character = Player.Character
    if Character then return Character end

    local CharactersContainer = Workspace:FindFirstChild("Characters")
    if CharactersContainer then Character = CharactersContainer:FindFirstChild(Player.Name) end

    return Character
end
-- // ==================================================================================================================================================================================





-- // ==================================================================================================================================================================================
function AimbotFunctions:GetAimPart(Character)
    if not Character then return nil end

    local Configuration = AimbotModule
    local TargetPartName = Configuration.TargetPart

    if TypeOf(TargetPartName) ~= "string" then TargetPartName = "Head" end
    if TargetPartName == "PrimaryPart" then return Character.PrimaryPart end

    if TargetPartName then local RequestedPart = Character:FindFirstChild(TargetPartName)
    if RequestedPart then return RequestedPart end
    end

    return nil
end
-- // ==================================================================================================================================================================================





-- // ==================================================================================================================================================================================
function AimbotFunctions:IsValidTarget(Player, SkipVisibility)
    if not Player or Player == LocalPlayer then return false end

    local Character = AimbotFunctions:ResolveCharacter(Player)
    if not Character then return false end

    local Configuration = AimbotModule

    if (Configuration.DownedCheck and HelperFunctions:IsDowned(Player.Name))
        or (Configuration.DeadCheck and HelperFunctions:IsDead(Player.Name))
        or (Configuration.FriendsCheck and HelperFunctions:IsFriends(Player.Name))
        or (Configuration.CrewCheck and HelperFunctions:IsCrew(Player.Name)) then
        return false
    end

    if not SkipVisibility and Configuration.VisibleCheck then
        local Visible = HelperFunctions:IsVisible(Character)

        if not Visible then
            Visible = HelperFunctions:IsVisible(Player.Name)
        end

        if not Visible then
            return false
        end
    end

    return true
end
-- // ==================================================================================================================================================================================





-- // ==================================================================================================================================================================================
function AimbotFunctions:AcquireTarget(CurrentCamera, MousePosition, FOVActive, RadiusSquared, RequireVisible)
    local PlayerList = Players:GetPlayers()
    local ClosestPlayer, ClosestPart, ClosestDistance = nil, nil, MathHuge

    for Index = 1, #PlayerList do
        local PlayerInstance = PlayerList[Index]

        if AimbotFunctions:IsValidTarget(PlayerInstance, not RequireVisible) then
            local Character = AimbotFunctions:ResolveCharacter(PlayerInstance)
            local AimPart = AimbotFunctions:GetAimPart(Character)

            if AimPart then
                local ScreenPosition, OnScreen = CurrentCamera:WorldToViewportPoint(AimPart.Position)

                if OnScreen then
                    local DeltaX = ScreenPosition.X - MousePosition.X
                    local DeltaY = ScreenPosition.Y - MousePosition.Y
                    local DistanceSquared = DeltaX * DeltaX + DeltaY * DeltaY

                    if (not FOVActive or DistanceSquared <= RadiusSquared) and DistanceSquared < ClosestDistance then
                        ClosestDistance = DistanceSquared
                        ClosestPlayer = PlayerInstance
                        ClosestPart = AimPart
                    end
                end
            end
        end
    end

    return ClosestPlayer, ClosestPart
end
-- // ==================================================================================================================================================================================





-- // ==================================================================================================================================================================================
function AimbotFunctions:UpdateCircle(MousePosition)
    local Configuration = AimbotModule

    local Radius = ToNumber(Configuration.FOVRadius) or 0
    local NumSides = ToNumber(Configuration.FOVNumSides) or 0
    local Thickness = ToNumber(Configuration.FOVThickness) or 0
    local Transparency = MathClamp(ToNumber(Configuration.FOVTransparency) or 0, 0, 1)

    local Visible = Configuration.FOVVisible and Radius > 0

    AimbotCircle.Visible = Visible
    AimbotCircleOutline.Visible = Visible

    if not Visible then AimbotCircleOutline.Visible = false return end

    AimbotCircle.Position = MousePosition
    AimbotCircle.Color = Configuration.FOVColor
    AimbotCircle.Filled = Configuration.FOVFilled

    AimbotCircle.Radius = Radius
    AimbotCircle.NumSides = NumSides
    AimbotCircle.Thickness = Thickness
    AimbotCircle.Transparency = Transparency

    local OutlineThickness = (Thickness > 0 and Thickness or 1) + 1

    AimbotCircleOutline.Filled = false
    AimbotCircleOutline.Visible = Visible
    AimbotCircleOutline.Color = Configuration.FOVOutlineColor
    AimbotCircleOutline.Position = MousePosition
    AimbotCircleOutline.Radius = Radius + OutlineThickness * 0.5
    AimbotCircleOutline.NumSides = NumSides
    AimbotCircleOutline.Thickness = OutlineThickness
    AimbotCircleOutline.Transparency = Transparency
end
-- // ==================================================================================================================================================================================





-- // ==================================================================================================================================================================================
function AimbotFunctions:Step(DeltaTime)
    if not Camera then return end

    local Configuration = AimbotModule
    local RequireVisible = Configuration.VisibleCheck

    local MousePosition = UserInputService:GetMouseLocation()
    AimbotFunctions:UpdateCircle(MousePosition)

    if not (Configuration.Enabled and AimbotState.IsActive) then
        AimbotState.LockedTarget = nil
        AimbotState.PendingAcquire = false
        AimbotState.RequireVisibilityCheck = false

        return
    end

    local LockedTarget = AimbotState.LockedTarget

    local Radius = ToNumber(Configuration.FOVRadius)
    local FOVActive = Configuration.FOVVisible and Radius > 0
    local RadiusSquared = Radius * Radius

    local AimPart = nil

    if AimbotFunctions:IsValidTarget(LockedTarget, true) then
        local Character = AimbotFunctions:ResolveCharacter(LockedTarget)

        if Character then
            AimPart = AimbotFunctions:GetAimPart(Character)
        end
    end

    if AimPart then
        local _, OnScreen = Camera:WorldToViewportPoint(AimPart.Position)
        if not OnScreen then AimPart = nil end
    end

    if not AimPart then
        AimbotState.LockedTarget = nil
        if not AimbotState.PendingAcquire then return end

        LockedTarget, AimPart = AimbotFunctions:AcquireTarget(Camera, MousePosition, FOVActive, RadiusSquared, RequireVisible)
        if not (LockedTarget and AimPart) then return end

        AimbotState.LockedTarget = LockedTarget
        AimbotState.PendingAcquire = false
        AimbotState.RequireVisibilityCheck = false
    end

    local TargetPosition = AimPart.Position

    if Configuration.PredictionEnabled then
        local Velocity = AimPart.AssemblyLinearVelocity

        TargetPosition = TargetPosition + Vector3New(
            Velocity.X * Configuration.PredictionX,
            Velocity.Y * Configuration.PredictionY,
            Velocity.Z * Configuration.PredictionZ
        )
    end

    if Configuration.SmoothnessEnabled then
        local SmoothValue = Configuration.SmoothnessThreshold or 0
        AimbotFunctions.SmoothFactor = MathClamp((SmoothValue * DeltaTime * 60), 0.05, 1)
    else
        AimbotFunctions.SmoothFactor = 1
    end



    if Configuration.Method == "MouseMoveRelease" then
        local ScreenPosition = Camera:WorldToViewportPoint(TargetPosition)
        local DeltaX = (ScreenPosition.X - MousePosition.X) * AimbotFunctions.SmoothFactor
        local DeltaY = (ScreenPosition.Y - MousePosition.Y) * AimbotFunctions.SmoothFactor

        local MoveX = MathFloor(DeltaX + 0.5)
        local MoveY = MathFloor(DeltaY + 0.5)

        if MoveX ~= 0 or MoveY ~= 0 then
            MouseMoveRelease(MoveX, MoveY)
        end
    else
        local Desired = CFrameNew(Camera.CFrame.Position, TargetPosition)
        Camera.CFrame = Camera.CFrame:Lerp(Desired, AimbotFunctions.SmoothFactor)
    end

    AimbotState.LockedTarget = LockedTarget
end
-- // ==================================================================================================================================================================================





-- // ==================================================================================================================================================================================
RunService.Heartbeat:Connect(function(DeltaTime)
    AimbotFunctions:Step(DeltaTime)
end)
-- // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(InputObject, GameProcessed)
    if GameProcessed then return end

    local Configuration = AimbotModule

    local LockBind = Configuration.LockBind
    if TypeOf(LockBind) ~= "EnumItem" then LockBind = Enum.KeyCode.Q end

    if not LockBind or InputObject.KeyCode ~= LockBind then return end
    if not Configuration.Enabled then return end
    if not AimbotState.IsActive then AimbotState.IsActive = true end

    if AimbotState.LockedTarget then
        AimbotState.LockedTarget = nil
        AimbotState.PendingAcquire = false
        AimbotState.RequireVisibilityCheck = false
        return
    end

    if not Camera then return end

    AimbotState.PendingAcquire = true
    AimbotState.RequireVisibilityCheck = Configuration.VisibleCheck

    local MousePosition = UserInputService:GetMouseLocation()
    local Radius = ToNumber(Configuration.FOVRadius)

    local FOVActive = Configuration.FOVVisible and Radius > 0
    local RadiusSquared = Radius * Radius

    local TargetPlayer, TargetPart = AimbotFunctions:AcquireTarget(Camera, MousePosition, FOVActive, RadiusSquared, Configuration.VisibleCheck)

    if TargetPlayer and TargetPart then
        AimbotState.LockedTarget = TargetPlayer

        AimbotState.PendingAcquire = false
        AimbotState.RequireVisibilityCheck = false

        return
    end

    AimbotState.PendingAcquire = false
    AimbotState.RequireVisibilityCheck = false
end)
-- // ==================================================================================================================================================================================

-- // ==================================================================================================================================================================================
-- // ==================================================================================================================================================================================
