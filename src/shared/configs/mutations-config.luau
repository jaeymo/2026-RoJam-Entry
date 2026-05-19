--!strict
local MUTATIONS_CONFIG = {
	MutationChance = 0.75,

	Mutations = {
		Aggressive = {
			Weight = 45,
			Name = "Aggressive",
		},
		Terminal = {
			Weight = 25,
			Name = "Aggressive",
		},
	},
}

return table.freeze(MUTATIONS_CONFIG) :: typeof(MUTATIONS_CONFIG)
