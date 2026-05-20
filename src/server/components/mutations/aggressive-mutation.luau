--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)
local MutationService = require(ServerScriptService.services["mutation-service"])

local AggressiveMutation = {}
AggressiveMutation.__index = AggressiveMutation

export type AggressiveMutation = typeof(setmetatable(
	{} :: {
		instance: Model,
		janitor: Classy.Janitor,
	},
	AggressiveMutation
))

function AggressiveMutation.new(instance: Instance, janitor: Classy.Janitor): AggressiveMutation
	return setmetatable({
		instance = instance :: Model,
		janitor = janitor,
	}, AggressiveMutation)
end

function AggressiveMutation.init(self: AggressiveMutation)
	MutationService:initializeEntityMutation("Aggressive", self.instance)

	local randomMutationTime = math.random(5, 10)
	local flag = false

	task.delay(randomMutationTime, function()
		if flag then
			return
		end

		MutationService:mutateEntity("Aggressive", self.instance)
	end)

	self.janitor:Add(function()
		flag = true
	end)
end

AggressiveMutation.classy = Classy.create("AggressiveMutation", AggressiveMutation, {
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("AggressiveMutation", AggressiveMutation.classy)

return AggressiveMutation
