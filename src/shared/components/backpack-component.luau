--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)

local BackpackComponent = {}
BackpackComponent.__index = BackpackComponent

export type BackpackComponent = typeof(setmetatable(
	{} :: {
		instance: Instance,
		janitor: Classy.Janitor,
		resources: { [string]: number },
	},
	BackpackComponent
))

function BackpackComponent.new(instance: Instance, janitor: Classy.Janitor): BackpackComponent
	return setmetatable({
		instance = instance,
		janitor = janitor,
		resources = {},
	}, BackpackComponent)
end

function BackpackComponent.setResource(self: BackpackComponent, resourceName: string, amount: number)
	self.resources[resourceName] = amount
	self.instance:SetAttribute(resourceName, amount)
end

function BackpackComponent.addResource(self: BackpackComponent, resourceName: string, amount: number): number
	if not self.resources[resourceName] then
		self.resources[resourceName] = 0
	end

	self.resources[resourceName] += amount
	self.instance:SetAttribute(resourceName, self.resources[resourceName])

	return self.resources[resourceName]
end

function BackpackComponent.removeResource(self: BackpackComponent, resourceName: string, amount: number)
	self:addResource(resourceName, amount * -1)
end

function BackpackComponent.clearResource(self: BackpackComponent, resourceName: string)
	self.resources[resourceName] = 0
end

function BackpackComponent.getResource(self: BackpackComponent, resourceName: string): number
	return self.resources[resourceName] or 0
end

BackpackComponent.classy = Classy.create("Tag", BackpackComponent, {
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("Tag", BackpackComponent.classy)

return BackpackComponent
