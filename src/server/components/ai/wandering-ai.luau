--!nocheck
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)

local AIPathService = require(ServerScriptService.services["ai-path-service"])
local Raydar = require(ReplicatedStorage.shared.utils.raydar)

local AIConfig = require(ReplicatedStorage.shared.configs["wandering-ai-config"])

local WanderingAI = {}
WanderingAI.__index = WanderingAI

export type WanderingAI = typeof(setmetatable(
	{} :: {
		entity: Model,
		human: Humanoid,
		janitor: Classy.Janitor,

		pathNodes: { BasePart },
		targetMemory: { BasePart },
		target: Model?,

		staminaRecoveryConnection: RBXScriptConnection,

		targetVisible: boolean,

		internalState: string,

		wanderLoopConnection: thread?,

		pathData: { Path: Path, Waypoints: { PathWaypoint }, Completed: boolean }?,
	},
	WanderingAI
))

function WanderingAI.new(character: Instance, janitor: Classy.Janitor): WanderingAI
	return setmetatable({
		entity = character :: Model,

		targetVisible = false,
		internalState = "None",

		pathNodes = {},
		targetMemory = {},

		stamina = math.random(0, AIConfig.Movement.MaxStamina),
		staminaRecoveryTick = os.clock(),
		staminaDrainTick = os.clock(),

		human = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid,
		janitor = janitor,
	}, WanderingAI)
end

function WanderingAI.cleanEntityModel(self: WanderingAI, entityModel: Model)
	entityModel.PrimaryPart = entityModel.HumanoidRootPart
	entityModel.PrimaryPart.Anchored = true
	entityModel.PrimaryPart.Transparency = 0.5

	entityModel.PrimaryPart.CollisionGroup = "PassiveEntity"
	self.human.HipHeight = 2
	entityModel.Client:Destroy()
	-- for _, child in pairs(entityModel:GetChildren()) do
	-- 	if child.Name == "HumanoidRootPart" then
	-- 		child.Transparency = 0.5
	-- 		continue
	-- 	elseif not child:IsA("Accessory") and not child:IsA("BasePart") then
	-- 		continue
	-- 	end

	-- 	child:Destroy()
	-- end
	entityModel.PrimaryPart.Anchored = false
end

function WanderingAI.init(self: WanderingAI)
	self:cleanEntityModel(self.entity)
	self.entity.PrimaryPart:SetNetworkOwner(nil)

	self.human.Health = AIConfig.Vitals.MaxHealth
	self.human.WalkSpeed = AIConfig.Movement.DefaultWalkSpeed
	self:WanderLoop()
end

