--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GenerationTypes = require(script.Parent.types)

local mapAssets = ReplicatedStorage.assets.map

local GenerationFactory = {}

export type GenerationFactory = typeof(GenerationFactory)

function GenerationFactory.getNewRoomAsset(_: GenerationFactory, name: string): GenerationTypes.Room?
	local room = mapAssets:FindFirstChild(name)
	if not room then
		warn(`[{script.Name}] Failed to find map room by the name of: {name}`)
		return
	end

	if not room:IsA("Model") then
		warn(`[{script.Name}] Room is not a model: {room}`)
		return
	end

	room = room:Clone()

	room:WaitForChild("Nodes"):WaitForChild("Room")
	room:WaitForChild("Nodes"):WaitForChild("Path")
	room:WaitForChild("Nodes"):WaitForChild("Barricade")

	return room :: GenerationTypes.Room
end

return GenerationFactory
