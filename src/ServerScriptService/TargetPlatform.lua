--!strict

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Geometry = require(ServerScriptService:WaitForChild("Geometry"))
local LeaderboardService = require(ServerScriptService:WaitForChild("LeaderboardService"))
local SpawnPool = require(game:GetService("ServerScriptService"):WaitForChild("SpawnPool"))

local R_MIN = 100
local R_RANGE = 140 -- x, z in [100, 240) + 60 (preventing collision with dividers)
local TAU = 2 * math.pi
local Y_MIN = 6
local Y_RANGE = 26 -- y in [6, 32)

local TARGETS_PER_ROW = 5
local TARGETS_PER_COLUMN = 6
local TARGETS_PER_PLATFORM = TARGETS_PER_ROW * TARGETS_PER_COLUMN
local X_SPACING = 7
local Y_OFFSET_FLOOR = 9.907 -- Measured from in-game differences
local Z_SPACING = 7
local TARGET_WIDTH = 3
local TARGET_HEIGHT_RANGE = {5, 22}
local TARGET_DEPTH = 2
local TARGET_PLATFORM_PADDING = Vector3.new(4, TARGET_HEIGHT_RANGE[2], 4)

local count = 0

local TargetPlatform = {}
TargetPlatform.__index = TargetPlatform

function TargetPlatform.new(player: Player, slice: number)
    local self = setmetatable({}, TargetPlatform)

    self.Owner = player
    self.slice = slice

    self.platform = ServerStorage.TargetPlatform:Clone()
    count += 1
    self.platform.Name = "TP" .. count
    self:SelectPosition()
    self.platform.Parent = Workspace.ActiveTargetPlatforms

    self.blocks = Instance.new("Folder")
    self.blocks.Name = "Blocks"
    self.blocks.Parent = self.platform

    self.yStarts = {} :: {[string]: number}
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

function TargetPlatform:SelectPosition()
    repeat
        local collision = false
        -- Generate platform coordinates
        local r = R_MIN + R_RANGE * math.random()
        local theta = TAU / SpawnPool.SIZE * (self.slice - 1 + math.random())
        local x = r * math.sin(theta) + 60 * math.sin((2*self.slice - 1) / (2*SpawnPool.SIZE) * TAU)
        local y = Y_MIN + Y_RANGE * math.random()
        local z = r * math.cos(theta) + 60 * math.cos((2*self.slice - 1) / (2*SpawnPool.SIZE) * TAU)

        -- Have the target face the origin
        local originFacingCFrame = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, 0))

        -- Make sure target doesn't collide with terrain
        local raycastResult = workspace:Raycast(originFacingCFrame.Position, -Vector3.yAxis * Y_MIN)
        if raycastResult then
            originFacingCFrame *= CFrame.new(0, Y_MIN - raycastResult.Distance, 0)
        end
        self.platform:PivotTo(originFacingCFrame)

        -- Check if it will intersect with any other target platform
        local centerCFrame: CFrame, size: Vector3 = self.platform:GetBoundingBox()
        -- Move the center up by half the Y-value, since the ExtentCFrame.Position
        local center = centerCFrame.Position + Vector3.new(0, TARGET_HEIGHT_RANGE[2] / 2, 0)
        -- Pad the platform assuming dimensions of target parts
        size += TARGET_PLATFORM_PADDING

        local newCylinder = {center = center, radius = size.X / 2, height = size.Y}
        for _, existingPlatform in Workspace.ActiveTargetPlatforms:GetChildren() do
            if self.platform ~= existingPlatform then
                local existingCFrame: CFrame, existingSize = existingPlatform:GetBoundingBox()
                local existingCylinder = {center = existingCFrame.Position, radius = existingSize.X / 2, height = existingSize.Y}
                collision = Geometry.doCylindersIntersect(existingCylinder, newCylinder)
                print(collision)
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

        self.yStarts[part.Name] = part.CFrame.Y
    end

    local knockedOver: RBXScriptConnection
    local function check()
        local blocksDestroyed = {}
        for blockName, startingY in self.yStarts do
            local block = self.blocks:FindFirstChild(blockName)
            if block and block:IsA("Part") and block.CFrame.Y <= startingY - 0.75 then
                table.insert(blocksDestroyed, blockName)
            end
        end
        for _, blockName in blocksDestroyed do
            self.yStarts[blockName] = nil
        end
        if #blocksDestroyed > 0 then
            LeaderboardService.BlocksDestroyed(player, #blocksDestroyed)
        end
        if not next(self.yStarts) then
            knockedOver:Disconnect()
            task.delay(3, function()
                self:Reset(player)
            end)
        end
    end
    knockedOver = RunService.Heartbeat:Connect(check)
end

function TargetPlatform:Destroy()
    self.platform:Destroy()
end

return TargetPlatform
