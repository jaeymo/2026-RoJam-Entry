--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FLOWER_CONFIG = {
	colors = {
		Purple = Color3.fromRGB(170, 0, 255),
		-- Yellow = Color3.fromRGB(255, 255, 0),
		Red = Color3.fromRGB(219, 43, 43),
	},

	GuiColors = {
		Purple = {
			Primary = Color3.fromRGB(75, 2, 111),
			Secondary = Color3.fromRGB(216, 138, 255),
			Tertiary = Color3.fromRGB(56, 23, 86),
		},
		-- Yellow = Color3.fromRGB(255, 255, 0),
		Red = {
			Primary = Color3.fromRGB(130, 22, 22),
			Secondary = Color3.fromRGB(234, 106, 106),
			Tertiary = Color3.fromRGB(73, 1, 1),
		},
	},

	models = {
		Red = (ReplicatedStorage.assets.models:FindFirstChild("props") :: Folder):FindFirstChild("RoseBush"),
		Purple = (ReplicatedStorage.assets.models:FindFirstChild("props") :: Folder):FindFirstChild("LavenderBush"),
	},

	tags = {
		Red = "RoseBush",
		Purple = "LavenderBush",
	},

	getAmountFlowersToSpawn = function(amountNodes: number): number
		return math.round(amountNodes / 2)
	end,
}

return table.freeze(FLOWER_CONFIG) :: typeof(FLOWER_CONFIG)
