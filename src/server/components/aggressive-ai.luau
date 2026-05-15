--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)

local AIPathService = require(ServerScriptService.services["ai-path-service"])

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI

export type AggressiveAI = typeof(setmetatable(
	{} :: {
		entity: Model,
		janitor: Classy.Janitor,
		target: Model?,

		pathData: { Path: Path, Waypoints: { PathWaypoint } }?,
	},
	AggressiveAI
))

function AggressiveAI.new(character: Instance, janitor: Classy.Janitor): AggressiveAI
	return setmetatable({
		entity = character :: Model,
		janitor = janitor,
	}, AggressiveAI)
end

function AggressiveAI.checkForTarget(self: AggressiveAI)
	if not Players:GetPlayers()[1] then
		error("NoPlr")
	end

	self.target = Players:GetPlayers()[1]
end

function AggressiveAI.ChaseLoop(self: AggressiveAI)
	self:checkForTarget()

	if not self.target then
		return
	end

	local entityPos = self.entity:GetPivot().Position
	local targetPos = self.target:GetPivot().Position
	self.pathData = AIPathService:CreatePath(entityPos, targetPos)
end

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
