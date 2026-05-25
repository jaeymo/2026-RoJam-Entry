--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local StatsHandler = require(ServerScriptService.domain.leaderstats["stats-handler"])

local network = Jaegar:GetNetwork()

local DeathTollHandler = {}

export type DeathTollHandler = typeof(DeathTollHandler)

local function collectBody(player: Player, entityModel: Instance)
	StatsHandler.ModifyStat(player, "Tolls", 1)
	-- print(entityModel)
end

function DeathTollHandler.jaegarInit(_: DeathTollHandler)
	network:OnServer("collectDeathToll", function(player: Player, entityModel: Instance)
		collectBody(player, entityModel)
	end)
end

return DeathTollHandler
