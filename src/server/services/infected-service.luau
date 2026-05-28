--!strict
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
	print(entityModel, infectedLevel, treatmentType)
end

function InfectedService.jaegarInit(self: InfectedService)
	network:OnServer("treatEntity", function(player: Player, entityModel: Model, treatmentType: "Garlic" | "Emeralds")
		local infectedLevel = entityModel:GetAttribute("InfectedLevel") or 0
		print(entityModel, infectedLevel, treatmentType)
	end)
end

return InfectedService
