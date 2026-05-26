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
}

export type ViewmodelController = typeof(ViewmodelController)

do
	local animator = rig:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
	ViewmodelController.animationObject:RegisterAnimator(animator)
	ViewmodelController.animationObject:RegisterAnimationsFromInstance(
		(ReplicatedStorage.assets:FindFirstChild("animations") :: Folder):FindFirstChild("viewmodel") :: Folder
	)

	ViewmodelController.viewmodelObject:init()
end

function ViewmodelController.getViewmodel(self: ViewmodelController): ViewmodelObject.ViewmodelObject
	return self.viewmodelObject
end

function ViewmodelController.jaegarInit(self: ViewmodelController)
	self:getViewmodel():enable()

	task.delay(3, function()
		local scepter = viewmodelItems:FindFirstChild("Scepter"):Clone() :: Model

		self:getViewmodel():equip(scepter)
		print(scepter)

		while task.wait(1.5) do
			-- self.animationObject:Play("ViewModelBatter", false)
		end
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
