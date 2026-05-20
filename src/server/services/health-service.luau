--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Ragdoller = require(ReplicatedStorage.packages.ragdoller)
local SignalRegistry = require(ServerScriptService["signal-registry"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local HealthService = {}

export type HealthService = typeof(HealthService)

function HealthService.killEntity(_: HealthService, entityModel: Model)
	entityModel:RemoveTag("PassiveAI")
	entityModel:RemoveTag("WanderingAI")
	entityModel:RemoveTag("AggressiveAI")
	entityModel:AddTag("Death")

	Debris:AddItem(entityModel, 3)
end

function HealthService.jaegarInit(self: HealthService)
	Viewer.WatchTag("Death", false, function(instance: Instance)
		Ragdoller:activateRagdoll(instance :: Model)
	end)

	SignalRegistry.mutationFinished:Connect(function(mutation: string, entityModel: Model)
		if mutation == "Terminal" then
			self:killEntity(entityModel)
		end
	end)
end

return HealthService
