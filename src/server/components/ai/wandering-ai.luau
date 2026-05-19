--!nocheck
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)

local AIPathService = require(ServerScriptService.services["ai-path-service"])
local Raydar = require(ReplicatedStorage.shared.utils.raydar)

local AIConfig = require(ReplicatedStorage.shared.configs["aggressive-ai-config"])

local WanderingAI = {}
WanderingAI.__index = WanderingAI

export type WanderingAI = typeof(setmetatable(
	{} :: {
		entity: Model,
		human: Humanoid,
		janitor: Classy.Janitor,
		target: Model?,

		staminaRecoveryConnection: RBXScriptConnection,

		targetVisible: boolean,
		lastSeenPos: Vector3?,

		internalState: string,

		chaseLoopConnection: thread?,

		pathData: { Path: Path, Waypoints: { PathWaypoint }, Completed: boolean }?,
	},
	WanderingAI
))

function WanderingAI.new(character: Instance, janitor: Classy.Janitor): WanderingAI
	return setmetatable({
		entity = character :: Model,

		targetVisible = false,
		internalState = "None",

		stamina = math.random(0, AIConfig.Movement.MaxStamina),
		staminaRecoveryTick = os.clock(),
		staminaDrainTick = os.clock(),

		human = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid,
		janitor = janitor,
	}, WanderingAI)
end

function WanderingAI.init(self: WanderingAI)
	self:ChaseLoop()
end

function WanderingAI.checkForTarget(self: WanderingAI)
	local desiredTarget = CollectionService:GetTagged("AIAttractor")[1]
	if not desiredTarget then
		error("NoPlr")
	end

	-- self.target = Players:GetPlayers()[1]
	self.target = desiredTarget
	return true
end

function WanderingAI.getPositioning(self: WanderingAI): (Vector3, Vector3)
	return self.target:GetPivot().Position, self.entity:GetPivot().Position
end

function WanderingAI.PeepTarget(self: WanderingAI)
	local targetPos, entityPos = self:getPositioning()

	local directionToTarget = (targetPos - entityPos).Unit
	local maxDistance = AIConfig.Pathfinding.SightDistance

	local result = Raydar:Fire(entityPos, directionToTarget, maxDistance, Raydar.RayTypes.HitWalls)
	if result and result.Instance and result.Instance == self.target then
		self.lastSeenPos = self.target:GetPivot().Position
	end
	return result
end

function WanderingAI.MoveToTarget(self: WanderingAI)
	local targetPos, _ = self:getPositioning()
	self.human:MoveTo(targetPos)
end

function WanderingAI.MoveToLastSeenPos(self: WanderingAI)
	local lastSeenPos = self.lastSeenPos
	local entityPos = self.entity:GetPivot().Position
	local mag = (entityPos - lastSeenPos).Magnitude
	if mag < 1 then
		self.lastSeenPos = nil
		return
	end
	self.human:MoveTo(self.lastSeenPos)
end

function WanderingAI.SetState(self: WanderingAI, state: string)
	self.entity:SetAttribute("State", state)
end

function WanderingAI.SetSpeed(self: WanderingAI, number: number)
	self.human.WalkSpeed = number
end

function WanderingAI.CancelLoop(self: WanderingAI)
	if self.chaseLoopConnection then
		task.cancel(self.chaseLoopConnection)
		self.chaseLoopConnection = nil
	end
end

WanderingAI.classy = Classy.create("WanderingAI", WanderingAI, {
	NamingConvention = {
		Init = "init",
	},
})

Classy.registerGlobal("WanderingAI", WanderingAI.classy)

return WanderingAI
