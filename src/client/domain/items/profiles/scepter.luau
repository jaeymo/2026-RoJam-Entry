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
	x.animationObject:Play("ViewModelBonk")
end

return Scepter
