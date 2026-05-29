--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()

local player = Players.LocalPlayer
local network = Jaegar:GetNetwork()

local InfectedController = {}

local TREATMENT_MAP = {
	["Garlic"] = 1,
	["Emeralds"] = 2,
}

export type InfectedController = typeof(InfectedController)

function InfectedController.treatEntity(
	self: InfectedController,
	entity: Model,
	entityInfectedLevel: number,
	treatmentType: string
)
	local character = player.Character
	if not character then
		return
	end

	local hasAtleastOneOfTreatmentType = ((character:GetAttribute(treatmentType) :: number) or 0) >= 0
	if not hasAtleastOneOfTreatmentType then
		return
	end

	network:SendServer("treatEntity", entity, treatmentType)
end

return InfectedController
