--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BackpackComponent = require(ReplicatedStorage.shared.components["backpack-component"])
local SignalRegistry = require(ServerScriptService["signal-registry"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local healthChangedConnections = {} :: {
	[Model]: RBXScriptConnection,
}

local destroyConnections = {} :: {
	[Model]: RBXScriptConnection,
}

local HealthService = {}

export type HealthService = typeof(HealthService)

function HealthService.isAlive(_: HealthService, entityModel: Model)
	return not entityModel:HasTag("Dead")
end

function HealthService.isDead(self: HealthService, entityModel: Model)
	return not self:isAlive(entityModel)
end

function HealthService.initEntity(self: HealthService, entityModel: Model, health: number)
	entityModel:AddTag("Health")

	self:setMaxHealth(entityModel, health)
	self:setHealth(entityModel, health)

	local healthConnection: RBXScriptConnection
	local destroyConnection: RBXScriptConnection

	healthConnection = entityModel:GetAttributeChangedSignal("Health"):Connect(function()
		if not entityModel.Parent then
			return
		end

		if self:isDead(entityModel) then
			return
		end

		if self:getHealth(entityModel) <= 0 then
			self:killEntity(entityModel)
		end
	end)

	destroyConnection = entityModel.Destroying:Connect(function()
		healthConnection:Disconnect()
		destroyConnection:Disconnect()

		healthChangedConnections[entityModel] = nil
		destroyConnections[entityModel] = nil
	end)

	healthChangedConnections[entityModel] = healthConnection
	destroyConnections[entityModel] = destroyConnection
end

function HealthService.setHealth(self: HealthService, entityModel: Model, health: number)
	local maxHealth = self:getMaxHealth(entityModel) or health
	entityModel:SetAttribute("Health", math.min(maxHealth, health))
end

function HealthService.setMaxHealth(self: HealthService, entityModel: Model, maxHealth: number)
	entityModel:SetAttribute("MaxHealth", maxHealth)

	if (self:getHealth(entityModel) or -100) > maxHealth then
		self:setHealth(entityModel, maxHealth)
	end
end

function HealthService.addHealthTo(self: HealthService, entityModel: Model, amount: number)
	if self:isDead(entityModel) then
		return
	end

	local newAmount = math.min(self:getMaxHealth(entityModel), self:getHealth(entityModel) + amount)
	self:setHealth(entityModel, newAmount)
end

function HealthService.removeHealthFrom(self: HealthService, entityModel: Model, amount: number)
	if self:isDead(entityModel) then
		return
	end

	local newAmount = math.max(0, self:getHealth(entityModel) - amount)
	self:setHealth(entityModel, newAmount)
end

function HealthService.getHealth(_: HealthService, entityModel: Model): number
	if not entityModel:HasTag("Health") then
		error(`[{script.Name}] Entity does not have health: {entityModel:GetFullName()}`)
	end

	return entityModel:GetAttribute("Health") :: number
end

function HealthService.getMaxHealth(_: HealthService, entityModel: Model): number
	if not entityModel:HasTag("Health") then
		error(`[{script.Name}] Entity does not have health: {entityModel:GetFullName()}`)
	end

	return entityModel:GetAttribute("MaxHealth") :: number
end

function HealthService.killEntity(self: HealthService, entityModel: Model)
	if self:isDead(entityModel) then
		return
	end

	self:setHealth(entityModel, 0)
	entityModel:AddTag("Dead")
end

function HealthService.jaegarInit(self: HealthService)
	Viewer.WatchTag("Dead", false, function(instance: Instance)
		instance:RemoveTag("PassiveAI")
		instance:RemoveTag("WanderingAI")
		instance:RemoveTag("AggressiveAI")
		instance:RemoveTag("AggressiveMutation")
		instance:RemoveTag("TerminalMutation")

		if instance:IsA("Model") and instance.PrimaryPart and not instance:HasTag("Character") then
			instance.PrimaryPart.CanCollide = false
			instance.PrimaryPart.CanQuery = false
			instance.PrimaryPart.CanTouch = false
		end
	end)

	SignalRegistry.mutationFinished:Connect(function(mutation: string, entityModel: Model)
		if mutation == "Terminal" then
			self:killEntity(entityModel)
		end
	end)

	SignalRegistry.hitEntity:Connect(function(entityModel: Model, damage: number)
		local wasDead = self:isDead(entityModel)

		self:removeHealthFrom(entityModel, damage)

		if not wasDead and self:isDead(entityModel) then
			local player = Players:GetPlayers()[1]
			if not player then
				return
			end

			if entityModel:GetAttribute("OriginalEntityType") == "Aggressive" then
				local data = BackpackComponent.classy:GetApplied(player)
				if not data then
					return
				end

				print("+1")
				data:GetData():addResource("fireCharges", 5)
			end
		end

		if entityModel:GetAttribute("State") == "Burning" then
			entityModel:SetAttribute("Burned", true)
		end
	end)
end

return HealthService
