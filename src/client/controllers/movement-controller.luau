--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local domain = ReplicatedStorage.client.domain

local localPlayer = Players.LocalPlayer

local CharacterState = require(domain.character["character-state"])
local Janitor = require(ReplicatedStorage.packages.janitor)
local SignalRegistry = require(ReplicatedStorage.client["client-signal-registry"])

local FREEFALL = Enum.HumanoidStateType.Freefall
local JUMPING = Enum.HumanoidStateType.Jumping
local LANDED = Enum.HumanoidStateType.Landed

local MovementController = {
	janitor = Janitor.new(),
	_isInAir = false,
	_isJumping = false,
	_fallStartTime = nil :: number?,
}

export type MovementController = typeof(MovementController)

function MovementController.getSpeed(_: MovementController): number
	return CharacterState:getSpeed()
end

function MovementController.getMoveDirection(_: MovementController): Vector3
	return CharacterState:getMoveDirection()
end

function MovementController.getFacingDirection(_: MovementController): Vector3
	return CharacterState:getFacingDirection()
end

function MovementController.isOnGround(_: MovementController): boolean
	return CharacterState:isOnGround()
end

function MovementController.isInAir(_: MovementController): boolean
	return CharacterState:isInAir()
end

function MovementController._watchHumanoidState(self: MovementController)
	local humanoid = CharacterState:getHumanoid() :: Humanoid

	repeat
		task.wait(0.1)
		humanoid = CharacterState:getHumanoid() :: any
	until humanoid

	self.janitor:Add(humanoid.StateChanged:Connect(function(_, newState: Enum.HumanoidStateType)
		if newState == FREEFALL and not self._isInAir then
			self:_freefall()
		elseif newState == JUMPING and not self._isJumping then
			self:_jump()
		end
	end))
end

function MovementController._freefall(self: MovementController)
	self._isInAir = true
	self._fallStartTime = os.clock()

	local canFire = false

	while task.wait() do
		local humanoid = CharacterState:getHumanoid()
		if not humanoid then
			break
		end

		if humanoid:GetState() == LANDED then
			canFire = true
			break
		end
	end

	if canFire then
		local character = localPlayer.Character
		if character then
			local fallDuration = os.clock() - self._fallStartTime :: number
			SignalRegistry.landed:Fire(character, fallDuration)
		end
	end

	self._isInAir = false
	self._fallStartTime = nil
end

function MovementController._jump(self: MovementController)
	local character = localPlayer.Character
	local humanoid = CharacterState:getHumanoid()

	self._isJumping = true

	if character then
		SignalRegistry.jumped:Fire(character)
	end

	while humanoid and humanoid:GetState() == JUMPING do
		task.wait()
	end

	self._isJumping = false
end

function MovementController.jaegarInit(self: MovementController)
	self:_watchHumanoidState()
end

return MovementController
