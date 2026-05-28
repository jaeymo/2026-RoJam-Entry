--!strict
local FLOWER_CONFIG = {
	colors = {
		Purple = Color3.fromRGB(170, 0, 255),
		Yellow = Color3.fromRGB(255, 255, 0),
		Green = Color3.fromRGB(0, 150, 0),
	},

	getAmountFlowersToSpawn = function(amountNodes: number): number
		return math.round(amountNodes / 2)
	end,
}

return table.freeze(FLOWER_CONFIG) :: typeof(FLOWER_CONFIG)
