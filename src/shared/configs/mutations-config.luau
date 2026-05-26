--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 0,
	AggressiveMutationChance = 0,

	Mutations = {
		Aggressive = {
			Weight = 1,
			Name = "Aggressive",
			ActivationDelayRange = { 5, 6 },
		},

		Terminal = {
			Weight = 1,
			Name = "Terminal",
			ActivationDelayRange = { 4, 5 },
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
