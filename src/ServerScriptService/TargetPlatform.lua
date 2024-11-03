--!strict

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local R_MIN = 75
local R_RANGE = 125 -- x, z in [75, 200)
local TAU = 2 * math.pi
local Y_MIN = 4
local Y_RANGE = 28 -- y in [4, 32)

local TARGETS_PER_ROW = 5
local TARGETS_PER_COLUMN = 6
local TARGETS_PER_PLATFORM = TARGETS_PER_ROW * TARGETS_PER_COLUMN
local X_SPACING = 7
local Y_OFFSET_FLOOR = 9.907 -- Measured from in-game differences
local Z_SPACING = 7

export type Type = {
    Reset: () -> nil,
    SetupTargets: (Player) -> nil,
}

type BoundingBox = {
    center: Vector3,
    size: Vector3,
}

local TargetPlatform = {}
TargetPlatform.__index = TargetPlatform

function TargetPlatform.new(player: Player)
    local self = setmetatable({}, TargetPlatform)

    self.Owner = player

    self.platform = ServerStorage.TargetPlatform:Clone()
    self.platform.Parent = Workspace.ActiveTargetPlatforms

    self.blocks = Instance.new("Folder")
    self.blocks.Name = "Blocks"
    self.blocks.Parent = self.platform
    
    self:SetupTargets(player)

    return self
end

function TargetPlatform:Reset()
    if self.blocks then
        for _, block in self.blocks:GetChildren() do
            if block:IsA("BasePart") then
                block:Destroy()
            end
        end
    end
    self:SetupTargets()
end

local function doBoxesIntersect(boxA: BoundingBox, boxB: BoundingBox): boolean
    local dx = math.abs(boxA.center.X - boxB.center.X)
    local dy = math.abs(boxA.center.Y - boxB.center.Y)
    local dz = math.abs(boxA.center.Z - boxB.center.Z)

    local combinedHalfSizeX = (boxA.size.X + boxB.size.X) / 2
    local combinedHalfSizeY = (boxA.size.Y + boxB.size.Y) / 2
    local combinedHalfSizeZ = (boxA.size.Z + boxB.size.Z) / 2

    return dx <= combinedHalfSizeX and dy <= combinedHalfSizeY and dz <= combinedHalfSizeZ
end

function TargetPlatform:SetupTargets(player: Player)
    -- Will hold a series of tuples consisting of {center, size}
    local originFacingCFrame 

    repeat
        local collision = false
        -- Generate platform coordinates
        local r = R_MIN + R_RANGE * math.random()
        local theta = TAU * math.random()
        local x = r * math.cos(theta)
        local y = Y_MIN + Y_RANGE * math.random()
        local z = r * math.sin(theta)

        -- Have the target face the origin
        originFacingCFrame = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))
        self.platform:PivotTo(originFacingCFrame)

        -- Check if it will intersect with any other target platform
        local centerCFrame: CFrame, size = self.platform:GetBoundingBox()
        local center = centerCFrame.Position
        local newBox = {center = center, size = size}
        for _, existingPlatform in Workspace.ActiveTargetPlatforms:GetChildren() do
            if self.platform ~= existingPlatform then
                local existingCFrame: CFrame, existingSize = existingPlatform:GetBoundingBox()
                local existingBox = {center = existingCFrame.Position, size = existingSize}
                collision = doBoxesIntersect(existingBox, newBox)
            end
        end
    until not collision

    for i = 0, TARGETS_PER_PLATFORM - 1 do
        -- Trial of creating a new part relative to the platform
        local partX = ((i // TARGETS_PER_ROW) - ((TARGETS_PER_COLUMN - 1) / 2)) * X_SPACING
        local partZ = ((i % TARGETS_PER_ROW) - ((TARGETS_PER_ROW - 1) / 2)) * Z_SPACING
        local partHeight = math.random(18) + 2
        local partY = Y_OFFSET_FLOOR + (partHeight / 2)
        
        local part = Instance.new("Part")
        part.Anchored = false
        part.Shape = Enum.PartType.Block
        part.Size = Vector3.new(3, partHeight, 2)
        part.CFrame = originFacingCFrame * CFrame.new(partX, partY, partZ)
        part.Parent = self.blocks
        part.Material = Enum.Material.SmoothPlastic
        part.BrickColor = BrickColor.random()
        part.CanCollide = true
        part.Name = "BlockTarget" .. i
        -- ensure target parts physics are handled by the players client
        part:SetNetworkOwner(player)
    end
end

return TargetPlatform
