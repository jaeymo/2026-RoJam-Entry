--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 0.3,
	AggressiveMutationChance = 0.1,

	Mutations = {
		Aggressive = {
			Weight = 45,
			Name = "Aggressive",
			ActivationDelayRange = { 5, 6 },
		},
		Terminal = {
			Weight = 25,
			Name = "Terminal",
			ActivationDelayRange = { 5, 6 },
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
