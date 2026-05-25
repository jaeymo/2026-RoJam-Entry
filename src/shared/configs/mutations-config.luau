--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 0.25,
	AggressiveMutationChance = 0.7,

	Mutations = {
		Aggressive = {
			Weight = 1,
			Name = "Aggressive",
			ActivationDelayRange = { 5, 6 },
		},

		Terminal = {
			Weight = 1,
			Name = "Terminal",
			ActivationDelayRange = { 2, 3 },
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
