--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local entityAssets = ReplicatedStorage.assets.entities
local testCharacters = entityAssets.test

local EntityFactory = {}

export type EntityFactory = typeof(EntityFactory)

function EntityFactory.getNewEntityModel(_: EntityFactory, jobName: string): Model?
	local jobFolder = ReplicatedStorage.assets.entities:FindFirstChild(string.lower(jobName))
	local newModel = (jobFolder:GetChildren()[math.random(1, #jobFolder:GetChildren())]) :: Model
	return newModel:Clone()
end

function EntityFactory.getNewDoctorModel(_: EntityFactory): Model?
	return ((entityAssets:FindFirstChild("doctors") :: Folder):FindFirstChild("plague-doctor") :: Model):Clone() :: Model?
end

return EntityFactory
