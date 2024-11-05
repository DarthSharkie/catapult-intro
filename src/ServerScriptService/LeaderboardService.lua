-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Events
local catapultLaunchEvent = ServerScriptService:WaitForChild("CatapultLaunchEvent")

-- local data
local shotsFiredValues: {[number]: IntValue} = {}
local blocksDestroyedValues: {[number]: IntValue} = {}

local LeaderboardService = {}

function LeaderboardService:addPlayer(player: Player)
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

    local blocksDestroyed = stats:FindFirstChild("BlocksDestroyed")
    if not blocksDestroyed then
        blocksDestroyed = Instance.new("IntValue")
        blocksDestroyed.Parent = stats
        blocksDestroyed.Name = "Blocks Destroyed"
        blocksDestroyed.Value = 0
    end

    shotsFiredValues[player.UserId] = shotsFired
    blocksDestroyedValues[player.UserId] = blocksDestroyed
end

function LeaderboardService:removePlayer(player: Player)
    shotsFiredValues[player.UserId] = nil
end

local function onCatapultLaunch(payload, player: Player)
    shotsFiredValues[player.UserId].Value += 1
end

function LeaderboardService:BlocksDestroyed(player: Player, count: number)
    blocksDestroyedValues[player.UserId].Value += count
end

function LeaderboardService:init()
    -- Handle value modifications
    catapultLaunchEvent.Event:Connect(onCatapultLaunch)
end

return LeaderboardService
