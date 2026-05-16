--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)

local AIPathService = require(ServerScriptService.services["ai-path-service"])
local Raydar = require(ReplicatedStorage.shared.utils.raydar)

local AIConfig = require(ReplicatedStorage.shared.configs["aggressive-ai-config"])

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI
export type AggressiveAI = typeof(setmetatable(
	{} :: {
		entity: Model,
		human: Humanoid,
		janitor: Classy.Janitor,
		target: Model?,

		targetVisible: boolean,

		chaseLoopConnection: thread?,

		pathData: { Path: Path, Waypoints: { PathWaypoint }, Completed: boolean }?,
	},
	AggressiveAI
))

function AggressiveAI.new(character: Instance, janitor: Classy.Janitor): AggressiveAI
	return setmetatable({
		entity = character :: Model,
		targetVisible = false,
		human = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid,
		janitor = janitor,
	}, AggressiveAI)
end

function AggressiveAI.init(self: AggressiveAI)
	self:ChaseLoop()
end

function AggressiveAI.checkForTarget(self: AggressiveAI)
	local desiredTarget = CollectionService:GetTagged("AIAttractor")[1]
	if not desiredTarget then
		error("NoPlr")
	end

	-- self.target = Players:GetPlayers()[1]
	self.target = desiredTarget
end

function AggressiveAI.getPositioning(self: AggressiveAI): (Vector3, Vector3)
	return self.target:GetPivot().Position, self.entity:GetPivot().Position
end

function AggressiveAI.PeepTarget(self: AggressiveAI)
	local targetPos, entityPos = self:getPositioning()

	local directionToTarget = (targetPos - entityPos).Unit
	local maxDistance = AIConfig.Pathfinding.SightDistance

	return Raydar:Fire(entityPos, directionToTarget, maxDistance, Raydar.RayTypes.HitWalls)
end

function AggressiveAI.MoveToTarget(self: AggressiveAI)
	local targetPos, _ = self:getPositioning()
	self.human:MoveTo(targetPos)
end

function AggressiveAI.ChaseLoop(self: AggressiveAI)
	self:checkForTarget()

	if not self.target then
		return
	end

	local function newPath()
		local targetPos, entityPos = self:getPositioning()

		self.human:MoveTo(self.entity:GetPivot().Position)
		self.pathData = AIPathService:CreatePath(entityPos, targetPos)
	end

	local function followPath()
		for _, point: PathWaypoint in pairs(self.pathData.Waypoints) do
			local canSeeTarget = self:PeepTarget()
			if canSeeTarget then
				self.targetVisible = true
				break
			end
			self.human:MoveTo(point.Position)
			self.human.MoveToFinished:Wait()
		end
		self.pathData.Completed = true
	end

	if self.chaseLoopConnection then
		self:CancelLoop()
	end

	self.chaseLoopConnection = task.spawn(function()
		while true do
			if self:PeepTarget() and self:checkForTarget() then
				self:MoveToTarget()
				task.wait()
				continue
			end
			self.targetVisible = false
			newPath()
			followPath()
		end
	end)
end

function AggressiveAI.CancelLoop(self: AggressiveAI)
	if self.chaseLoopConnection then
		task.cancel(self.chaseLoopConnection)
		self.chaseLoopConnection = nil
	end
end

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {
	NamingConvention = {
		Init = "init",
	},
})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
