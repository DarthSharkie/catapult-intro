local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- modules
local Projectile = require(ServerScriptService:WaitForChild("Projectile"))

-- events
local catapultLaunchEvent = ServerScriptService:WaitForChild("CatapultLaunchEvent")
local catapultUnloadEvent = ServerScriptService:WaitForChild("CatapultUnloadEvent")

-- local constants
local SPRING_TENSION_FACTOR = 5000
local SPRING_TENSION_INITAL_VALUE = 25000
local RELEASE_ANGLE_INITIAL_VALUE = -90
local RELEASE_ANGLE_QUANTUM = 5
local MOTOR_MAX_TORQUE = 10000000
local CATAPULT_LAUNCH_RESET_TIME = ServerStorage.CatapultPlatform:GetAttribute("LaunchResetTime")

local PROJECTILES = {
    -- left side
    Ice = CFrame.new(23.74, 16.29, -3.45),
    Wood = CFrame.new(24.94, 16.195, 1.05),
    Marble = CFrame.new(24.744, 16.195, 5.55),
    Leather = CFrame.new(23.544, 16.395, 10.05),
    -- right side
    Plastic = CFrame.new(-24.456, 15.995, -3.45),
    Rubber = CFrame.new(-25.156, 15.995, 1.05),
    Rock = CFrame.new(-25.156, 15.995, 5.55),
    Glass = CFrame.new(-24.756, 15.995, 10.05),
}


local Catapult = {}
Catapult.__index = Catapult

function Catapult.new(userId: number)
    local self = setmetatable({}, Catapult)

    self.Owner = userId

    -- init other stuff here
    self.platform = ServerStorage.CatapultPlatform:Clone()
    self.platform:PivotTo(CFrame.new(0, 14, 0))
    self.platform.Parent = Workspace.ActiveCatapultPlatforms

    self.armature = self.platform.Catapult.Swivel.Armature
    self.launcherHinge = self.platform.Constraints.LauncherHinge
    
    self.launchButton = self.platform.LaunchButton.button
    self.launchButton.ProximityPrompt.Triggered:Connect(function(...)
        self:Launch(...)
    end)

    self.targetResetButton = self.platform.TargetResetButton.button
    self.targetResetButton.ProximityPrompt.Triggered:Connect(function(...)

    end)

    self.reloadAttachment = self.platform.Catapult.Swivel.Armature.Att_Reload
    
    -- Init, connect triggers, and alias spring parts
    self.springTension = SPRING_TENSION_INITAL_VALUE
    self.springTensionButton = self.platform.SpringTensionButton
    self.tensionIncreaseButton = self.springTensionButton.StrongButton
    self.tensionIncreaseButton.ProximityPrompt.Triggered:Connect(function(...)
        self:IncreaseSpringTension(...)
    end)
    self.tensionDecreaseButton = self.springTensionButton.WeakButton
    self.tensionDecreaseButton.ProximityPrompt.Triggered:Connect(function(...)
        self:DecreaseSpringTension(...)
    end)
    self.springConstraint = self.platform.Constraints.SpringConstraint
    self.tensionLabel = self.springTensionButton.Console.SurfaceGui.Frame.PowerLabel 

    -- Init, connect triggers, and alias release angle parts
    self.releaseAngle = RELEASE_ANGLE_INITIAL_VALUE
    self.angleButton = self.platform.AngleButton
    self.angleIncreaseButton = self.angleButton.HigherButton
    self.angleIncreaseButton.ProximityPrompt.Triggered:Connect(function(...)
        self:IncreaseReleaseAngle(...)
    end)
    self.angleDecreaseButton = self.angleButton.LowerButton
    self.angleDecreaseButton.ProximityPrompt.Triggered:Connect(function(...)
        self:DecreaseReleaseAngle(...)
    end)
    self.releaseAngleConstraint = self.platform.Constraints.LauncherHinge
    self.releaseAngleLabel = self.angleButton.Console.SurfaceGui.Frame.AngleLabel 

    -- Other data
    self.payload = nil
    self.lastArmatureNetworkOwner = nil
    self.launchAttempts = 0
    
    -- disable launch prompt as a ball has not been loaded
    self:EnableLaunchPrompt(false)

    -- Create template balls
    self.projectiles = {}
    for material, cframe in PROJECTILES do
        self.projectiles[material] = Projectile.new(material, true, cframe)
        self.projectiles[material]:SetParent(self.platform)
        self.projectiles[material]:SetTrigger(function(projectile: Projectile.Type, player: Player)
            self:Load(projectile, player)
        end)
    end

    return self
