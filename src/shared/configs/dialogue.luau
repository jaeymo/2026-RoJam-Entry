return {
	Plague_Doctor = {
		Dialogue = {
			{
				Text = "The sickness spreads faster every night.",

				Followups = {
					"People wait until it is too late.",
					"I cannot save everyone.",
				},
			},

			{
				Text = "Do not touch the infected unless you know what you are doing.",

				Followups = {
					"Most die before morning.",
					"The fever changes them.",
				},
			},

			{
				Text = "You look healthier than most around here.",
			},
		},

		OutOfMessages = {
			"Return if you need treatment.",
			"I still have work to do.",
			"Stay away from the sick.",
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
				Text = "People have been disappearing at night.",

				Followups = {
					"No one goes outside after the dark anymore.",
				},
			},

			{
				Text = "You should not stay out here too long.",
			},

			{
				Text = "Can i get some food?",
			},
		},

		InfectedLevel = {
			[1] = {
				"I don't feel well...",
				"My head hurts..",
				"I think i'm getting sick...",
				"Please help me",
			},

			[2] = {
				"DON'T LEAVE ME",
				"PLEASE HELP ME!!",
				"I'M GOING TO DIE",
				"YOU HAVE TO HELP ME",
				"I HAVE A FAMILY PLEASE HELP ME",
			},
		},

		OutOfMessages = {
			"Doctor?",
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
}
