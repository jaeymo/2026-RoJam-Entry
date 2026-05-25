--!strict
local InfectedConfig = {
	[0] = {
		Weight = 10,

		StaminaMultiplier = 1,
		DamageMultiplier = 1,

		ParanoiaLevel = 1,
		ChanceOfClarifyingSymptoms = 0,
	},

	[1] = {
		Weight = 5,

		StaminaMultiplier = 0.6,
		DamageMultiplier = 1.2,

		ParanoiaLevel = 3,
		ChanceOfClarifyingSymptoms = 0.2,
	},

	[2] = {
		Weight = 3,

		StaminaMultiplier = 0.4,
		DamageMultiplier = 1.5,

		ParanoiaLevel = 5,
		ChanceOfClarifyingSymptoms = 0.5,
	},
}

export type InfectedConfig = typeof(InfectedConfig)

return InfectedConfig
