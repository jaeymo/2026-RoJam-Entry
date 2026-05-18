return {
	Average_NPC_Amount = 5,
	Average_Rat_Amount = 5,

	--// from a 100
	Barricade_Chance = 10,
	DeadBody_Chance = 25,

	--// idk what a spawn node is supposed to contain
	SpawnNode = {},

	Mutations = {
		RandomMutate = {
			Aggressive_Mutation_Chance = 45, --// chance an npc bcomes aggressive randomly
			Terminal_Mutation_Chance = 50, --// chance an npc dies within a timeframe
		},

		AnotherRandomMutate = {
			Aggressive_Mutation_Chance = 35, --// chance an npc bcomes aggressive randomly
			Terminal_Mutation_Chance = 20, --// chance an npc dies within a timeframe
		},
	},

	NPC_Interactions = {
		Plague_Doctor = {
			Dialogue = {
				{
					YOU = "Hi.",
					NPC = "wsg",

					Followups = {
						{
							YOU = "How's it going?",
							NPC = "I am well enough, the sick need attention i guess...",
						},
						{
							YOU = "So... Your a doctor? like a plague doctor, haha get it?",
							NPC = "That was not funny..",
						},
					},
				},

				{
					YOU = "BROO",
					NPC = "What?",

					Followups = {
						{
							YOU = "Chicken nut",
							NPC = "0/10 Ragebait",
						},
						{
							YOU = "Chicken butt",
							NPC = "Do you wish to die?",
						},
					},
				},
			},

			OutOfMessages = {
				YOU = {
					"I have nothing else to say.",
					"Thank you? i guess?",
				},

				NPC = {
					"Return when you need me.",
				},
			},

			Functions = {
				Trade = function(NPC: Instance)
					print(`does trading with {NPC.Name}`)
				end,
			},
		},

		NonAggressiveNPCs = {
			Dialogue = {
				{
					YOU = "Hi.",
					NPC = "Hello there.",

					Followups = {
						{
							YOU = "What are you doing?",
							NPC = "Just trying to survive.",
						},
						{
							YOU = "Need anything?",
							NPC = "Don't kill me please.",
						},
					},
				},

				{
					YOU = "How's it going?",
					NPC = "Could be worse.",

					Followups = {
						{
							YOU = "Stay safe.",
							NPC = "You too.",
						},
					},
				},
			},

			Specials = {
				Infected = {
					"DON'T LEAVE ME",
					"PLEASE HELP ME!!",
					"I'M GOING TO DIE",
					"YOU HAVE TO HELP ME",
					"I HAVE A FAMILY PLEASE HELP ME",
				},
			},

			OutOfMessages = {
				YOU = {
					"I should go.",
					"Goodbye.",
				},

				NPC = {
					"Damn doctors.",
					"Yeah yeah whatever",
				},
			},

			Functions = {
				Trade = function(NPC: Instance)
					print(`tried trading with trading NPC: {NPC.Name}`)
				end,

				Cure = function(NPC: Instance)
					print(`tried curing random infected NPC: {NPC.Name}`)
				end,
			},
		},
	},
}
