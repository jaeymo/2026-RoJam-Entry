--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 0.8,
	AggressiveMutationChance = 0.5,

	Mutations = {
		Aggressive = {
			Weight = 25,
			Name = "Aggressive",
		},
		Terminal = {
			Weight = 85,
			Name = "Terminal",
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
