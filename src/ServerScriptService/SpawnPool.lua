local SpawnPool = {}
SpawnPool.__index = SpawnPool

export type Spawn = {
    CFrame: CFrame,
    Owner: Player?,
}

SIZE = 6
local R_DISTANCE = 90
local spawns = {}
local TAU = math.pi * 2

function SpawnPool.new()
    local self = setmetatable({}, SpawnPool)

    for point = 1, SIZE do
        local theta = ((point - 1) * 2 + 1) / (2 * SIZE) * TAU  -- e.g., 1/12, 3/12, 5/12, etc.
        local spawnPosition = Vector3.new(R_DISTANCE * math.cos(theta), 0, R_DISTANCE * math.sin(theta))
        -- Continue outward from the center, but the catapult faces the "back" of the platform
        local spawnCFrame = CFrame.lookAt(spawnPosition, Vector3.zero) * CFrame.new(0, 14, 0)
        spawns[point] = {
            CFrame = spawnCFrame,
            Owner = nil,
        }
    end

    return self
end

function SpawnPool:Allocate(player: Player): CFrame
    local choice
    repeat 
        choice = math.random(1, #spawns)
    until not spawns[choice].Owner

    print("Picked Spawn Point " .. choice)
    spawns[choice].Owner = player
    return spawns[choice].CFrame
end

function SpawnPool:Return(player: Player)
    for point = 1, SIZE do
        if spawns[point].Owner == player then
            spawns[point].Owner = nil
        end
    end
end

return SpawnPool