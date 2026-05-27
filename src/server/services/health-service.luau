--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SignalRegistry = require(ServerScriptService["signal-registry"])
local Viewer = require(ReplicatedStorage.packages.viewer)

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

	-- memory leak! dont care!
	entityModel:GetAttributeChangedSignal("Health"):Connect(function()
		if self:getHealth(entityModel) <= 0 then
			self:killEntity(entityModel)
		end
	end)
end

function HealthService.setHealth(_: HealthService, entityModel: Model, health: number)
	entityModel:SetAttribute("Health", health)
end

function HealthService.setMaxHealth(_: HealthService, entityModel: Model, maxHealth: number)
	entityModel:SetAttribute("MaxHealth", maxHealth)
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

	SignalRegistry.hitEntity:Connect(function(entityModel: Model, attackName: string)
		self:killEntity(entityModel)
		if entityModel:GetAttribute("State") == "Burning" then
			entityModel:SetAttribute("Burned", true)
		end
	end)
end

return HealthService
