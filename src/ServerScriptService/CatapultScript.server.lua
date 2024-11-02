local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- modules
local Catapult = require(ServerScriptService:WaitForChild("Catapult"))
local TargetPlatform = require(ServerScriptService:WaitForChild("TargetPlatforms"))
local Projectiles = require(ServerScriptService:WaitForChild("Projectiles"))
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService"))

-- events
local catapultLaunchEvent = ServerScriptService:WaitForChild("CatapultLaunchEvent")
local catapultUnloadEvent = ServerScriptService:WaitForChild("CatapultUnloadEvent")

-- local data

-- local constants


local function onGameOver()
end

local function onGameReset()
end

local function initialize()

    local catapult = Catapult.new()
    local target1 = TargetPlatform.new()
    local target2 = TargetPlatform.new()
    
    LeaderboardService:init()
end

initialize()
