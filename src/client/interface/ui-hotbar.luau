--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Modules //--
local Config = require(ReplicatedStorage.shared.configs.configuration)
local Janitor = require(ReplicatedStorage.packages.janitor)
local SignalRegistery = require(ReplicatedStorage.client["client-signal-registry"])

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local Inventory = Main:WaitForChild("Inventory") :: Frame

--// Main Coce //--
local UiHotbar = {
	janitor = Janitor.new(),
	slots = {},
	currentlyActive = nil,
	hideThread = nil,
}

export type UiHotbar = typeof(UiHotbar)

local function Tween(Object: Instance, Time: number, Properties: {})
	local TweenObject =
		TweenService:Create(Object, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Properties)

	TweenObject:Play()

	return TweenObject
end

local function TweenSlotOut(Slot: Frame)
	local Label = Slot:FindFirstChild("TextLabel")

	Tween(Slot, 0.35, { Position = UDim2.fromScale(0, Slot.Position.Y.Scale) })

	if Label then
		Tween(Label, 0.175, { TextColor3 = Color3.fromRGB(255, 0, 0) })
	end
end

local function TweenSlotIn(Slot: Frame, Active: boolean?)
	local Label = Slot:FindFirstChild("TextLabel")

	Tween(Slot, 0.35, { Position = UDim2.fromScale(0.5, Slot.Position.Y.Scale) })

	if Label and not Active then
		Tween(Label, 0.175, { TextColor3 = Color3.fromRGB(255, 255, 255) })
	end
end

function UiHotbar:createSlots()
	for _, ItemName in Config.Items do
		local Slot = Inventory:FindFirstChild(ItemName)
		if not Slot then
			continue
		end

		self.slots[ItemName] = Slot

		Slot.Position = UDim2.fromScale(0.5, Slot.Position.Y.Scale)

		local Label: TextLabel = Slot:FindFirstChild("TextLabel")
		if Label then
			Label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
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
	local NewSlot = self.slots[itemName]
	if not NewSlot then
		return
	end

	if self.hideThread then
		task.cancel(self.hideThread)
		self.hideThread = nil
	end

	if self.currentlyActive then
		local OldSlot = self.slots[self.currentlyActive]
		if OldSlot then
			TweenSlotIn(OldSlot)
		end
	end

	self.currentlyActive = itemName

	TweenSlotOut(NewSlot)

	self.hideThread = task.delay(5, function()
		if self.currentlyActive ~= itemName then
			return
		end

		TweenSlotIn(NewSlot, true)
	end)
end

function UiHotbar:clearActive(itemName: string)
	local Slot = self.slots[itemName]
	if not Slot then
		return
	end

	if self.hideThread then
		task.cancel(self.hideThread)
		self.hideThread = nil
	end

	self.currentlyActive = nil

	TweenSlotIn(Slot)
end

function UiHotbar:destroy(self: UiHotbar)
	self.janitor:Cleanup()
end

function UiHotbar.jaegarInit(self: UiHotbar)
	self:createSlots()
	self:watchSignals()
end

return UiHotbar
