--!strict
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
		entityModel:RemoveTag("Passive")
		entityModel:RemoveTag("Wandering")
		entityModel:AddTag("Aggressive")

		-- can add something for terminal here if need be, like a skin change
		-- elseif mutationName == "Terminal" then
		-- 	print()
	end

	SignalRegistry.mutationFinished:Fire(mutationName, entityModel)
end

return MutationService
