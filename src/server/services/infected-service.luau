--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackComponent = require(ReplicatedStorage.shared.components["backpack-component"])
local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()

local network = Jaegar:GetNetwork()

local InfectedService = {}

export type InfectedService = typeof(InfectedService)

function InfectedService.treatEntity(
	self: InfectedService,
	entityModel: Model,
	infectedLevel: number,
	treatmentType: "Garlic" | "Emeralds"
)
	local player = Players:GetPlayers()[1]
	if not player or not player.Character then
		return
	end

	local backpack = BackpackComponent.classy:GetApplied(player)

	if not backpack then
		warn(`[{script.Name}] Failed to get backpack`)
		return
	end

	local hasAtleastOneOfTreatmentType = backpack:GetData():getResource(treatmentType) > 0
	if not hasAtleastOneOfTreatmentType then
		warn(`[{script.Name}] NOOOo`)
		return
	end

	backpack:GetData():removeResource(treatmentType, 1)

	entityModel:AddTag("HealedInfection")
	entityModel:RemoveTag("TerminalMutation")
	entityModel:RemoveTag("AggressiveMutation")
end

function InfectedService.jaegarInit(self: InfectedService)
	network:OnServer("treatEntity", function(player: Player, entityModel: Model, treatmentType: "Garlic" | "Emeralds")
		local infectedLevel = (entityModel:GetAttribute("InfectedLevel") :: number?) or 0
		self:treatEntity(entityModel, infectedLevel, treatmentType)
	end)
end

return InfectedService
