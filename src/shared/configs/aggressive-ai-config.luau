--!strict
local AggressiveAiConfig = {
	Vitals = {
		Health = 10,
		MaxHealth = 10,
	},

	Movement = {
		MaxStamina = 10,
		StaminaDrain = 1,
		StaminaHeal = 1,

		StaminaRecoveryRate = 0.25,
		StaminaRecoveryTime = 3,

		ExhaustedSpeed = 8,
		DefaultWalkSpeed = 10,
		ChasingSpeed = 20,
	},

	Attacks = {
		MainAttackCooldown = 3,
		MainAttackStaminaCost = 3,
	},

	Pathfinding = {
		SightDistance = 50,
		SearchTimeout = 1,
		StopDistance = 10,
	},
}

export type AggressiveAiConfig = typeof(AggressiveAiConfig)

return AggressiveAiConfig
