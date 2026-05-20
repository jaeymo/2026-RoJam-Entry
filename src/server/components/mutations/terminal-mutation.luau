--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)
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
	MutationService:initializeEntityMutation("Terminal", self.instance)

	local randomMutationTime = math.random(5, 10)
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
	Logging = true,
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("TerminalMutation", TerminalMutation.classy)

return TerminalMutation
