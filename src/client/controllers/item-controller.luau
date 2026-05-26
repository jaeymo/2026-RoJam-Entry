--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local domain = ReplicatedStorage.client.domain

local ItemProfileHandler = require(domain.items["item-profile-handler"])
local Janitor = require(ReplicatedStorage.packages.janitor)
local SignalRegistry = require(ReplicatedStorage.client["client-signal-registry"])
local config = require(ReplicatedStorage.shared.configs.configuration)

local ItemController = {
	currentlyHeldItem = nil :: string?,
	janitor = Janitor.new(),
}

export type ItemController = typeof(ItemController)

function ItemController.start(self: ItemController)
	self:watchInputs()
end

function ItemController.stop(self: ItemController)
	self.janitor:Cleanup()
end

function ItemController.toggleEquip(self: ItemController, newHeldItem: string)
	if self.currentlyHeldItem == newHeldItem then
		self:unequipCurrent(false)
		return
	end

	if self.currentlyHeldItem ~= nil then
		self:unequipCurrent(true)
		self:equip(newHeldItem)
		return
	end

	self:equip(newHeldItem)
end

function ItemController.equip(self: ItemController, itemName: string)
	self.currentlyHeldItem = itemName
	SignalRegistry.itemEquipped:Fire(itemName)
	ItemProfileHandler:getProfile(itemName):equip()
end

function ItemController.unequipCurrent(self: ItemController, isEquippingNext: boolean)
	if not self.currentlyHeldItem then
		return
	end

	local old = self.currentlyHeldItem
	self.currentlyHeldItem = nil
	SignalRegistry.itemUnequipped:Fire(old, isEquippingNext)
	ItemProfileHandler:getProfile(old):unequip()
end

function ItemController.primary(self: ItemController)
	if not self.currentlyHeldItem then
		return
	end

	SignalRegistry.itemPrimary:Fire(self.currentlyHeldItem)
	ItemProfileHandler:getProfile(self.currentlyHeldItem):primary()
end

function ItemController.watchInputs(self: ItemController)
	self.janitor:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:primary()
		end

		local itemName = config.Items[input.KeyCode]
		if itemName then
			self:toggleEquip(itemName)
		end
	end))
end

function ItemController.jaegarInit(self: ItemController)
	self:start()
end

return ItemController
