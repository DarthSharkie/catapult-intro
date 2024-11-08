local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- modules
local Catapult = require(ServerScriptService:WaitForChild("Catapult"))
local TargetPlatform = require(ServerScriptService:WaitForChild("TargetPlatform"))
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService"))
local SpawnPool = require(ServerScriptService:WaitForChild("SpawnPool"))
local Lighting = require(ServerScriptService:WaitForChild("Lighting"))

-- events
local targetPlatformResetEvent = ServerScriptService:WaitForChild("TargetPlatformResetEvent")

-- local data
local catapults = {}
local targetPlatforms = {}

-- local constants

-- Nix the baseplate
workspace.Baseplate:Destroy()

local function _onGameOver()
end

local function onTargetReset(player: Player)
    for _, targetPlatform in targetPlatforms[player.UserId] do
        targetPlatform:Reset(player)
    end
end

local function initialize(player: Player)
    -- Ensure this connection happens before spawning the character!
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                wait(3)
                player:LoadCharacter()
            end)
        end
    end)

    local spawn: SpawnPool.Spawn = SpawnPool.Allocate(player)
    catapults[player.UserId] = Catapult.new(player, spawn.CFrame)

    targetPlatforms[player.UserId] = {
        TargetPlatform.new(player, spawn.Index),
        TargetPlatform.new(player, spawn.Index),
    }

    LeaderboardService.addPlayer(player)

    -- Ensure this happens after creating the Catapult, so the spawn point exists
    player.RespawnLocation = catapults[player.UserId]:GetSpawn()
    player:LoadCharacter()
end

local function cleanup(player: Player)
    catapults[player.UserId]:Destroy()
    for _, targetPlatform in targetPlatforms[player.UserId] do
        targetPlatform:Destroy()
    end
    LeaderboardService.removePlayer(player)
    SpawnPool.Return(player)
end

-- TODO: Figure out if there's a better way to have LB connect to Catapult launch
LeaderboardService.Init()
SpawnPool.Init()

-- Lighting needs to be in a separate thread
coroutine.wrap(Lighting.tick)()

Players.PlayerAdded:Connect(function(player: Player)
    initialize(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    cleanup(player)
end)

targetPlatformResetEvent.Event:Connect(onTargetReset)

--[[  TODO List
1. [x] Allow for multiple spawns
2. Prevent overlapping catapult fire (4-6 per server to allow for enough range of motion)
   - [x] will need to limit catapult rotation
   - [x] will need to limit target platform theta
   - [x] Need to adjust position to ensure the entire platform is inside the slice
3. [x] Detect targets knocked over (if they're still standing, it doesn't count)
4. [x] Save number of launches, number of targets "destroyed" to cloud
5. Consider badges/achievements for number of launches, number of targets
6. [x] Figure out how to fully-manage via Rojo... model export from studio didn't work
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
9. Misc improvements
   - cylindrical bounding box detection for platforms (as long as they're cylinders)
   - [x] fully manage the ReplicatedStorage folder (GUI)
   - [x] fully manage the TextChatService folder
   - Figure out `rojo build` and .rbxm import any time the MeshId properties change
   - Figure out managing Terrain via *.rbxl.
]]