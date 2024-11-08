local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local resetGameEvent = ReplicatedStorage.Events.ResetGameEvent
local showCompleteUIEvent = ReplicatedStorage.Events.ShowCompleteUIEvent
local completeGUIPrefab = ReplicatedStorage:WaitForChild("CompleteGUIPrefab")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local completeGUI
local resetButton

local function enableUI(isEnabled: boolean)
	completeGUI.Enabled = isEnabled
end

local function initialize()
	-- Add new gui instance to player gui, hidden
	completeGUI = completeGUIPrefab:Clone()
	completeGUI.Name = "CompleteGUI"
	completeGUI.Enabled = false
	completeGUI.Parent = playerGui

	-- When reset button hit, notify server to reset and hide the gui
	local resetButton = completeGUI.Dimmer.ResetButton
	resetButton.Activated:Connect(function()
		resetGameEvent:FireServer()
		enableUI(false)
	end)

	-- receives event when launch attempts reach 0, show the gui
	showCompleteUIEvent.OnClientEvent:Connect(function()
		enableUI(true)
	end)
end

initialize()