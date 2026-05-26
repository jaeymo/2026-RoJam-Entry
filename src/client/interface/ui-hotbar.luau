--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules //--
local Config = require(ReplicatedStorage.shared.configs.configuration)
local Janitor = require(ReplicatedStorage.packages.janitor)
local SignalRegistery = require(ReplicatedStorage.client["client-signal-registry"])

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local Inventory = Main:WaitForChild("Inventory") :: Frame
local Template = Inventory:WaitForChild("Template") :: Frame

--// Main Coce //--
local UiHotbar = {
	janitor = Janitor.new(),
	slots = {},
	currentlyActive = nil,
}

export type UiHotbar = typeof(UiHotbar)

function UiHotbar:createSlots()
	for KeyCode, ItemName in Config.Items do
		local Clone = Template:Clone()

		Clone.Visible = true
		Clone.Name = ItemName

		local ItemNameLabel = Clone:WaitForChild("TextLabel")
		local Keybind = Clone:WaitForChild("Keybind")

		local Number =
			KeyCode.Name:gsub("One", "1"):gsub("Two", "2"):gsub("Three", "3"):gsub("Four", "4"):gsub("Five", "5")

		ItemNameLabel.Text = ItemName

		Keybind.Text = Number
		Clone.LayoutOrder = tonumber(Number)

		self:setSlotActive(Clone, false)

		Clone.Parent = Inventory

		self.slots[ItemName] = Clone
	end

	Template.Visible = false
end

function UiHotbar:watchSignals()
	self.janitor:Add(SignalRegistery.itemEquipped:Connect(function(ItemName: string)
		self:setActive(ItemName)
	end))

	self.janitor:Add(SignalRegistery.itemUnequipped:Connect(function(ItemName: string)
		self:clearActive(ItemName)
	end))
end

function UiHotbar:setActive(itemName: string)
	if self.currentlyActive then
		self:clearActive(self.currentlyActive)
	end

	local slot = self.slots[itemName]

	if not slot then
		return
	end

	self.currentlyActive = itemName

	self:setSlotActive(slot, true)
end

function UiHotbar:clearActive(itemName: string)
	local slot = self.slots[itemName]

	if not slot then
		return
	end

	self.currentlyActive = nil

	self:setSlotActive(slot, false)
end

function UiHotbar:setSlotActive(slot: Frame, state: boolean)
	local activeFrame = slot:FindFirstChild("Active")
	if activeFrame then
		activeFrame.Enabled = state
	end
end

function UiHotbar:destroy(self: UiHotbar)
	self.janitor:Cleanup()
end

function UiHotbar.jaegarInit(self: UiHotbar)
	self:createSlots()
	self:watchSignals()
end

return UiHotbar
