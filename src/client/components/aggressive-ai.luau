--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI

export type AggressiveAI = typeof(setmetatable(
	{} :: {
		entity: Model,

		currentState: string,

		janitor: Classy.Janitor,
	},
	AggressiveAI
))

function AggressiveAI.new(entity: Instance, janitor: Classy.Janitor): AggressiveAI
	return setmetatable({
		entity = entity :: Model,
		currentState = "None",
		janitor = janitor,
	}, AggressiveAI)
end

function AggressiveAI.Init(self: AggressiveAI)
	self.janitor:Add(self.entity:GetAttributeChangedSignal("State"):Connect(function()
		local oldState = self.currentState
		local exitFunc = self["Exit" .. oldState]

		if exitFunc then
			exitFunc()
		end

		local newState = self.entity:GetAttribute("State") :: string
		local func = self[newState]

		if func then
			func()
		end

		self.currentState = newState
	end))
end

function AggressiveAI.Destroy(self: AggressiveAI)
	self.janitor:Cleanup()
end

function AggressiveAI.Chasing(self: AggressiveAI) end

function AggressiveAI.ExitChasing(self: AggressiveAI) end

function AggressiveAI.Hunting(self: AggressiveAI) end

function AggressiveAI.ExitHunting(self: AggressiveAI) end

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
