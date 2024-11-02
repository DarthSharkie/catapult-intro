local module = {}

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- objects

-- events
local catapultLaunchEvent = ServerScriptService:WaitForChild("CatapultLaunchEvent")
local catapultUnloadEvent = ServerScriptService:WaitForChild("CatapultUnloadEvent")

local projectileTemplates = nil
local projectileSelected = nil

local launchResetTime = nil
-- the amount of time the projectile launched will exist for after being launched
local PROJECTILE_LIFETIME = 10

-- enable or disable all projectile proximity prompts
function module.enableProjectileProximityPrompts(isEnabled: boolean)
    for _, projectile in projectileTemplates:GetChildren() do
        projectile.ProximityPrompt.Enabled = isEnabled
    end
end

function module:projectileSelectedToLoad(projectile: Part, player: Player, loadCatapult)
    -- set new projectile on catapult
    local newProjectile = projectile:Clone()
    loadCatapult(newProjectile)

    -- hide the selected projectile to show user it was chosen
    projectileSelected = projectile
    projectileSelected.Anchored = true
    projectileSelected.Transparency = 0.6
    projectileSelected.CanCollide = false

    -- disable all projectile proximity prompts
    self.enableProjectileProximityPrompts(false)
end

function module.onCatapultLaunch(catapultPayload)
    -- Once launched, re-display the selected projectile as an option
    projectileSelected.Transparency = 0
    projectileSelected.CanCollide = true
    projectileSelected.Anchored = false
    projectileSelected = nil

    -- destroy the projectile after some time in case it is in the way of the next launch
    if catapultPayload then
        task.delay(PROJECTILE_LIFETIME, function()
            if catapultPayload then
                catapultPayload:Destroy()
                catapultPayload = nil
            end    
        end)
    end
    
    task.delay(launchResetTime, function()
        module.enableProjectileProximityPrompts(true)
    end)
    
end

function module.onCatapultUnload()
    -- Once launched, re-display the selected projectile as an option
    projectileSelected.Transparency = 0
    projectileSelected.CanCollide = true
    projectileSelected.Anchored = false
    projectileSelected = nil

    module.enableProjectileProximityPrompts(true)    
end

function module:init(projectiles: Folder, loadCatapult, launchResetTime_)
    launchResetTime = launchResetTime_ + 0.4  --extra time for armature to come back down
    projectileTemplates = projectiles
    for _, projectile in projectileTemplates:GetChildren() do
        projectile.ProximityPrompt.ObjectText = projectile.Material.Name
        projectile.ProximityPrompt.ActionText = "Load"
        projectile.ProximityPrompt.Triggered:Connect(function(player: Player)
            self:projectileSelectedToLoad(projectile, player, loadCatapult)
        end)
    end
    
    catapultLaunchEvent.Event:Connect(self.onCatapultLaunch)
    catapultUnloadEvent.Event:Connect(self.onCatapultUnload)
end

return module
