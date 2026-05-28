return {
	Average_NPC_Amount = 5,
	Average_Rat_Amount = 5,

	--// from a 100
	Barricade_Chance = 10,
	DeadBody_Chance = 25,

	Infection = {
		Min_MaxHealth = 20,

		Health_Drain = 10,
		Health_Take = 5,

		MaxHealth_Drain = 15,
		MaxHealth_Take = 2,

		Damage_PerHit = 5,
	},

	Items = {
		[Enum.KeyCode.One] = "Scepter",
		[Enum.KeyCode.Two] = "FlintAndSteel",
	},

	Shop = {
		Garlic = {
			Icon = "rbxassetid://121932471238553",
			Price = 4,
		},

		Emeralds = {
			Icon = "rbxassetid://73785031998645",
			Price = 2,
		},
	},

	--// idk what a spawn node is supposed to contain
	SpawnNode = {},
}
