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
				Weight = 20,
			},
			Pitchfork = {
				Name = "Pitchfork",
				Weight = 50,
			},
			Plow = {
				Name = "Plow",
				Weight = 50,
			},
			Nothing = {
				Name = "Nothing",
				Weight = 1,
			},
		},
	},
	Nitwit = {
		Name = "NitWit",
		Weight = 13,
		Vitals = {
			HealthMultiplier = 1,
			DamageMultiplier = 1,
		},
		Weapons = {
			Torch = {
				Name = "Torch",
				Weight = 20,
			},
			Pitchfork = {
				Name = "Pitchfork",
				Weight = 10,
			},
			Nothing = {
				Name = "Nothing",
				Weight = 1,
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
				Weight = 50,
			},
			Pitchfork = {
				Name = "Pitchfork",
				Weight = 10,
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
