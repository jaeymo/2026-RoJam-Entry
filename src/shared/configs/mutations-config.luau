--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 1,
	AggressiveMutationChance = 0.1,

	Mutations = {
		Aggressive = {
			Weight = 1000,
			Name = "Aggressive",
			ActivationDelayRange = { 5, 6 },
		},
		Terminal = {
			Weight = 1,
			Name = "Terminal",
			ActivationDelayRange = { 5, 6 },
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
