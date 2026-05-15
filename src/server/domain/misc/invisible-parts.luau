--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classy = require(ReplicatedStorage.packages.classy)

local MapMeshCollision = {}

export type MapMeshCollision = typeof(MapMeshCollision)

Classy.new("NoCollision", function(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
	end

	return 0
end, {
	ClassNames = { "BasePart" },
})

return MapMeshCollision
