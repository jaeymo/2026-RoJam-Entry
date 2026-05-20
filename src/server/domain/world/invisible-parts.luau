--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classy = require(ReplicatedStorage.packages.classy)

local InvisibleParts = {}

export type InvisibleParts = typeof(InvisibleParts)

Classy.create("Invisible", function(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
	end

	return 0
end, {
	ClassNames = { "BasePart" },
})

return InvisibleParts
