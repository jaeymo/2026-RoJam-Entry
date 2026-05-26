--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)
local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local Network = Jaegar:GetNetwork()

local AIPathService = require(ServerScriptService.services["ai-path-service"])
local Raydar = require(ReplicatedStorage.shared.utils.raydar)

local Configs = ReplicatedStorage.shared.configs
local AIConfig = require(Configs["aggressive-ai-config"])
local InfectedConfig = require(Configs["infected-config"])
local JobConfig = require(Configs["job-config"])

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI

export type AggressiveAI = typeof(setmetatable(
	{} :: {
		entity: Model,
		human: Humanoid,
		janitor: Classy.Janitor,
		target: Model?,

		destroyed: boolean,

		staminaDrainTick: number?,
		staminaRecoveryTick: number?,
		searchStartTick: number?,

		maxStamina: number,
		maxHealth: number,
		staminaRecoveryRate: number,
		staminaRecoveryTime: number,

		exhaustedSpeed: number,
		defaultWalkSpeed: number,
		chasingSpeed: number,

		staminaRecoveryConnection: RBXScriptConnection,

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

		stamina = AIConfig.Movement.MaxStamina,
		staminaRecoveryTick = os.clock(),
		staminaDrainTick = os.clock(),

		human = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid,
		janitor = janitor,
		destroyed = false,
	}, AggressiveAI)
end

function AggressiveAI.cleanEntityModel(self: AggressiveAI, entityModel: Model)
	entityModel.PrimaryPart = entityModel.HumanoidRootPart
	entityModel.PrimaryPart.Anchored = true

	self.human.HipHeight = 2

	entityModel.HumanoidRootPart.Transparency = 1

	local collisionBall = Instance.new("Part")
	collisionBall.Transparency = 0.8
	collisionBall.Shape = Enum.PartType.Ball
	collisionBall.Size = Vector3.one * 4
	collisionBall.Position = entityModel.PrimaryPart.Position
	collisionBall.CollisionGroup = "CollisionHitbox"

	local w = Instance.new("WeldConstraint")
	w.Part0 = entityModel.HumanoidRootPart
	w.Part1 = collisionBall
	w.Parent = collisionBall

	collisionBall.Parent = entityModel

	if entityModel:FindFirstChild("Client") then
		entityModel:FindFirstChild("Client"):Destroy()
	end

	entityModel.PrimaryPart.Anchored = false
end

function AggressiveAI.Init(self: AggressiveAI)
	self:cleanEntityModel(self.entity)
	self.entity.PrimaryPart:SetNetworkOwner(nil)
	self.entity.PrimaryPart.CollisionGroup = "Entity"

	self.currentJob = self.entity:GetAttribute("JobName")
	self.currentWeapon = self.entity:GetAttribute("JobWeapon")

	self:applyJobConfig()
	self:applyInfectedConfig()

	task.defer(function()
		if self.destroyed then
			return
		end
		self:ChaseLoop()
	end)

	self:SetState("Hunting")
end

function AggressiveAI.applyJobConfig(self: AggressiveAI)
	local jobName = self.currentJob
	local jobMod = JobConfig[jobName]

	if not jobMod then
		warn(jobName)
		return
	end

	self.maxStamina = math.ceil(AIConfig.Movement.MaxStamina * jobMod.Movement.StaminaMultiplier)
	self.stamina = math.random(0, self.maxStamina)

	self.maxHealth = math.ceil(AIConfig.Vitals.MaxHealth * jobMod.Vitals.HealthMultiplier)
	self.staminaRecoveryRate = AIConfig.Movement.StaminaRecoveryRate * jobMod.Movement.StaminaRecoveryRateMultiplier
	self.staminaRecoveryTime = AIConfig.Movement.StaminaRecoveryTime * jobMod.Movement.StaminaRecoveryTimeMultiplier

	self.exhaustedSpeed = AIConfig.Movement.ExhaustedSpeed * jobMod.Movement.SpeedMultiplier
	self.defaultWalkSpeed = AIConfig.Movement.DefaultWalkSpeed * jobMod.Movement.SpeedMultiplier
	self.chasingSpeed = AIConfig.Movement.ChasingSpeed * jobMod.Movement.SpeedMultiplier
end

function AggressiveAI.applyInfectedConfig(self: AggressiveAI)
	local level = self.entity:GetAttribute("InfectedLevel")
	local levelConfig = InfectedConfig[level]

	if not levelConfig then
		warn(level)
		return
	end

	self.maxStamina = math.ceil(AIConfig.Movement.MaxStamina * levelConfig.StaminaMultiplier)
	self.stamina = math.random(0, self.maxStamina)

	self.staminaRecoveryRate = AIConfig.Movement.StaminaRecoveryRate * levelConfig.StaminaMultiplier
	self.staminaRecoveryTime = AIConfig.Movement.StaminaRecoveryTime * levelConfig.StaminaMultiplier

	self.exhaustedSpeed = AIConfig.Movement.ExhaustedSpeed * levelConfig.SpeedMultiplier
	self.defaultWalkSpeed = AIConfig.Movement.DefaultWalkSpeed * levelConfig.SpeedMultiplier
	self.chasingSpeed = AIConfig.Movement.ChasingSpeed * levelConfig.SpeedMultiplier
end

function AggressiveAI.checkForTarget(self: AggressiveAI)
	-- local desiredTarget = CollectionService:GetTagged("AIAttractor")[1]
	local plr = Players:GetPlayers()[1]
	if not plr then
		return
	end

	local char = plr.Character or plr.CharacterAdded:Wait()
	local desiredTarget = char
	if not desiredTarget then
		warn("NoPlr")
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

	local result = Raydar:Fire(entityPos, directionToTarget, maxDistance, Raydar.RayTypes.AimForPlayers, self.entity)
	-- if result then
	-- print(result.Instance, result.Instance.Parent)
	-- end
	if result and result.Instance and result.Instance == self.target then
		self.lastSeenPos = self.target:GetPivot().Position
	end
	return result
end

function AggressiveAI.GetPushedDistance(self: AggressiveAI)
	local minDistance = AIConfig.Pathfinding.StopDistance
	local targetPos, entityPos = self:getPositioning()
	local mag = (targetPos - entityPos).Magnitude

	if mag > minDistance then
		self.internalState = "followTarget"
		return targetPos
	end

	self:Attack()
	self.internalState = "closeChase"

	return entityPos
end

function AggressiveAI.MoveToTarget(self: AggressiveAI)
	self.human:MoveTo(self:GetPushedDistance())
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
	self.entity:SetAttribute("State", state)
end

function AggressiveAI.SetSpeed(self: AggressiveAI, number: number)
	self.human.WalkSpeed = number
end

function AggressiveAI.DecreaseStamina(self: AggressiveAI)
	local elapsedTick = os.clock() - self.staminaDrainTick

	local staminaDrain = AIConfig.Movement.StaminaDrain
	local maxStamina = self.maxStamina

	if elapsedTick >= 0.5 then
		self.stamina = math.clamp(self.stamina - staminaDrain, 0, maxStamina)
		self.staminaDrainTick = os.clock()
	end
end

function AggressiveAI.IncreaseStamina(self: AggressiveAI)
	local staminaRecoveryRate = self.staminaRecoveryRate
	local staminaHeal = AIConfig.Movement.StaminaHeal
	local maxStamina = self.maxStamina

	local elapsedTick = os.clock() - self.staminaRecoveryTick

	if elapsedTick >= staminaRecoveryRate then
		self.stamina = math.clamp(self.stamina + staminaHeal, 0, maxStamina)
		self.staminaDrainTick = os.clock()
	end
end

function AggressiveAI.RecoverStamina(self: AggressiveAI)
	if self.staminaRecoveryConnection then
		return
	end

	self:SetState("ExhaustedWalk")
	self.entity:SetAttribute("Recovering", true)
	self:SetSpeed(self.exhaustedSpeed)

	local staminaRecoveryTime = self.staminaRecoveryTime
	local staminaRecoveryRate = self.staminaRecoveryRate
	local maxStamina = self.maxStamina

	local recoveryTick = os.clock()
	local healTick = os.clock()

	self.staminaRecoveryConnection = RunService.Heartbeat:Connect(function()
		local elapsedRecoveryTick = os.clock() - recoveryTick
		local recover_t = elapsedRecoveryTick / staminaRecoveryTime

		local elapsedHealTick = os.clock() - healTick
		local heal_t = elapsedHealTick / staminaRecoveryTime

		if heal_t >= staminaRecoveryRate then
			self.stamina = math.clamp(recover_t * maxStamina, 0, maxStamina)
			healTick = os.clock()
		end

		if recover_t >= 1 or self.stamina >= maxStamina then
			self.staminaRecoveryConnection:Disconnect()
			self.staminaRecoveryConnection = nil

			self.entity:SetAttribute("Recovering", false)

			if
				self.internalState == "followTarget"
				or self.internalState == "searchTarget"
				or self.internalState == "closeChase"
			then
				self:SetState("Chasing")
			else
				self:SetState("Hunting")
			end

			self.attackTick = os.clock()

			return
		end
	end)
end

function AggressiveAI.Attack(self: AggressiveAI)
	local cooldown = AIConfig.Attacks.MainAttackCooldown
	if not self.attackTick then
		self.attackTick = os.clock() - cooldown
	end

	local elapsedTick = os.clock() - self.attackTick

	if elapsedTick <= cooldown or self.entity:GetAttribute("Recovering") then
		return false
	end

	local maxStam = self.maxStamina
	local attackCost = AIConfig.Attacks.MainAttackStaminaCost

	self:SetState("Attack")
	self.internalState = "attacking"
	self.attackTick = os.clock()
	self.stamina = math.clamp(self.stamina - attackCost, 0, maxStam)

	local pivot = self.entity.PrimaryPart.CFrame
	local forward = pivot.LookVector * 5

	Network:Broadcast("spawnEnemyHitbox", pivot + forward, Vector3.new(6, 5, 8))

	self:SetSpeed(self.defaultWalkSpeed * AIConfig.Attacks.AttackMovementSpeedMultiplier)
	task.wait(1)
	if self.entity:GetAttribute("Recovering") then
		self:SetSpeed(self.exhaustedSpeed)
	else
		self:SetSpeed(self.defaultWalkSpeed)
	end
	self.internalState = "None"
	return true
end

function AggressiveAI.ChaseLoop(self: AggressiveAI)
	self:checkForTarget()

	if not self.target then
		repeat
			task.wait()
		until self.destroyed or self:checkForTarget()
	end

	if self.destroyed then
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
			local foundTarget = peepTarget and peepTarget.Instance:IsDescendantOf(self.target)

			if foundTarget then
				self.targetVisible = true
				break
			end
			if self.stamina < self.maxStamina and self.entity:GetAttribute("State") == "ExhaustedWalk" then
				self:RecoverStamina()
			else
				self:IncreaseStamina()
				self:SetState("Hunting")
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
			if self.internalState == "attacking" then
				task.wait()
				continue
			end
			local peepTarget = self:PeepTarget()
			local foundTarget = peepTarget and peepTarget.Instance:IsDescendantOf(self.target)

			if foundTarget then
				if self.stamina == 0 or self.entity:GetAttribute("State") == "ExhaustedWalk" then
					if self.internalState == "attacking" then
						continue
					end

					if self.internalState == "closeChase" then
						if not self:Attack() then
							self:SetState("Idle")
						end
					else
						self.internalState = "followTarget"
					end

					self:RecoverStamina()
				else
					if self.entity:GetAttribute("Recovering") then
						self:SetSpeed(self.exhaustedSpeed)
					else
						self:SetSpeed(self.chasingSpeed)
					end
					if self.internalState == "closeChase" then
						if not self:Attack() then
							self:SetState("Idle")
						end
					else
						self:SetState("Chasing")
						self.internalState = "followTarget"
						self:DecreaseStamina()
					end
				end

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

						self:SetState("Chasing")
						continue
					end
				end

				if self.stamina == 0 or self.entity:GetAttribute("State") == "ExhaustedWalk" then
					self:RecoverStamina()
				else
					self:SetSpeed(self.chasingSpeed)
					self:SetState("Chasing")
					self:DecreaseStamina()
				end

				self:MoveToLastSeenPos()
				task.wait()
				continue
			end

			self.targetVisible = false
			newPath()

			self.internalState = "followPath"
			if not self.staminaRecoveryConnection and self.entity:GetAttribute("State") == "ExhaustedWalk" then
				self:RecoverStamina()
			else
				self:SetSpeed(self.defaultWalkSpeed)
				self:SetState("Hunting")
			end

			followPath()
		end
	end)
end

function AggressiveAI.CancelLoop(self: AggressiveAI)
	self.human:MoveTo(self.entity:GetPivot().Position)
	if self.chaseLoopConnection then
		task.cancel(self.chaseLoopConnection)
		self.chaseLoopConnection = nil
	end
end

function AggressiveAI.Destroy(self: AggressiveAI)
	self:CancelLoop()
	self.destroyed = true
end

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {
	Nuke = false,
})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
