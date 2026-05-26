--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FindFirstAncestorWithTag = require(ReplicatedStorage.shared.utils["find-first-ancestor-with-tag"])
local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local SignalRegistry = require(ServerScriptService["signal-registry"])

local network = Jaegar:GetNetwork()

local CombatService = {}

export type CombatService = typeof(CombatService)

function CombatService.jaegarInit(_: CombatService)
	network:OnServer("processScepterHits", function(_: Player, hits: { Humanoid })
		for _, hit in hits do
			local entity = FindFirstAncestorWithTag(hit, "Entity")
			if not entity then
				continue
			end

			SignalRegistry.hitEntity:Fire(entity :: Model)
		end
	end)
end

return CombatService
