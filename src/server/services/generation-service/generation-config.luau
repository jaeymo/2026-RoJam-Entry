--!strict
local GENERATION_CONFIG = {
	worldOrigin = Vector3.yAxis * 100,
	parent = workspace:WaitForChild("runtime"):WaitForChild("map"),

	gamePhases = {
		early = {
			name = "early",
			length = 50,

			safezones = {
				enabled = true,

				minSpacing = 4,
				maxSpacing = 7,

				guaranteedAtEnd = true,
			},
		},
		middle = {
			name = "middle",
			length = 12,

			safezones = {
				enabled = true,

				minSpacing = 3,
				maxSpacing = 5,

				guaranteedAtEnd = true,
			},
		},
		late = {
			name = "late",

			safezones = {
				enabled = true,

				minSpacing = 5,
				maxSpacing = 10,

				guaranteedAtEnd = true,
			},
		},
	},

	lateGameGeneration = {
		maxRooms = 250,
		minLateStretch = 3,
		maxLateStretch = 5,
	},
}

return table.freeze(GENERATION_CONFIG) :: typeof(GENERATION_CONFIG)
