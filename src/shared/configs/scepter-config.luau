--!strict
local SCEPTER_CONFIG = {
	chanceToFollowUpBatterWithPoke = 0.85,

	attacks = {
		["Poke"] = {
			Damage = 1,
			HitboxSize = Vector3.new(3, 3, 4),
			StunDuration = 1,
		},

		["Batter"] = {
			Damage = 1,
			HitboxSize = Vector3.one * 4,
			StunDuration = 1,
		},

		["Peck"] = {
			Damage = 1,
			HitboxSize = Vector3.one * 4,
			StunDuration = 1,
		},

		["Bonk"] = {
			Damage = 1,
			HitboxSize = Vector3.one * 4,
			StunDuration = 1,
		},
	},
}

export type AttackData = {
	Damage: number,
	HitboxSize: Vector3,
	StunDuration: number,
}

return table.freeze(SCEPTER_CONFIG) :: typeof(SCEPTER_CONFIG)
