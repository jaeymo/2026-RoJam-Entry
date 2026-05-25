--!strict
local JobConfig = {
	Farmer = {
		Name = "Farmer",
		Weight = 10,
		Vitals = {
			HealthMultiplier = 1,
			DamageMultiplier = 1.25,
		},
		Movement = {
			StaminaMultiplier = 1,
			DamageMultiplier = 1.25,

			StaminaRecoveryRateMultiplier = 1.25,
			StaminaRecoveryTimeMultiplier = 1.5,

			SpeedMultiplier = 1.1,
		},
		Weapons = {
			Torch = {
				Name = "Torch",
				Weight = 2,
			},
			PitchFork = {
				Name = "PitchFork",
				Weight = 5,
			},
			Plow = {
				Name = "Plow",
				Weight = 5,
			},
			Nothing = {
				Name = "Nothing",
				Weight = 1,
			},
		},
	},
	Nitwit = {
		Name = "NitWit",
		Weight = 3,
		Vitals = {
			HealthMultiplier = 1,
			DamageMultiplier = 1,
		},

		Movement = {
			StaminaMultiplier = 1,
			DamageMultiplier = 1,

			StaminaRecoveryRateMultiplier = 1,
			StaminaRecoveryTimeMultiplier = 1,

			SpeedMultiplier = 1,
		},
		Weapons = {
			Torch = {
				Name = "Torch",
				Weight = 2,
			},
			PitchFork = {
				Name = "PitchFork",
				Weight = 1,
			},
			Nothing = {
				Name = "Nothing",
				Weight = 10,
			},
		},
	},

	Knight = {
		Name = "Knight",
		Weight = 5,
		Vitals = {
			HealthMultiplier = 2,
			DamageMultiplier = 1.5,
		},
		Movement = {
			StaminaMultiplier = 3,
			DamageMultiplier = 1.5,

			StaminaRecoveryRateMultiplier = 2,
			StaminaRecoveryTimeMultiplier = 1.5,

			SpeedMultiplier = 1.5,
		},
		Weapons = {
			Sword = {
				Name = "Sword",
				Weight = 5,
			},
			PitchFork = {
				Name = "PitchFork",
				Weight = 1,
			},
			Nothing = {
				Name = "Nothing",
				Weight = 1,
			},
		},
	},
}

export type JobConfig = typeof(JobConfig)

export type JobConfigEntry = {
	Name: string,
	Weight: number,
	Vitals: {
		HealthMultiplier: number,
		DamageMultiplier: number,
	},
	Weapons: {
		[string]: {
			Name: string,
			Weight: number,
		},
	},
}

return table.freeze(JobConfig)
