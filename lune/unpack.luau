local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local place = process.args[1]
if place:sub(-#".rbxl") ~= ".rbxl" then
    error("Place file must end in .rbxl")
end
local file = fs.readFile(process.args[1])
local placeModel = roblox.deserializePlace(file)

local decompressedPlace = roblox.serializePlace(placeModel, true)
fs.writeFile(place .. "x", decompressedPlace)