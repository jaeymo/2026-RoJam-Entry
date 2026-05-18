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
		maxRooms = 500,
		minLateStretch = 3,
		maxLateStretch = 5,
	},

	-- a +- value that randomly decides the game phases. for example, early could end at 6 (8-2), while middle could end at 17 (16 + 1)
	-- phaseLeniency = 2,

	-- gamePhases = {
	-- 	early = 8,
	-- 	middle = 16,
	-- 	late = 24,
	-- } :: { [string]: number },
}

return table.freeze(GENERATION_CONFIG) :: typeof(GENERATION_CONFIG)
