--!nocheck
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

		searchStartTick: number?,

		targetVisible: boolean,
		lastSeenPos: Vector3?,

		internalState: string,

		chaseLoopConnection: thread?,

		pathData: { Path: Path, Waypoints: { PathWaypoint }, Completed: boolean }?,
	},
	AggressiveAI
))

function AggressiveAI.new(character: Instance, janitor: Classy.Janitor): AggressiveAI
	return setmetatable({
		entity = character :: Model,
		targetVisible = false,
		internalState = "None",
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
	return true
end

function AggressiveAI.getPositioning(self: AggressiveAI): (Vector3, Vector3)
	return self.target:GetPivot().Position, self.entity:GetPivot().Position
end

function AggressiveAI.PeepTarget(self: AggressiveAI)
	local targetPos, entityPos = self:getPositioning()

	local directionToTarget = (targetPos - entityPos).Unit
	local maxDistance = AIConfig.Pathfinding.SightDistance

	local result = Raydar:Fire(entityPos, directionToTarget, maxDistance, Raydar.RayTypes.HitWalls)
	if result and result.Instance and result.Instance == self.target then
		self.lastSeenPos = self.target:GetPivot().Position
	end
	return result
end

function AggressiveAI.MoveToTarget(self: AggressiveAI)
	local targetPos, _ = self:getPositioning()
	self.human:MoveTo(targetPos)
end

function AggressiveAI.MoveToLastSeenPos(self: AggressiveAI)
	local lastSeenPos = self.lastSeenPos
	local entityPos = self.entity:GetPivot().Position
	local mag = (entityPos - lastSeenPos).Magnitude
	if mag < 1 then
		self.lastSeenPos = nil
		return
	end
	self.human:MoveTo(self.lastSeenPos)
end

function AggressiveAI.SetState(self: AggressiveAI, state: string)
	self.entity:SetAttribute(state)
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
			local peepTarget = self:PeepTarget()
			local canSeeTarget = peepTarget and peepTarget.Instance == self.target
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
			local peepTarget = self:PeepTarget()
			if peepTarget and peepTarget == self.target then
				print("move")
				self.internalState = "followTarget"
				self:MoveToTarget()
				task.wait()
				continue
			elseif self.lastSeenPos then
				if self.internalState ~= "searchTarget" then
					self.internalState = "searchTarget"
					self.searchStartTick = os.clock()
				else
					local elapsedSearchTime = os.clock() - self.searchStartTick
					if elapsedSearchTime >= AIConfig.Pathfinding.SearchTimeout then
						self.lastSeenPos = nil
						self.internalState = "followPath"
						continue
					end
				end

				print("search")

				self:MoveToLastSeenPos()
				task.wait()
				continue
			end

			self.targetVisible = false
			newPath()
			self.internalState = "followPath"
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
