--!strict
local Players = game:GetService("Players")

local PlayerInitialization = {}

local function handlePlayer(player: Player)
	player:AddTag("Player")
end

for _, player in Players:GetPlayers() do
	handlePlayer(player)
end

Players.PlayerAdded:Connect(handlePlayer)

return PlayerInitialization
