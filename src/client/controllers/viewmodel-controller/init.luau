--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Janitor = require(ReplicatedStorage.packages.janitor)
local ViewmodelObject = require(script["viewmodel-object"])

local object = ViewmodelObject.new()
object:init()

local ViewmodelController = {
	janitor = Janitor.new(),
	isActive = false,
	viewmodelObject = object,
}

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
	self:enable()
	self.viewmodelObject:disable()

	-- temporary equip handling
	local temporaryFlag = false

	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.KeyCode ~= Enum.KeyCode.One then
			return
		end

		temporaryFlag = not temporaryFlag

		if temporaryFlag then
			self.viewmodelObject:enable()
		else
			self.viewmodelObject:disable()
		end
	end)
end

return ViewmodelController
