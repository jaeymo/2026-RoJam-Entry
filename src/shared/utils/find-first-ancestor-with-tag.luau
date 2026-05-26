--!strict
local CollectionService = game:GetService("CollectionService")

local function findFirstAncestorWithTag(instance: Instance, tag: string): Instance?
	local current = instance.Parent

	while current do
		if CollectionService:HasTag(current, tag) then
			return current
		end

		current = current.Parent
	end

	return nil
end

return findFirstAncestorWithTag
