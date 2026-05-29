--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local SignalRegistry = require(ServerScriptService["signal-registry"])

local MutationService = {}

export type MutationService = typeof(MutationService)

function MutationService.initializeEntityMutation(_: MutationService, mutationName: string, entityModel: Model)
	entityModel:SetAttribute(`{mutationName}MutationDone`, false)
end

function MutationService.mutateEntity(self: MutationService, mutationName: string, entityModel: Model)
	if entityModel:HasTag("HealedInfection") then
		return
	end

	entityModel:SetAttribute(`{mutationName}MutationDone`, true)

	if mutationName == "Aggressive" then
		if entityModel:GetAttribute("InitialTransitionState") then
			return
		end

		self:swapFromWanderingToAggressive(entityModel)
	end

	SignalRegistry.mutationFinished:Fire(mutationName, entityModel)
end

function MutationService.swapFromWanderingToAggressive(_: MutationService, entityModel: Model)
	if entityModel:GetAttribute("InitialTransitionState") then
		return
	end

	entityModel:RemoveTag("PassiveAI")
	entityModel:RemoveTag("WanderingAI")
	entityModel:RemoveTag("AggressiveMutation")
	entityModel:AddTag("AggressiveAI")
	entityModel:AddTag("Transitioned")
end

function MutationService.jaegarInit(self: MutationService)
	SignalRegistry.hitPassive:Connect(function(passiveEntity: Model)
		self:swapFromWanderingToAggressive(passiveEntity)
		passiveEntity:SetAttribute("InitialTransitionState", "Stunned")
	end)
end

return MutationService
