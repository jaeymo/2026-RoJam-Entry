--!strict
local WanderingAIConfig = {
	Vitals = {
		Health = 3,
		MaxHealth = 3,
	},

	Movement = {

		DefaultWalkSpeed = 16,
	},

	Pathfinding = {
		SpaceOutTime = 3,
		DistractedTime = 3,

		SightDistance = 50,
		SearchTimeout = 1,
		StopDistance = 40,
	},
}

export type WanderingAIConfig = typeof(WanderingAIConfig)

return WanderingAIConfig
