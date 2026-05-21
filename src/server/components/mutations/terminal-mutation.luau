--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local configs = ReplicatedStorage.shared.configs

local Classy = require(ReplicatedStorage.packages.classy)
local MutationConfig = require(configs["mutations-config"])
local MutationService = require(ServerScriptService.services["mutation-service"])

local TerminalMutation = {}
TerminalMutation.__index = TerminalMutation

export type TerminalMutation = typeof(setmetatable(
	{} :: {
		instance: Model,
		janitor: Classy.Janitor,
	},
	TerminalMutation
))

function TerminalMutation.new(instance: Instance, janitor: Classy.Janitor): TerminalMutation
	return setmetatable({
		instance = instance :: Model,
		janitor = janitor,
	}, TerminalMutation)
end

function TerminalMutation.init(self: TerminalMutation)
	print("TERMINAL!")
	MutationService:initializeEntityMutation("Terminal", self.instance)

	local activationDelayRange = MutationConfig.Mutations.Terminal.ActivationDelayRange
	local randomMutationTime = math.random(activationDelayRange[1], activationDelayRange[2])
	local flag = false

	task.delay(randomMutationTime, function()
		if flag then
			return
		end
		MutationService:mutateEntity("Terminal", self.instance)
	end)

	self.janitor:Add(function()
		flag = true
	end)
end

TerminalMutation.classy = Classy.create("TerminalMutation", TerminalMutation, {
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("TerminalMutation", TerminalMutation.classy)

return TerminalMutation
