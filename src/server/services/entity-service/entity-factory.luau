--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local entityAssets = ReplicatedStorage.assets.entities

local EntityFactory = {}

export type EntityFactory = typeof(EntityFactory)

function EntityFactory.getNewEntityModel(_: EntityFactory, _: string): Model?
	local testCharacters = ReplicatedStorage.assets.entities:FindFirstChild("test") :: Folder
	return (testCharacters:GetChildren()[math.random(1, #testCharacters:GetChildren())]:Clone()) :: Model

	-- local entity = entityAssets:FindFirstChild(name)
	-- if not entity then
	-- 	warn(`[{script.Name}] Failed to find entity by the name of: {name}`)
	-- 	return nil
	-- end

	-- if not entity:IsA("Model") then
	-- 	warn(`[{script.Name}] Entity is not a model: {entity}`)
	-- 	return nil
	-- end

	-- return entity:Clone()
end

function EntityFactory.getNewDoctorModel(_: EntityFactory): Model?
	return ((entityAssets:FindFirstChild("doctors") :: Folder):FindFirstChild("plague-doctor") :: Model):Clone() :: Model?
end

return EntityFactory
