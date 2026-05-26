--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BetterAnimation = require(ReplicatedStorage.packages["better-animation"])
local SignalRegistry = require(ReplicatedStorage.client["client-signal-registry"])
local ViewmodelObject = require(script["viewmodel-object"])

local rig = ReplicatedStorage.assets.viewmodel:FindFirstChild("rig") :: Model
local viewmodelItems = ReplicatedStorage.assets.models:FindFirstChild("viewmodel-models") :: Folder

local ViewmodelController = {
	animationObject = BetterAnimation.new("viewmodel"),
	viewmodelObject = ViewmodelObject.new(rig),
	cachedItems = {},
}

export type ViewmodelController = typeof(ViewmodelController)

do
	local animator = rig:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
	ViewmodelController.animationObject:RegisterAnimator(animator)
	ViewmodelController.animationObject:RegisterAnimationsFromInstance(
		(ReplicatedStorage.assets:FindFirstChild("animations") :: Folder):FindFirstChild("viewmodel") :: Folder
	)

	ViewmodelController.viewmodelObject:init()

	local scepter = (viewmodelItems:FindFirstChild("Scepter") :: Model):Clone()
	-- local flintAndSteel = (viewmodelItems:FindFirstChild("FlintAndSteel") :: Model):Clone()

	ViewmodelController.cachedItems["Scepter"] = scepter
end

function ViewmodelController.getViewmodel(self: ViewmodelController): ViewmodelObject.ViewmodelObject
	return self.viewmodelObject
end

function ViewmodelController.jaegarInit(self: ViewmodelController)
	self:getViewmodel():enable()

	-- task.delay(3, function()
	-- 	self:getViewmodel():equip(scepter)

	-- 	local index = 1
	-- 	while task.wait(2.25) do
	-- 		local animations = {
	-- 			"ViewModelBatter",
	-- 			"ViewModelBonk",
	-- 			"ViewModelPoke",
	-- 			"ViewModelPeck",
	-- 		}

	-- 		self.animationObject:Play(animations[index], false)

	-- 		index += 1
	-- 		if index > 4 then
	-- 			index = 1
	-- 		end
	-- 	end
	-- end)

	SignalRegistry.itemEquipped:Connect(function(itemName: string)
		local model = self.cachedItems[itemName]
		if not model then
			return
		end

		if itemName == "Scepter" then
			self:getViewmodel():setArmInvisible("left")
		end

		self:getViewmodel():equip(model)
	end)

	SignalRegistry.itemUnequipped:Connect(function(itemName: string)
		self:getViewmodel():unequip()
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject, _: boolean)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		self:getViewmodel():updateMouseDelta(Vector2.new(input.Delta.X, input.Delta.Y))
	end)

	SignalRegistry.jumped:Connect(function()
		self:getViewmodel():onJump()
	end)

	SignalRegistry.landed:Connect(function()
		self:getViewmodel():onLand()
	end)
end

return ViewmodelController
