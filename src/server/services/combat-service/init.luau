--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local ScepterConfig = require(ReplicatedStorage.shared.configs["scepter-config"])
local SignalRegistry = require(ServerScriptService["signal-registry"])

local network = Jaegar:GetNetwork()

local CombatService = {}

export type CombatService = typeof(CombatService)

function CombatService.jaegarInit(_: CombatService)
	network:OnServer("processScepterHits", function(_: Player, hits: { Model }, attackName: string)
		local attackData = ScepterConfig.attacks[attackName] :: ScepterConfig.AttackData
		if not attackData then
			warn(`[{script.Name}] No attack data... because stupid???`)
			return
		end

		for _, hit in hits do
			if hit:HasTag("WanderingAI") then
				SignalRegistry.hitPassive:Fire(hit :: Model)
				continue
			end
			SignalRegistry.hitEntity:Fire(hit :: Model, attackData.Damage, attackName)
		end
	end)
end

return CombatService
