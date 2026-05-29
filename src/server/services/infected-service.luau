--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	local hasAtleastOneOfTreatmentType = ((player.Character:GetAttribute(treatmentType) :: number) or 0) >= 0
	print(entityModel, infectedLevel, treatmentType, hasAtleastOneOfTreatmentType)

	if not hasAtleastOneOfTreatmentType then
		return
	end
end

function InfectedService.jaegarInit(self: InfectedService)
	network:OnServer("treatEntity", function(player: Player, entityModel: Model, treatmentType: "Garlic" | "Emeralds")
		local infectedLevel = (entityModel:GetAttribute("InfectedLevel") :: number?) or 0
		self:treatEntity(entityModel, infectedLevel, treatmentType)
	end)
end

return InfectedService
