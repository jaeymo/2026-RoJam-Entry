--!nocheck

--// Services //--
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--// Modules //--
local Classy = require(ReplicatedStorage.packages.classy)
local StatsHandler = require(ServerScriptService.domain.leaderstats["stats-handler"])

--// Main Code //--
local Dead_NPC = {}

local function SetupPrompt(NPC: Instance)
	local InfectionLevel = NPC:GetAttribute("Infected")
	if InfectionLevel and InfectionLevel > 0 then
		return
	end

	local PrimaryPart = NPC:FindFirstChild("HumanoidRootPart") or NPC.PrimaryPart
	if not PrimaryPart then
		return
	end

	if PrimaryPart:FindFirstChild("DeadPrompt") then
		return
	end

	local Prompt = Instance.new("ProximityPrompt")
	Prompt.Name = "DeadPrompt"
	Prompt.ActionText = ""
	Prompt.RequiresLineOfSight = false
	Prompt.Parent = PrimaryPart
end

ProximityPromptService.PromptTriggered:Connect(function(Prompt: ProximityPrompt, Player: Player)
	if Prompt.Name ~= "DeadPrompt" then
		return
	end

	Prompt:Destroy()

	StatsHandler.ModifyStat(Player, "Tolls", 1)
end)

Classy.create("Dead", function(NPC: Instance)
	task.spawn(function()
		SetupPrompt(NPC)
	end)

	return {
		Init = function() end,
		Destroy = function() end,
	}
end)

return Dead_NPC
