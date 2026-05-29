--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roman = require(ReplicatedStorage.shared.utils.roman)
local Viewer = require(ReplicatedStorage.packages.viewer)

local UiTolls = {}

export type UiTolls = typeof(UiTolls)

function UiTolls.jaegarInit(self: UiTolls)
	local deathTolls = Players.LocalPlayer
		:WaitForChild("PlayerGui")
		:WaitForChild("ui-assets")
		:WaitForChild("Canvas")
		:WaitForChild("DeathTolls")
		:WaitForChild("Amount") :: TextLabel

	Viewer.WatchAttribute(Players.LocalPlayer, "Cured_Success", function(newValue: number)
		deathTolls.Text = Roman.ToRoman(newValue)
	end, false)
end

return UiTolls