function WanderingAI.changeTarget(self: WanderingAI)
	local validTarget = false
	local nodes = table.clone(self.pathNodes)

	local newPath

	repeat
		local randomNum = math.random(1, #nodes)
		newPath = nodes[randomNum]

		if table.find(self.targetMemory, newPath) then
			table.remove(nodes, randomNum)
		else
			validTarget = true
		end

	until validTarget or #nodes <= 0

	if not newPath then
		return
	end

	if #self.targetMemory >= AIConfig.Pathfinding.TargetMemoryLength then
		table.remove(self.targetMemory, 1)
	end

	self.targetMemory[#self.targetMemory + 1] = newPath

	self.target = newPath
end

function WanderingAI.checkForTargetNodes(self: WanderingAI)
	local desiredTarget = CollectionService:GetTagged("PathNodes")
	if not desiredTarget then
		error("NoTarg")
	end

	-- self.target = Players:GetPlayers()[1]
	table.clear(self.pathNodes)
	for _, v in pairs(desiredTarget) do
		if not v:IsDescendantOf(workspace) then
			continue
		end
		self.pathNodes[#self.pathNodes + 1] = v
	end
	return true
end

function WanderingAI.getPositioning(self: WanderingAI): (Vector3, Vector3)
	return self.target:GetPivot().Position, self.entity:GetPivot().Position
end

function WanderingAI.GetPushedDistance(self: WanderingAI)
	local targetPos, entityPos = self:getPositioning()
	local mag = (targetPos - entityPos).Magnitude

	if mag > 1 then
		self.internalState = "followTarget"
		return targetPos
	end

	self:changeTarget()

	return entityPos
end

function WanderingAI.PeepTarget(self: WanderingAI)
	local targetPos, entityPos = self:getPositioning()

	local directionToTarget = (targetPos - entityPos).Unit
	local maxDistance = AIConfig.Pathfinding.SightDistance

	local result = Raydar:Fire(entityPos, directionToTarget, maxDistance, Raydar.RayTypes.AimforPathNodes)

	return result
end

function WanderingAI.MoveToTarget(self: WanderingAI)
	self.human:MoveTo(self:GetPushedDistance())
end

function WanderingAI.SetState(self: WanderingAI, state: string)
	self.entity:SetAttribute("State", state)
end

function WanderingAI.SetSpeed(self: WanderingAI, number: number)
	self.human.WalkSpeed = number
end

function WanderingAI.TakeBreak(self: WanderingAI)
	if self.internalState == "takingBreak" then
		return
	end
	self.internalState = "takingBreak"

	self.human:MoveTo(self.entity:GetPivot().Position)
	self:SetState("Resting")

	local breakTime = math.random(AIConfig.Movement.BreakTime.Min, AIConfig.Movement.BreakTime.Max)
		/ AIConfig.Movement.BreakTime.Weight

	task.wait(breakTime)
	self.internalState = "followPath"
	self:SetState("Wandering")
	self:ResetStamina()
	self:changeTarget()
end

function WanderingAI.DecreaseStamina(self: WanderingAI)
	local elapsedTick = os.clock() - self.staminaDrainTick

	local staminaDrain = AIConfig.Movement.StaminaDrain
	local maxStamina = AIConfig.Movement.MaxStamina

	if elapsedTick >= 0.5 then
		self.stamina = math.clamp(self.stamina - staminaDrain, 0, maxStamina)
		self.staminaDrainTick = os.clock()
	end
end

function WanderingAI.ResetStamina(self: WanderingAI)
	self.stamina = AIConfig.Movement.MaxStamina
end

function WanderingAI.isTargetFound(self: WanderingAI)
	local peepTarget = self:PeepTarget()
	local hit = peepTarget
	local foundTarget
	if not hit then
		foundTarget = false
	else
		foundTarget = peepTarget.Instance:IsDescendantOf(self.target) or peepTarget.Instance == self.target
	end
	return foundTarget
end

function WanderingAI.WanderLoop(self: WanderingAI)
	self:checkForTargetNodes()

	if not self.target then
		repeat
			self:changeTarget()
			task.wait()
		until self:checkForTargetNodes()
	end

	local function newPath()
		local targetPos, entityPos = self:getPositioning()

		self.human:MoveTo(self.entity:GetPivot().Position)
		self.pathData = AIPathService:CreatePath(entityPos, targetPos)
	end

	local function followPath()
		for _, point: PathWaypoint in pairs(self.pathData.Waypoints) do
			if self:isTargetFound() then
				self.targetVisible = true
				return
			end
			if self.stamina < AIConfig.Movement.MaxStamina and self.entity:GetAttribute("State") == "Resting" then
				self:TakeBreak()
			else
				self:SetState("Wandering")
				self:DecreaseStamina()
			end

			self.human:MoveTo(point.Position)
			self.human.MoveToFinished:Wait()
		end

		self.pathData.Completed = true
		self:changeTarget()
	end

	if self.wanderLoopConnection then
		self:CancelLoop()
	end

	self.wanderLoopConnection = task.spawn(function()
		while true do
			if self:isTargetFound() then
				if self.stamina == 0 or self.entity:GetAttribute("State") == "Resting" then
					self:TakeBreak()
				else
					if self.entity:GetAttribute("Recovering") then
						self:TakeBreak()
					end

					self.internalState = "followTarget"
					self:SetState("Wandering")
					self:DecreaseStamina()
				end

				self:MoveToTarget()
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

function WanderingAI.CancelLoop(self: WanderingAI)
	if self.wanderLoopConnection then
		task.cancel(self.wanderLoopConnection)
		self.wanderLoopConnection = nil
	end
end

WanderingAI.classy = Classy.create("WanderingAI", WanderingAI, {
	Nuke = false,
	NamingConvention = {
		Init = "init",
	},
})

Classy.registerGlobal("WanderingAI", WanderingAI.classy)

return WanderingAI
