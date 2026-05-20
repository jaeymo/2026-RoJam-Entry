--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local HealthService = require(ServerScriptService.services["health-service"])

local PlayerInitialization = {}

local function handlePlayer(player: Player)
	player:AddTag("Player")
end

for _, player in Players:GetPlayers() do
	handlePlayer(player)
end

Players.PlayerAdded:Connect(handlePlayer)

return PlayerInitialization
