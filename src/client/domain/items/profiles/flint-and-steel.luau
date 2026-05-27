--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charState = require(ReplicatedStorage.client.domain.character["character-state"])
local flameConnector = require(ReplicatedStorage.client.domain["flame-handler"])
local raydar = require(ReplicatedStorage.shared.utils.raydar)

local ViewmodelController
local HitboxController

local FlintAndSteel = {}

export type FlintAndSteel = typeof(FlintAndSteel)

function FlintAndSteel.equip(self: FlintAndSteel)
	ViewmodelController.animationObject:Play("ViewModelFNSIdle")
	ViewmodelController:getViewmodel():setArmVisible("left")
end

function FlintAndSteel.unequip(self: FlintAndSteel)
	ViewmodelController.animationObject:Stop("ViewModelFNSIdle")
	print(self)
end

function FlintAndSteel.primary(self: FlintAndSteel)
	ViewmodelController.animationObject:Play("ViewModelFNSSpark")

	ViewmodelController.animationObject:GetTrack("ViewModelFNSSpark"):GetMarkerReachedSignal("hit"):Wait()

	local forwardDist = 10
	local downwardDist = 6

	local forwardResult = raydar:Fire(
		charState:getRoot().Position,
		charState:getFacingDirection(),
		forwardDist,
		raydar.RayTypes.AimForEntities,
		charState:getCharacter()
	)

	if forwardResult then
		flameConnector:Spawn(forwardResult.Position, Vector3.one * 6)
		return
	end

	local downwardResult = raydar:Fire(
		charState:getRoot().Position + charState:getFacingDirection() * forwardDist,
		Vector3.yAxis * -1,
		downwardDist,
		raydar.RayTypes.AimForEntities,
		charState:getCharacter()
	)

	if downwardResult then
		flameConnector:Spawn(downwardResult.Position, Vector3.one * 6)
		return
	end

	print("Hit nuffin")
end

function FlintAndSteel.secondary(self: FlintAndSteel)
	print("secondary")
	flameConnector:Spawn(charState:getRoot().Position + charState:getFacingDirection() * 3, Vector3.one * 5, {})
end

function FlintAndSteel.jaegarInit(_: FlintAndSteel)
	ViewmodelController = require(ReplicatedStorage.client.controllers["viewmodel-controller"])
	HitboxController = require(ReplicatedStorage.client.controllers["hitbox-controller"])
end

return FlintAndSteel
