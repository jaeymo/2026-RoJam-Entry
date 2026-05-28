--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()

local network = Jaegar:GetNetwork()

local InfectedController = {}

local TREATMENT_MAP = {
	["Garlic"] = 1,
	["Emerald"] = 2,
}

export type InfectedController = typeof(InfectedController)

function InfectedController.treatEntity(
	self: InfectedController,
	entity: Model,
	entityInfectedLevel: number,
	treatmentType: string
)
	print(entity, entityInfectedLevel, treatmentType, TREATMENT_MAP[treatmentType])
end

return InfectedController
