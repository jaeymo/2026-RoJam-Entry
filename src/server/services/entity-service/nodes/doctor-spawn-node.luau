--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EntityFactory = require(script.Parent.Parent["entity-factory"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local DoctorSpawnNode = {}

export type DoctorSpawnNode = typeof(DoctorSpawnNode)

Viewer.WatchTag("DoctorSpawnNode", false, function(instance: Instance)
	if instance:IsDescendantOf(ReplicatedStorage) then
		return
	end

	local newDoctorModel = EntityFactory:getNewDoctorModel()
	if not newDoctorModel then
		warn(`[{script.Name}] Failed to get new doctor model`)
		return
	end

	newDoctorModel:PivotTo((instance :: BasePart).CFrame * CFrame.new(0, 3, 0))
	newDoctorModel:AddTag("Ragdoll")
	newDoctorModel:AddTag("Entity")
	newDoctorModel:AddTag("Plague_Doctor")
	newDoctorModel.Parent = workspace
end)

return DoctorSpawnNode
