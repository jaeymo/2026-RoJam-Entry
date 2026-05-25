--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Scepter = {}

export type Scepter = typeof(Scepter)

function Scepter.equip(self: Scepter)
	-- print(self)
end

function Scepter.unequip(self: Scepter)
	-- print(self)
end

function Scepter.primary(self: Scepter)
	local x = require(ReplicatedStorage.client.controllers["viewmodel-controller"])

	local names = {
		"ViewModelBatter",
		"ViewModelBonk",
		"ViewModelPoke",
	}

	local selection = names[math.random(1, #names)]
	print(selection)
	x.animationObject:Play(selection)
end

return Scepter
