local ServerStorage = game:GetService("ServerStorage")

local SpawnPool = {}
SpawnPool.__index = SpawnPool

export type Spawn = {
    CFrame: CFrame,
    Owner: Player?,
    Index: number,
}

SpawnPool.SIZE = 8
local SIZE = SpawnPool.SIZE
local R_DISTANCE = 90
local spawns = {}
local TAU = math.pi * 2
local dividers = {}

function SpawnPool.Init()
    local dividerFolder = Instance.new("Folder")
    dividerFolder.Name = "Dividers"
    dividerFolder.Parent = workspace

    for point = 1, SIZE do
        local radial = ((point - 1) * 2 + 1)  -- e.g., 1, 3, 5, ...
        local theta = radial / (2 * SIZE) * TAU  -- e.g., 1/12, 3/12, 5/12, etc.
        local spawnPosition = Vector3.new(R_DISTANCE * math.sin(theta), 0, R_DISTANCE * math.cos(theta))
        -- Continue outward from the center, but the catapult faces the "back" of the platform
        local spawnCFrame = CFrame.lookAt(spawnPosition, Vector3.zero) * CFrame.new(0, 14, 0)
        spawns[point] = {
            CFrame = spawnCFrame,
            Owner = nil,
            Index = point,
        }

        -- The terrain is generally grassy, but grass blades should not poke through the platform feet.
        -- Therefore, create a cylinder of Ground, as if the land was cleared.  Height == 4 because of voxels.
        workspace.Terrain:FillCylinder(CFrame.new(spawnPosition.X, -2, spawnPosition.Z), 4, 45, Enum.Material.Ground)

        local divider = Instance.new("Part")
        divider.Name = "Divider" .. point
        divider.Shape = Enum.PartType.Block
        divider.Size = Vector3.new(0.01, 500, 500)
        divider.Material = Enum.Material.Fabric
        divider.Massless = true
        divider.CanCollide = true
        divider.Transparency = 0.75
        divider.Color = Color3.new(0,0,0)
        divider.Anchored = true
        local dividerTheta = (radial - 1) / (2 * SIZE) * TAU
        local dividerPosition = Vector3.new(250 * math.sin(dividerTheta), 250, 250 * math.cos(dividerTheta))
        local dividerCFrame = CFrame.new(dividerPosition) * CFrame.fromAxisAngle(Vector3.yAxis, dividerTheta)
        divider.CFrame = dividerCFrame
        divider.Parent = ServerStorage.Dividers
        dividers[point] = divider
    end
end

function SpawnPool.Allocate(player: Player): Spawn
    local choice
    repeat
        choice = math.random(1, #spawns)
    until not spawns[choice].Owner

    print("Picked Spawn Point " .. choice)
    spawns[choice].Owner = player

    dividers[choice].Parent = workspace.Dividers
    -- Ternary nastiness, but should be safe here since these numbers won't be falsy
    local rightDividerIndex = (choice == SIZE) and 1 or choice + 1
    dividers[rightDividerIndex].Parent = workspace.Dividers

    return spawns[choice]
end

function SpawnPool.Return(player: Player)
    for point = 1, SIZE do
        if spawns[point].Owner == player then
            spawns[point].Owner = nil
            local leftNeighborIndex = (point == 1) and SIZE or point - 1  -- ternary
            if spawns[leftNeighborIndex].Owner == nil then
                dividers[point].Parent = ServerStorage.Dividers
            end
            local rightNeighborIndex = (point == SIZE) and 1 or point + 1  -- ternary
            if spawns[rightNeighborIndex].Owner == nil then
                dividers[rightNeighborIndex].Parent = ServerStorage.Dividers
            end
        end
    end
end

return SpawnPool