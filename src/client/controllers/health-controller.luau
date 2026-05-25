--!nocheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)
local Ragdoller = require(ReplicatedStorage.packages.ragdoller)
local Viewer = require(ReplicatedStorage.packages.viewer)

local player = Players.LocalPlayer

local HealthController = {}

export type HealthController = typeof(HealthController)

function HealthController.jaegarInit(_: HealthController)
	Viewer.WatchTag("Dead", false, function(instance: Instance)
		if player and player.Character and player.Character == instance then
			return
		end

		Ragdoller:activateRagdoll(instance :: Model)
	end)
end

return HealthController
