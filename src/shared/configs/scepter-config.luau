--!strict
local SCEPTER_CONFIG = {
	chanceToFollowUpBatterWithPoke = 0.75,

	attacks = {
		["Poke"] = {
			Damage = 10,
			HitboxSize = Vector3.one * 5,
		},

		["Batter"] = {
			Damage = 10,
			HitboxSize = Vector3.one * 5,
		},

		["Peck"] = {
			Damage = 10,
			HitboxSize = Vector3.one * 5,
		},

		["Bonk"] = {
			Damage = 10,
			HitboxSize = Vector3.one * 5,
		},
	},
}

export type AttackData = {
	Damage: number,
	HitboxSize: Vector3,
}

return table.freeze(SCEPTER_CONFIG) :: typeof(SCEPTER_CONFIG)
