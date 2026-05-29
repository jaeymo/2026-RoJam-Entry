--!strict
local Misc = {}

export type Misc = typeof(Misc)

workspace.DescendantAdded:Connect(function(desc: Instance)
	if desc.Name == "PlagueDoctor" then
		print(desc)
		desc:AddTag("Plague_Doctor")
		desc:AddTag("Shopkeeper")
	end
end)

return Misc
