local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- modules
local Catapult = require(ServerScriptService:WaitForChild("Catapult"))
local TargetPlatform = require(ServerScriptService:WaitForChild("TargetPlatform"))
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService"))

-- events

-- local data
local catapults = {}
local targetPlatforms = {}

-- local constants

local function onGameOver()
end

local function onGameReset()
end

local function initialize(player: Player)
    catapults[player.UserId] = Catapult.new(player.UserId)

    targetPlatforms[player.UserId] = {
        TargetPlatform.new(player), 
        TargetPlatform.new(player)
    }
    
    LeaderboardService:addPlayer(player)
end

local function cleanup(player: Player)
    catapults[player.UserId]:Destroy()
    for _, targetPlatform in targetPlatforms[player.UserId] do
        targetPlatform:Destroy()
    end
    LeaderboardService:removePlayer(player)
end

Players.PlayerAdded:Connect(function(player: Player) 
    initialize(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    cleanup(player)
end)

-- TODO: Figure out if there's a better way to have LB connect to Catapult launch
LeaderboardService:init()
