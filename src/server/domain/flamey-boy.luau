--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlameyBoy = {}

local Jaeger = require(ReplicatedStorage.packages.jaegar):Server()
local Network = Jaeger:GetNetwork()

local BackpackComponent = require(ReplicatedStorage.shared.components["backpack-component"])
local HealthService = require(ServerScriptService.services["health-service"])
local MutationService = require(ServerScriptService.services["mutation-service"])
local StatsHandler = require(ServerScriptService.domain.leaderstats["stats-handler"])

export type FlameyBoy = typeof(FlameyBoy)

Network:OnServer("damageNPC", function(_, charModel: Model, damage: number)
	if charModel:HasTag("WanderingAI") then
		-- charModel:SetAttribute("InitialTransitionState", "Stunned")
		MutationService:swapFromWanderingToAggressive(charModel)
	end

	if charModel:GetAttribute("DeathTollCollected") then
		return
	end

	charModel:SetAttribute("BurnTick", os.clock())
	charModel:SetAttribute("State", "Burning")

	if HealthService:getHealth(charModel) <= 0 then
		charModel:AddTag("PleaseIgnore")
		charModel:SetAttribute("Burned", true)
		charModel:AddTag("Burned")
		charModel:SetAttribute("DeathTollCollected", true)

		if charModel:GetAttribute("OriginalEntityType") == "Aggressive" then
			if Players:GetPlayers()[1] then
				StatsHandler.ModifyStat(Players:GetPlayers()[1], "Tolls", 1)
				BackpackComponent.classy:GetApplied(Players:GetPlayers()[1]):GetData():addResource("FireCharge", 1)
			end
		else
			print("you killed a harmless npc!")
		end
	end
end)

return FlameyBoy
