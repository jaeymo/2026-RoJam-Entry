--!nocheck

--// Services //--
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules //--
local Classy = require(ReplicatedStorage.packages.classy)
local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()

local Network = Jaegar:GetNetwork()

--// Main Code //--
local Dead_NPC = {}

local function SetupPrompt(NPC: Instance)
	local InfectionLevel = NPC:GetAttribute("Infected")
	if InfectionLevel and InfectionLevel > 0 then
		return
	end

	local Client = NPC:FindFirstChild("Client") or NPC:WaitForChild("Client", 10)
	if not Client then
		return
	end

	local PrimaryPart = Client:FindFirstChild("HumanoidRootPart") or Client.PrimaryPart
	if not PrimaryPart then
		warn(`[{script.Name}] Failed to get primary part for: {NPC:GetFullName()}`)
		return
	end

	if PrimaryPart:FindFirstChild("DeadPrompt") then
		return
	end

	local Prompt = Instance.new("ProximityPrompt")
	Prompt.Name = "DeadPrompt"
	Prompt.ActionText = "Collect"
	Prompt.RequiresLineOfSight = false
	Prompt.Parent = PrimaryPart
end

local function CollectBody(NPC: Model)
	print("COLLECTED: ", NPC)
end

ProximityPromptService.PromptTriggered:Connect(function(Prompt: ProximityPrompt, _: Player)
	if Prompt:GetAttribute("Collected") then
		return
	end

	if Prompt.Name ~= "DeadPrompt" then
		return
	end

	local NPC = Prompt.Parent.Parent.Parent
	if not NPC then
		warn(`[{script.Name}] Failed to get NPC for prompt: {Prompt:GetFullName()}`)
		return
	end

	Prompt:SetAttribute("Collected", true)
	Network:SendServer("collectDeathToll", NPC)
	CollectBody(NPC)
	Prompt:Destroy()
end)

Classy.create("Dead", function(NPC: Instance)
	task.spawn(function()
		SetupPrompt(NPC)

		if NPC:FindFirstChild("NPCPrompt", true) then
			NPC:FindFirstChild("NPCPrompt", true):Destroy()
		end
	end)

	return {
		Init = function() end,
		Destroy = function() end,
	}
end)

return Dead_NPC
