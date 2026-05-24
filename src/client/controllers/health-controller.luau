--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoller = require(ReplicatedStorage.packages.ragdoller)
local Viewer = require(ReplicatedStorage.packages.viewer)

local player = Players.LocalPlayer

local HealthController = {}

export type HealthController = typeof(HealthController)

function HealthController.jaegarInit(_: HealthController)
	Viewer.WatchTag("Dead", false, function(instance: Instance)
		print(instance)
		if not instance:HasTag("Ragdoll") then
			return
		end

		if player and player.Character and player.Character == instance then
			return
		end

		Ragdoller:activateRagdoll(instance :: Model)
	end)
end

return HealthController
