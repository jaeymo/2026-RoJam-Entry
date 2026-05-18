--!strict
local GENERATION_CONFIG = {
	worldOrigin = Vector3.yAxis * 100,
	parent = workspace:WaitForChild("runtime"):WaitForChild("map"),

	phaseLeniency = 2,

	gamePhases = {
		early = 5,
		middle = 5,
		late = 5,
	} :: { [string]: number },

	lateGameGeneration = {
		maxRooms = 250,
		minLateStretch = 3,
		maxLateStretch = 5,
	},
}

return table.freeze(GENERATION_CONFIG) :: typeof(GENERATION_CONFIG)
