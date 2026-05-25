--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BetterAnimation = require(ReplicatedStorage.packages["better-animation"])
local Janitor = require(ReplicatedStorage.packages.janitor)
local SignalRegistry = require(ReplicatedStorage.client["client-signal-registry"])
local ViewmodelObject = require(script["viewmodel-object"])

local object = ViewmodelObject.new()
object:init()

local ViewmodelController = {
	janitor = Janitor.new(),
	isActive = false,
	viewmodelObject = object,
	animationObject = BetterAnimation.new("viewmodel"),
}

do
	ViewmodelController.animationObject:RegisterAnimator(object.animator)

	ViewmodelController.animationObject:RegisterAnimationsFromInstance(
		(ReplicatedStorage.assets:FindFirstChild("animations") :: any):FindFirstChild("viewmodel"),
		workspace:WaitForChild("runtime")
	)
end

export type ViewmodelController = typeof(ViewmodelController)

function ViewmodelController.enable(self: ViewmodelController)
	if self.isActive then
		return
	end

	self.viewmodelObject:enable()
	self.isActive = true

	self.janitor:Add(RunService.RenderStepped:Connect(function(dt: number)
		self.viewmodelObject:update(dt)
	end))

	self.janitor:Add(UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		self.viewmodelObject:updateDelta(Vector2.new(input.Delta.X, input.Delta.Y))
	end))
end

function ViewmodelController.disable(self: ViewmodelController)
	if not self.isActive then
		return
	end

	self.isActive = false
	self.viewmodelObject:disable()

	self.janitor:Cleanup()
end

function ViewmodelController.getViewmodelObject(self: ViewmodelController)
	return self.viewmodelObject
end

function ViewmodelController.jaegarInit(self: ViewmodelController)
	self:_setup()

	-- SignalRegistry.itemEquipped:Connect(function(_: string)
	-- 	self:getViewmodelObject():enable()
	-- 	-- self:getViewmodelObject():equip(ReplicatedStorage.assets.models["viewmodel-equippables"].template:Clone())
	-- end)

	-- SignalRegistry.itemUnequipped:Connect(function(_: string)
	-- 	self:getViewmodelObject():unequip()
	-- 	self:getViewmodelObject():disable()
	-- end)
end

function ViewmodelController._setup(self: ViewmodelController)
	self:enable()
	self.viewmodelObject:disable()

	SignalRegistry.jumped:Connect(function()
		self.viewmodelObject:onLand({ vertical = 1, horizontal = 1 }) -- multipliers if needed
	end)

	SignalRegistry.landed:Connect(function()
		self.viewmodelObject:onJump({ vertical = 1, horizontal = 1 })
	end)
end

return ViewmodelController
