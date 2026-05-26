--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local SignalRegistry = require(ServerScriptService["signal-registry"])

local network = Jaegar:GetNetwork()

local CombatService = {}

export type CombatService = typeof(CombatService)

function CombatService.jaegarInit(_: CombatService)
	network:OnServer("processScepterHits", function(_: Player, hits: { Model })
		for _, hit in hits do
			SignalRegistry.hitEntity:Fire(hit :: Model, "Poke")
		end
	end)
end

return CombatService
