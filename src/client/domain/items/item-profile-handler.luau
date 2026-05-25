--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StringUtil = require(ReplicatedStorage.shared.utils["string-util"])

local ItemProfileHandler = {
	profiles = {} :: { [string]: ItemImpl },
}

export type ItemImpl = {
	equip: (self: ItemImpl) -> (),
	unequip: (self: ItemImpl) -> (),
	primary: (self: ItemImpl) -> (),
}

do
	for _, v in script.Parent.profiles:GetChildren() do
		ItemProfileHandler.profiles[StringUtil:kebabToPascal(v.Name)] = require(v) :: any
	end
end

export type ItemProfileHandler = typeof(ItemProfileHandler)

function ItemProfileHandler.getProfile(self: ItemProfileHandler, itemName: string): ItemImpl
	return self.profiles[itemName] or error(`[{script.Name}] Failed to get profile for: {itemName}`)
end

return ItemProfileHandler
