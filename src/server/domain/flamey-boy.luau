--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FlameyBoy = {}

local Jaeger = require(ReplicatedStorage.packages.jaegar):Server()
local Network = Jaeger:GetNetwork()

local HealthService = require(ServerScriptService.services["health-service"])

export type FlameyBoy = typeof(FlameyBoy)

Network:OnServer("damageNPC", function(_, charModel: Model, damage: number)
	charModel:SetAttribute("BurnTick", os.clock())
	charModel:SetAttribute("State", "Burning")
	if HealthService:getHealth(charModel) <= 0 then
		charModel:SetAttribute("Burned", true)
	end
end)

return FlameyBoy
