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

--[[  TODO List
0. Reset target event hookup (feature parity)
1. Allow for multiple spawns
2. Prevent overlapping catapult fire (4-6 per server to allow for enough range of motion)
   - will need to limit catapult rotation
   - will need to limit target platform theta
3. Detect targets knocked over (if they're still standing, it doesn't count)
4. Save number of launches, number of targets "destroyed" to cloud
5. Consider badges/achievements for number of launches, number of targets
6. Figure out how to fully-manage via Rojo... model export from studio didn't work
7. Think about progression: is it multiple cats?  more powerful cat?  more sophisticated targets?  Skill tree?
   - new projectile?  bola? explosive? multi-ball?
   - new cats?  trebuchet?  ballista?
   - earn currency?
8. Monetization possible?  What x2 type things, or time savers would people pay for?
   - Auto-load
   - Earning multiplier
   - Buy currency pack(s)
   - Auto-target?
   - Auto-fire?
]]