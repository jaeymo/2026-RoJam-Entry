--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local domain = ReplicatedStorage.client.domain

local CharacterState = require(domain.character["character-state"])
local SignalRegistry = require(ReplicatedStorage.client["client-signal-registry"])

local MovementController = {}

export type MovementController = typeof(MovementController)

function MovementController.isOnGround(self: MovementController): boolean
	return CharacterState:isOnGround()
end

function MovementController.isInAir(self: MovementController): boolean
	return CharacterState:isInAir()
end

function MovementController._freefall(self: MovementController) end

function MovementController._jump(self: MovementController) end

return MovementController
