--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classy = require(ReplicatedStorage.packages.classy)

local NoCollisionParts = {}

export type NoCollisionParts = typeof(NoCollisionParts)

Classy.create("NoCollision", function(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CanCollide = false
	end

	return 0
end, {
	ClassNames = { "BasePart" },
})

return NoCollisionParts
