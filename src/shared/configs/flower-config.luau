--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FLOWER_CONFIG = {
	colors = {
		Purple = Color3.fromRGB(170, 0, 255),
		-- Yellow = Color3.fromRGB(255, 255, 0),
		Red = Color3.fromRGB(219, 43, 43),
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
