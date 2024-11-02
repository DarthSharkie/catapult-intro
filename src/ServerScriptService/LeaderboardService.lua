local module = {}

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Events
local catapultLaunchEvent = ServerScriptService:WaitForChild("CatapultLaunchEvent")

-- local data
local shotsFiredValues: {[number]: IntValue} = {}

local function addPlayer(player: Player)
    
    local stats = player:FindFirstChild("leaderstats")
    if not stats then
        stats = Instance.new("Folder")
        stats.Name = "leaderstats"
        stats.Parent = player        
    end
    
    local shotsFired = stats:FindFirstChild("ShotsFired")
    if not shotsFired then
        shotsFired = Instance.new("IntValue")
        shotsFired.Parent = stats
        shotsFired.Name = "Shots Fired"
        shotsFired.Value = 0
    end
    
    shotsFiredValues[player.UserId] = shotsFired
    
end

local function removePlayer(player: Player)
    shotsFiredValues[player.UserId] = nil
end

local function onCatapultLaunch(payload, player: Player)
    shotsFiredValues[player.UserId].Value += 1
end


function module:init()
    
    -- Handle players joining and leaving
    Players.PlayerAdded:Connect(addPlayer)
    Players.PlayerRemoving:Connect(removePlayer)
    
    -- Handle value modifications
    catapultLaunchEvent.Event:Connect(onCatapultLaunch)
    
end

return module
