--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local configs = ReplicatedStorage.shared.configs

local Classy = require(ReplicatedStorage.packages.classy)
local MutationConfig = require(configs["mutations-config"])
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

	local activationDelayRange = MutationConfig.Mutations.Aggressive.ActivationDelayRange
	local randomMutationTime = math.random(activationDelayRange[1], activationDelayRange[2])
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
