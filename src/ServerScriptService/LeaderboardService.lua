-- Services
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Events
local catapultLaunchEvent = ServerScriptService:WaitForChild("CatapultLaunchEvent")

-- local data
local playerRecords: {[number]: PlayerRecord} = {}
local blocksDestroyedValues: {[number]: IntValue} = {}
local shotsFiredValues: {[number]: IntValue} = {}
local PlayerData = DataStoreService:GetDataStore("PlayerData")

type PlayerRecord = {
    shotsFired: number,
    blocksDestroyed: number,
}

local function newPlayerRecord(): PlayerRecord
    return {
        shotsFired = 0,
        blocksDestroyed = 0,
    }
end

local LeaderboardService = {}

local function LoadData(player: Player): (boolean, any)
    local success: boolean, result: any = pcall(function()
        return PlayerData:GetAsync(player.UserId)
    end)
    if not success then
        warn(result)
    end
    return success, result
end

local function SaveData(player: Player, data: PlayerRecord): boolean
    local success: boolean, result: any = pcall(function()
        PlayerData:SetAsync(player.UserId, data)
    end)
    if not success then
        warn(result)
    end
    return success
end

function LeaderboardService.addPlayer(player: Player)

    local success: boolean, result: any = LoadData(player)
    local playerRecord: PlayerRecord = success and result :: PlayerRecord or newPlayerRecord()
    playerRecords[player.UserId] = playerRecord

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
        shotsFired.Name = "Fired"
        shotsFired.Value = playerRecord.shotsFired
    end

    local blocksDestroyed = stats:FindFirstChild("BlocksDestroyed")
    if not blocksDestroyed then
        blocksDestroyed = Instance.new("IntValue")
        blocksDestroyed.Parent = stats
        blocksDestroyed.Name = "Destroyed"
        blocksDestroyed.Value = playerRecord.blocksDestroyed
    end

    shotsFiredValues[player.UserId] = shotsFired
    blocksDestroyedValues[player.UserId] = blocksDestroyed
end

function LeaderboardService.removePlayer(player: Player)
    -- Don't remove from the table in case of failure; let OnClose try again
    SaveData(player, playerRecords[player.UserId])

    blocksDestroyedValues[player.UserId] = nil
    shotsFiredValues[player.UserId] = nil
end

local function onCatapultLaunch(_payload, player: Player)
    shotsFiredValues[player.UserId].Value += 1
    playerRecords[player.UserId].shotsFired += 1
end

function LeaderboardService.BlocksDestroyed(player: Player, count: number)
    blocksDestroyedValues[player.UserId].Value += count
    playerRecords[player.UserId].blocksDestroyed += count
end

local function OnClose()
    for _, player in Players:GetPlayers() do
        SaveData(player, playerRecords[player.UserId])
    end
end

function LeaderboardService.Init()
    -- Handle value modifications
    catapultLaunchEvent.Event:Connect(onCatapultLaunch)

    game:BindToClose(OnClose)
end

return LeaderboardService