end

function Catapult:EnableLaunchPrompt(isEnabled: boolean)
    self.launchButton.ProximityPrompt.Enabled = isEnabled
end

function Catapult:Unload()
    if not self.payload then
        return
    end
    self.payload:Destroy()
    self.payload = nil

    self:EnableLaunchPrompt(false)

    catapultUnloadEvent:Fire()
end

function Catapult:Load(projectile: Projectile.Type, player: Player)
    if self.payload then
        return
    end

    local function unloadFn()
        self:Unload()
    end

    self.payload = Projectile.launchable(projectile, player, CFrame.new(self.reloadAttachment.WorldPosition), unloadFn)

    Workspace.Audio.Load:Play()
    
    self:EnableLaunchPrompt(true)
end

function Catapult:SetNetworkOwnerForLaunch(player: Player)
    -- no need to keep setting network owner if it was already set to this player
    if self.lastArmatureNetworkOwner and self.lastArmatureNetworkOwner == player then
        return
    end
    self.lastArmatureNetworkOwner = player
    
    -- ensure the armature physics are handled by the players client
    self.armature:SetNetworkOwner(player)
end

function Catapult:Launch(player: Player)
    if not self.payload then
        return
    end
    
    -- disable launch prompt
    self:EnableLaunchPrompt(false)
    
    -- for a smooth launch, ensure the player owns the related objects
    self:SetNetworkOwnerForLaunch(player)
    
    -- Move payload to active projectiles
    self.payload:DisableTrigger()

    catapultLaunchEvent:Fire(self.payload, player)
    
    -- remove torque to launch the catapult
    self.launcherHinge.MotorMaxTorque = 0
    Workspace.Audio.Launch:Play()
    
    self.payload = nil

    task.delay(CATAPULT_LAUNCH_RESET_TIME, function()
        -- reapply the torque to reset the catapult
        self.launcherHinge.MotorMaxTorque = MOTOR_MAX_TORQUE
    end)
end

function Catapult:IncreaseSpringTension()
    if self.springTension < 75000 then
        self.springTension = self.springTension + SPRING_TENSION_FACTOR
        self.springConstraint.Stiffness = self.springTension
        self.tensionLabel = self.springTension / SPRING_TENSION_FACTOR
    end
end

function Catapult:DecreaseSpringTension()
    if self.springTension > SPRING_TENSION_FACTOR then
        self.springTension = self.springTension - SPRING_TENSION_FACTOR
        self.springConstraint.Stiffness = self.springTension
        self.tensionLabel = self.springTension / SPRING_TENSION_FACTOR
    end
end

function Catapult:IncreaseReleaseAngle()
    if self.releaseAngle > -150 then
        self.releaseAngle = self.releaseAngle - RELEASE_ANGLE_QUANTUM
        self.releaseAngleConstraint.LowerAngle = self.releaseAngle
        self.releaseAngleLabel = math.abs(self.releaseAngle)
    end
end

function Catapult:DecreaseReleaseAngle()
    if self.releaseAngle < -10 then
        self.releaseAngle = self.releaseAngle + RELEASE_ANGLE_QUANTUM
        self.releaseAngleConstraint.LowerAngle = self.releaseAngle
        self.releaseAngleLabel = math.abs(self.releaseAngle)
    end
end

function Catapult:Destroy()
    if self.payload then
        self.payload:Destroy()
    end
    self.platform:Destroy()
end

return Catapult
