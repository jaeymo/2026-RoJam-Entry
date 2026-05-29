--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackComponent = require(ReplicatedStorage.shared.components["backpack-component"])
local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()

local network = Jaegar:GetNetwork()

local PlayerInitialization = {}

local function handlePlayer(player: Player)
	player:AddTag("Player")

	local component = BackpackComponent.classy:Apply(player)
	component:GetData():setResource("Garlic", 3)
	component:GetData():setResource("Emeralds", 1)
	component:GetData():setResource("SandCharge", 1)
	component:GetData():setResource("FireCharge", 3)
end

function PlayerInitialization.jaegarInit()
	network:OnServer("useCharge", function(player: Player, chargeType: string)
		local component = BackpackComponent.classy:GetApplied(player)
		if not component then
			error("failed")
			return
		end

		component:GetData():removeResource(chargeType, 1)
	end)
end

for _, player in Players:GetPlayers() do
	handlePlayer(player)
end

Players.PlayerAdded:Connect(handlePlayer)

return PlayerInitialization
