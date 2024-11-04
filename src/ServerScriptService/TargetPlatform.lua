--!strict

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local SpawnPool = require(game:GetService("ServerScriptService"):WaitForChild("SpawnPool"))

local R_MIN = 160 
local R_RANGE = 140 -- x, z in [160, 300)
local TAU = 2 * math.pi
local Y_MIN = 4
local Y_RANGE = 28 -- y in [4, 32)

local TARGETS_PER_ROW = 5
local TARGETS_PER_COLUMN = 6
local TARGETS_PER_PLATFORM = TARGETS_PER_ROW * TARGETS_PER_COLUMN
local X_SPACING = 7
local Y_OFFSET_FLOOR = 9.907 -- Measured from in-game differences
local Z_SPACING = 7
local TARGET_WIDTH = 3
local TARGET_HEIGHT_RANGE = {4, 22}
local TARGET_DEPTH = 2
local TARGET_PLATFORM_PADDING = Vector3.new(4, TARGET_HEIGHT_RANGE[2], 4)

type BoundingBox = {
    center: Vector3,
    size: Vector3,
}

local TargetPlatform = {}
TargetPlatform.__index = TargetPlatform
TargetPlatform.count = 0

function TargetPlatform.new(player: Player, slice: number)
    local self = setmetatable({}, TargetPlatform)

    self.Owner = player
    self.slice = slice

    self.platform = ServerStorage.TargetPlatform:Clone()
    TargetPlatform.count += 1
    self.platform.Name = "TP" .. TargetPlatform.count
    self:SelectPosition()
    self.platform.Parent = Workspace.ActiveTargetPlatforms

    self.blocks = Instance.new("Folder")
    self.blocks.Name = "Blocks"
    self.blocks.Parent = self.platform
    
    self:SetupTargets(player)

    return self
end

function TargetPlatform:Reset(player: Player)
    self.platform.Parent = nil
    if self.blocks then
        for _, block in self.blocks:GetChildren() do
            if block:IsA("BasePart") then
                block:Destroy()
            end
        end
    end
    self.platform.Parent = nil
    self:SelectPosition()
    self.platform.Parent = Workspace.ActiveTargetPlatforms
    self:SetupTargets(player)
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

function TargetPlatform:SelectPosition()
    repeat
        local collision = false
        -- Generate platform coordinates
        local r = R_MIN + R_RANGE * math.random()
        local theta = TAU / SpawnPool.SIZE * (self.slice - 1 + math.random())
        local x = r * math.sin(theta)
        local y = Y_MIN + Y_RANGE * math.random()
        local z = r * math.cos(theta)

        -- Have the target face the origin
        local originFacingCFrame = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))
        self.platform:PivotTo(originFacingCFrame)

        -- Check if it will intersect with any other target platform
        local centerCFrame: CFrame, size: Vector3 = self.platform:GetBoundingBox()
        local center = centerCFrame.Position
        local newBox = {
            center = center,
            size = size + TARGET_PLATFORM_PADDING
        }
        for _, existingPlatform in Workspace.ActiveTargetPlatforms:GetChildren() do
            if self.platform ~= existingPlatform then
                local existingCFrame: CFrame, existingSize = existingPlatform:GetBoundingBox()
                local existingBox = {center = existingCFrame.Position, size = existingSize}
                collision = doBoxesIntersect(existingBox, newBox)
                if collision then break end
            end
        end
    until not collision
end

function TargetPlatform:SetupTargets(player: Player)
    local platformCFrame = self.platform:GetPivot()
    for i = 0, TARGETS_PER_PLATFORM - 1 do
        -- Trial of creating a new part relative to the platform
        local partX = ((i // TARGETS_PER_ROW) - ((TARGETS_PER_COLUMN - 1) / 2)) * X_SPACING
        local partZ = ((i % TARGETS_PER_ROW) - ((TARGETS_PER_ROW - 1) / 2)) * Z_SPACING
        local partHeight = math.random(unpack(TARGET_HEIGHT_RANGE))
        local partY = Y_OFFSET_FLOOR + (partHeight / 2)
        
        local part = Instance.new("Part")
        part.Anchored = false
        part.Shape = Enum.PartType.Block
        part.Size = Vector3.new(TARGET_WIDTH, partHeight, TARGET_DEPTH)
        part.CFrame = platformCFrame * CFrame.new(partX, partY, partZ)
        part.Material = Enum.Material.SmoothPlastic
        part.BrickColor = BrickColor.random()
        part.CanCollide = true
        part.Name = "BlockTarget" .. i
        part.Parent = self.blocks
        -- ensure target parts physics are handled by the players client
        part:SetNetworkOwner(player)
    end
end

function TargetPlatform:Destroy()
    self.platform:Destroy()
end

return TargetPlatform
