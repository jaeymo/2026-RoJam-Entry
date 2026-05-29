--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.shared.configs.configuration)
local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local StatsHandler = require(ServerScriptService.domain.leaderstats["stats-handler"])

local network = Jaegar:GetNetwork()

local TradeService = {}

export type TradeService = typeof(TradeService)

-- function TradeService.jaegarInit(self: TradeService)
-- 	network:OnServer("trade", function(player: Player, item: string)
-- 		local price = Config.Shop[item]
-- 		print(price, item)

-- 		StatsHandler.ModifyStat(player, item, -price)
-- 	end)
-- end

return TradeService
