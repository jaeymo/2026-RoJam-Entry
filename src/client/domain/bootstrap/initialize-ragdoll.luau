--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoller = require(ReplicatedStorage.packages.ragdoller)
local Viewer = require(ReplicatedStorage.packages.viewer)

local player = Players.LocalPlayer

local InitializeRagdoll = {}

export type InitializeRagdoll = typeof(InitializeRagdoll)

-- dan, if you somehow see this, hi!
Viewer.WatchTag("Ragdoll", false, function(instance)
	if player.Character and player.Character == instance then
		return
	end

	Ragdoller:addRagdoll(instance :: Model)
end)

return InitializeRagdoll
