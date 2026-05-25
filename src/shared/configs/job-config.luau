--!strict
local JobConfig = {
	Farmer = {
		Name = "Farmer",
		Weight = 10,
		Vitals = {
			HealthMultiplier = 1,
			DamageMultiplier = 1.25,
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
		Weight = 20,
		Vitals = {
			HealthMultiplier = 1,
			DamageMultiplier = 1,
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

return table.freeze(JobConfig)
