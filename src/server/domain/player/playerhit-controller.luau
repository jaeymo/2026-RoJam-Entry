--// Services //--
local HapticService = game:GetService("HapticService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules //--
local HealthService = require("../../services/health-service")
local config = require(ReplicatedStorage.shared.configs.configuration)

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local Network = Jaegar:GetNetwork()

--// Variables //--
local Data = config.Infection

local Colors = {
	Purple = Color3.fromRGB(170, 0, 255),
	Yellow = Color3.fromRGB(255, 255, 0),
	Green = Color3.fromRGB(0, 150, 0),
}

local ColorList = {
	Colors.Purple,
	Colors.Yellow,
	Colors.Green,
}

--// Main Code //--
local PlayerHitController = {}

local function Infect(Player: Player)
	local Character = Player.Character :: Model
	if not Character then
		return
	end

	if Player:GetAttribute("Infected") then
		HealthService:removeHealthFrom(Character, Data.Damage_PerHit)
		return
	end

	Player:SetAttribute("Infected", ColorList[math.random(1, #ColorList)])

	task.spawn(function()
		local HealthTick = 0
		local MaxHealthTick = 0

		while Player:GetAttribute("Infected") do
			local DeltaTime = task.wait(1)

			if not Character then
				break
			end

			HealthTick += DeltaTime
			MaxHealthTick += DeltaTime

			if HealthTick >= Data.Health_Drain then
				HealthTick = 0

				HealthService:removeHealthFrom(Character, Data.Health_Take)

				if HealthService:getHealth(Character) <= 0 then
					break
				end
			end

			if MaxHealthTick >= Data.MaxHealth_Drain then
				MaxHealthTick = 0

				local MaxHealth = HealthService:getMaxHealth(Character)

				if MaxHealth > Data.Min_MaxHealth then
					HealthService:setMaxHealth(Character, math.max(Data.Min_MaxHealth, MaxHealth - Data.MaxHealth_Take))
				end
			end
		end
	end)
end

function PlayerHitController.Deinfect(Player: Player)
	Player:SetAttribute("Infected", nil)

	local Character = Player.Character :: Model
	if not Character then
		return
	end

	HealthService:setHealth(Character, HealthService:getMaxHealth(Character))
end

ProximityPromptService.PromptTriggered:Connect(function(Prompt: ProximityPrompt, Player: Player)
	local Base = Prompt.Parent
	if not Base or not Player then
		return
	end

	local InfectionColor = Player:GetAttribute("Infected")
	if not InfectionColor then
		return
	end

	for Tag, Color in Colors do
		if Base:HasTag(Tag) and InfectionColor == Color then
			PlayerHitController.Deinfect(Player)
			break
		end
	end
end)

Network:OnServer("sendHit", Infect)

return PlayerHitController
