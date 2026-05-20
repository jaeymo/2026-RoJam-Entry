--!strict
local WanderingAIConfig = {
	Vitals = {
		Health = 3,
		MaxHealth = 3,
	},

	Movement = {
		MaxStamina = 20,
		StaminaDrain = 1,
		StaminaHeal = 1,

		StaminaRecoveryRate = 0.25,
		StaminaRecoveryTime = 3,

		BreakTime = { Min = 30, Max = 50, Weight = 10 },

		DefaultWalkSpeed = 6,
	},

	Animations = {
		Wandering = "Wander",
		Resting = "Rest",
	},

	Pathfinding = {
		TargetMemoryLength = 2,
		SpaceOutTime = 3,
		DistractedTime = 3,

		SightDistance = 50,
		SearchTimeout = 1,
		StopDistance = 40,
	},
}

export type WanderingAIConfig = typeof(WanderingAIConfig)

return WanderingAIConfig
