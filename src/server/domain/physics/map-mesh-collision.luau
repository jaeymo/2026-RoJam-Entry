--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classy = require(ReplicatedStorage.packages.classy)

local MapMeshCollision = {}

export type MapMeshCollision = typeof(MapMeshCollision)

Classy.new("Invisible", function(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CanCollide = false
	end

	return 0
end, {
	ClassNames = { "BasePart" },
})

return MapMeshCollision
