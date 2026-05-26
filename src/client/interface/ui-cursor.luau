--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local UiCursor = {}

local signals = require("../client-signal-registry")

export type UiCursor = typeof(UiCursor)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

Mouse.Icon = "rbxassetid://135894365640631"

local itemEquipped = false

UserInputService.MouseIconEnabled = false

signals.itemEquipped:Connect(function()
	UserInputService.MouseIconEnabled = true
end)

signals.itemUnequipped:Connect(function()
	UserInputService.MouseIconEnabled = false
end)

return UiCursor
