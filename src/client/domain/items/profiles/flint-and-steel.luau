--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewmodelController
local HitboxController

local FlintAndSteel = {}

export type FlintAndSteel = typeof(FlintAndSteel)

function FlintAndSteel.equip(self: FlintAndSteel)
	print(self)
	ViewmodelController.animationObject:Play("ViewModelFNSIdle")
	ViewmodelController:getViewmodel():setArmVisible("left")
end

function FlintAndSteel.unequip(self: FlintAndSteel)
	ViewmodelController.animationObject:Stop("ViewModelFNSIdle")
	print(self)
end

function FlintAndSteel.primary(self: FlintAndSteel)
	print(self)
end

function FlintAndSteel.jaegarInit(_: FlintAndSteel)
	ViewmodelController = require(ReplicatedStorage.client.controllers["viewmodel-controller"])
	HitboxController = require(ReplicatedStorage.client.controllers["hitbox-controller"])
end

return FlintAndSteel
