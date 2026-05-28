--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SignalRegistry = require(ServerScriptService["signal-registry"])

local MutationService = {}

export type MutationService = typeof(MutationService)

function MutationService.initializeEntityMutation(_: MutationService, mutationName: string, entityModel: Model)
	entityModel:SetAttribute(`{mutationName}MutationDone`, false)
end

function MutationService.mutateEntity(_: MutationService, mutationName: string, entityModel: Model)
	entityModel:SetAttribute(`{mutationName}MutationDone`, true)

	if mutationName == "Aggressive" then
		if entityModel:GetAttribute("InitialTransitionState") then
			return
		end

		entityModel:RemoveTag("PassiveAI")
		entityModel:RemoveTag("WanderingAI")
		entityModel:AddTag("AggressiveAI")

		-- can add something for terminal here if need be, like a skin change
		-- elseif mutationName == "Terminal" then
		-- 	print()
	end

	SignalRegistry.mutationFinished:Fire(mutationName, entityModel)
end

function MutationService.jaegarInit(_: MutationService)
	SignalRegistry.hitPassive:Connect(function(passiveEntity: Model)
		passiveEntity:RemoveTag("AggressiveMutation")
		passiveEntity:SetAttribute("InitialTransitionState", nil)

		passiveEntity:RemoveTag("PassiveAI")
		passiveEntity:RemoveTag("WanderingAI")

		passiveEntity:SetAttribute("InitialTransitionState", "Stunned")
		passiveEntity:AddTag("AggressiveAI")
	end)
end

return MutationService
