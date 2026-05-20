--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoller = require(ReplicatedStorage.packages.ragdoller)
local Viewer = require(ReplicatedStorage.packages.viewer)

local InitializeRagdoll = {}

export type InitializeRagdoll = typeof(InitializeRagdoll)

-- dan, if you somehow see this, hi!
Viewer.WatchTag("Ragdoll", false, function(instance)
	local player = Players:GetPlayers()[1]

	if player and player.Character and player.Character == instance then
		return
	end

	Ragdoller:addRagdoll(instance :: Model)
end)

return InitializeRagdoll
