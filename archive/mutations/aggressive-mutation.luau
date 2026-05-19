--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)

local AggressiveMutation = {}
AggressiveMutation.__index = AggressiveMutation

export type AggressiveMutation = typeof(setmetatable(
	{} :: {
		instance: Instance,
		janitor: Classy.Janitor,
	},
	AggressiveMutation
))

function AggressiveMutation.new(instance: Instance, janitor: Classy.Janitor): AggressiveMutation
	return setmetatable({
		instance = instance,
		janitor = janitor,
	}, AggressiveMutation)
end

AggressiveMutation.classy = Classy.create("AggressiveMutation", AggressiveMutation, {
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("AggressiveMutation", AggressiveMutation.classy)

return AggressiveMutation
