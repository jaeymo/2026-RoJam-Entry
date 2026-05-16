--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local entityAssets = ReplicatedStorage.assets.entities

local EntityFactory = {}

export type EntityFactory = typeof(EntityFactory)

function EntityFactory.getNewEntityModel(_: EntityFactory, name: string): Model?
	local entity = entityAssets:FindFirstChild(name)
	if not entity then
		warn(`[{script.Name}] Failed to find entity by the name of: {name}`)
		return nil
	end

	if not entity:IsA("Model") then
		warn(`[{script.Name}] Entity is not a model: {entity}`)
		return nil
	end

	return entity:Clone()
end

return EntityFactory
