--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 0.2,
	AggressiveMutationChance = 0.1,

	Mutations = {
		Aggressive = {
			Weight = 1,
			Name = "Aggressive",
			ActivationDelayRange = { 15, 60 },
		},

		Terminal = {
			Weight = 1,
			Name = "Terminal",
			ActivationDelayRange = { 20, 60 },
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
