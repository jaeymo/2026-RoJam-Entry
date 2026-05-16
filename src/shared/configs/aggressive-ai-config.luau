--!strict
local AggressiveAiConfig = {
	Vitals = {
		Health = 10,
		MaxHealth = 10,
	},

	Movement = {
		WalkSpeed = 16,
	},

	Pathfinding = {
		SightDistance = 50,
		SearchTimeout = 1,
		StopDistance = 5,
	},
}

export type AggressiveAiConfig = typeof(AggressiveAiConfig)

return AggressiveAiConfig
