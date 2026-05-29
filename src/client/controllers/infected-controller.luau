--!strict
local Debris = game:GetService("Debris")
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
	local hasAtleastOneOfTreatmentType = ((player:GetAttribute(treatmentType) :: number) or 0) > 0
	if not hasAtleastOneOfTreatmentType then
		return
	end

	local levelOfTreatment = TREATMENT_MAP[treatmentType]
	local doesTreatmentWork = levelOfTreatment >= entityInfectedLevel

	network:SendServer("treatEntity", entity, treatmentType, doesTreatmentWork)

	if doesTreatmentWork then
		local CureBlock = ReplicatedStorage.assets.particles["Cure?"]:Clone()
		CureBlock.Position = entity:GetPivot().Position
		CureBlock.Parent = workspace.runtime
		Debris:AddItem(CureBlock, 5)
		CureBlock.Attachment.Cross:Emit(1)
		CureBlock.Feathers:Emit(160)
	else
		print("NAH, NO WORK!")
	end
end

return InfectedController
