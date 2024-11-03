local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

export type Type = {
    Instance: Instance,
    SetParent: (Instance) -> nil,
    SetTrigger: ((Type, Player) -> nil) -> nil,
    DisableTrigger: () -> nil,
    Destroy: () -> nil,
}

local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(material: string, anchored: boolean, position: CFrame)
    local self = setmetatable({}, Projectile)

    local instanceName
    if material:sub(-#"Ball") ~= "Ball" then
        instanceName = material .. "Ball"
        self.material = material
    else
        instanceName = material
        self.material = material:sub(-#"Ball")
    end

    -- Needs parenting once returned
    local template = ServerStorage.Projectiles:FindFirstChild(instanceName)
    self.Instance = template:Clone()
    self.Instance.Anchored = anchored
    self.Instance:PivotTo(position)

    if not self.Instance.ProximityPrompt then
        self.Instance.ProximityPrompt = Instance.new("ProximityPrompt")
    end
    local prompt = self.Instance.ProximityPrompt
    prompt.ActionText = "Load"
    prompt.ObjectText = self.material
    prompt.RequiresLineOfSight = false

    return self
end

function Projectile.clone(projectile: Type)
    local self = setmetatable({}, Projectile)

    self.Instance = projectile.Instance:Clone()

    return self
end

function Projectile:SetParent(parent: Instance)
    self.Instance.Parent = parent
end

function Projectile:SetTrigger(fn: (Type, Player) -> nil)
    self.Instance.ProximityPrompt.Triggered:Connect(function(player: Player)
        fn(self, player)
    end)
end

function Projectile:DisableTrigger()
    self.Instance.ProximityPrompt.Enabled = false
end

function Projectile.launchable(projectile: Type, player: Player, cframe: CFrame, unloadFn): Type 
    local p = Projectile.clone(projectile)
    p.Instance.Anchored = false
    p.Instance:PivotTo(cframe)
    local prompt = p.Instance.ProximityPrompt
    prompt.ActionText = "Unload"
    prompt.KeyboardKeyCode = "U"
    prompt.Triggered:Connect(unloadFn)
    
    p.Instance.Parent = Workspace.ActiveProjectiles
    p.Instance:SetNetworkOwner(player)
    return p
end

function Projectile:Destroy()
    self.Instance:Destroy()
end

return Projectile
