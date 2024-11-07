--!strict

type BoundingBox = {
    center: Vector3,
    size: Vector3,
}

type Cylinder = {
    center: Vector3,
    radius: number,
    height: number
}

--[[Assumes axis-aligned cylinder with height in the Y direction]]
local function doCylindersIntersect(cylA: Cylinder, cylB: Cylinder): boolean
    local dx = math.abs(cylA.center.X - cylB.center.X)
    local dz = math.abs(cylA.center.Z - cylB.center.Z)

    local dy = math.abs(cylA.center.Y - cylB.center.Y)
    local combinedHalfSizeY = (cylA.height + cylB.height) / 2

    return dx^2 + dz^2 <= (cylA.radius + cylB.radius)^2 and dy <= combinedHalfSizeY
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

return {
    doBoxesIntersect = doBoxesIntersect,
    doCylindersIntersect = doCylindersIntersect,
}