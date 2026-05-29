--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackComponent = require(ReplicatedStorage.shared.components["backpack-component"])

local PlayerInitialization = {}

local function handlePlayer(player: Player)
	player:AddTag("Player")

	local component = BackpackComponent.classy:Apply(player)
	component:GetData():setResource("Garlic", 10)
	component:GetData():setResource("Emeralds", 10)
	component:GetData():setResource("SandCharges", 0)
end

for _, player in Players:GetPlayers() do
	handlePlayer(player)
end

Players.PlayerAdded:Connect(handlePlayer)

return PlayerInitialization
