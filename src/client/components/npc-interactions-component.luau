--!nocheck

--// Services //--
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

--// Modules //--
local Classy = require(ReplicatedStorage.packages.classy)
local Config = require(ReplicatedStorage.shared.configs.configuration)

--// Variables //--
local ActiveConfig = {}
local UsedMessages = {}

local Keybinds = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
}

--// Client Variables //--
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local PlayerGui = Player:WaitForChild("PlayerGui")

local ScreenGui = PlayerGui:WaitForChild("ui-assets"):WaitForChild("NPCInteraction")

local TradeFrame = ScreenGui:WaitForChild("List"):WaitForChild("Gird"):WaitForChild("Trade")
local TalkFrame = ScreenGui:WaitForChild("List"):WaitForChild("Gird"):WaitForChild("Talk")
local CureFrame = ScreenGui:WaitForChild("List"):WaitForChild("Gird"):WaitForChild("Cure")
local ExitFrame = ScreenGui:WaitForChild("List"):WaitForChild("Exit")

local Sound = ScreenGui:WaitForChild("List"):WaitForChild("Sounds"):WaitForChild("Select")

--// Main Code //--
local NPC_Ineractions = {}

NPC_Ineractions.Cooldown = false
NPC_Ineractions.ActiveNPC = nil
NPC_Ineractions.ActiveActions = {}

local function SystemMessage(Model: Model, Text: string)
	local Head = Model:FindFirstChild("Head") or Model.PrimaryPart
	if not Head then
		return
	end

	TextChatService:DisplayBubble(Head, Text)
end

local function GetConfigForNPC(NPC: Model)
	local FoundConfig = Config.NPC_Interactions.NonAggressiveNPCs

	for Name, Table in Config.NPC_Interactions do
		if Name == "NonAggressiveNPCs" then
			continue
		end

		if NPC:HasTag(Name) then
			FoundConfig = Table
			break
		end
	end

	return FoundConfig
end

local function RunTalk()
	local NPC = NPC_Ineractions.ActiveNPC
	if not NPC then
		return
	end

	UsedMessages[NPC] = UsedMessages[NPC] or {}

	local Used = UsedMessages[NPC]

	local Available = {}

	for Index, Dialogue in ipairs(ActiveConfig.Dialogue) do
		if not Used[Index] then
			table.insert(Available, {
				Index = Index,
				Data = Dialogue,
			})
		end
	end

	if #Available <= 0 then
		local YouMessage = ActiveConfig.OutOfMessages.YOU[math.random(1, #ActiveConfig.OutOfMessages.YOU)]

		local NPCMessage = ActiveConfig.OutOfMessages.NPC[math.random(1, #ActiveConfig.OutOfMessages.NPC)]

		SystemMessage(Character, YouMessage)

		task.delay(1, function()
			SystemMessage(NPC, NPCMessage)
		end)

		return
	end

	local Chosen = Available[math.random(1, #Available)]

	Used[Chosen.Index] = true

	local Dialogue = Chosen.Data

	SystemMessage(Character, Dialogue.YOU)

	task.delay(1, function()
		SystemMessage(NPC, Dialogue.NPC)

		if Dialogue.Followups and #Dialogue.Followups > 0 then
			local Followup = Dialogue.Followups[math.random(1, #Dialogue.Followups)]

			task.delay(1, function()
				SystemMessage(Character, Followup.YOU)

				task.delay(1, function()
					SystemMessage(NPC, Followup.NPC)
				end)
			end)
		end
	end)
end

local function RunInfectedInteraction()
	if not NPC_Ineractions.ActiveNPC:GetAttribute("Infected") then
		return
	end

	local Messages = ActiveConfig.Specials.Infected

	if not Messages or #Messages <= 0 then
		return
	end

	SystemMessage(NPC_Ineractions.ActiveNPC, Messages[math.random(1, #Messages)])
end

local function CloseUI()
	ScreenGui.Enabled = false
	NPC_Ineractions.ActiveNPC = nil
	NPC_Ineractions.Cooldown = nil

	ActiveConfig = {}
	table.clear(NPC_Ineractions.ActiveActions)
end

local function RunAction(Action: string)
	if NPC_Ineractions.Cooldown then
		return
	end

	NPC_Ineractions.Cooldown = true

	Sound:Play()

	if Action == "Talk" then
		RunTalk()
		CloseUI()
	elseif Action == "Exit" then
		if NPC_Ineractions.ActiveNPC and NPC_Ineractions.ActiveNPC:GetAttribute("Infected") then
			RunInfectedInteraction()
		end

		CloseUI()
	else
		local Functions = ActiveConfig.Functions

		if Functions and Functions[Action] then
			Functions[Action](NPC_Ineractions.ActiveNPC)
		end

		CloseUI()
	end

	task.delay(1, function()
		NPC_Ineractions.Cooldown = false
	end)
end

local function SetupUI(NPC: Instance)
	TradeFrame.Visible = false
	TalkFrame.Visible = false
	CureFrame.Visible = false

	local Actions = {}

	if NPC:GetAttribute("CanTrade") then
		table.insert(Actions, "Trade")
	end

	table.insert(Actions, "Talk")

	if NPC:GetAttribute("Infected") then
		table.insert(Actions, "Cure")
	end

	local Highest = #Actions + 1

	NPC_Ineractions.ActiveActions = {}

	for Index, Action in ipairs(Actions) do
		NPC_Ineractions.ActiveActions[Keybinds[Index]] = Action

		if Action == "Trade" then
			TradeFrame.Visible = true
			TradeFrame.Keybind.Text = tostring(Index)
		elseif Action == "Talk" then
			TalkFrame.Visible = true
			TalkFrame.Keybind.Text = tostring(Index)
		elseif Action == "Cure" then
			CureFrame.Visible = true
			CureFrame.Keybind.Text = tostring(Index)
		end
	end

	NPC_Ineractions.ActiveActions[Keybinds[Highest]] = "Exit"
	ExitFrame.Keybind.Text = tostring(Highest)

	NPC_Ineractions.ActiveNPC = NPC
	ActiveConfig = GetConfigForNPC(NPC)

	ScreenGui.Enabled = true
end

local function SetupPrompt(NPC: Instance)
	if NPC:HasTag("AggressiveAI") then
		return
	end

	local PrimaryPart = NPC:FindFirstChild("HumanoidRootPart") or NPC.PrimaryPart
	if not PrimaryPart then
		return
	end

	if PrimaryPart:FindFirstChild("NPCPrompt") then
		return
	end

	local Prompt = Instance.new("ProximityPrompt")
	Prompt.Name = "NPCPrompt"
	Prompt.ActionText = ""
	Prompt.RequiresLineOfSight = false
	Prompt.Parent = PrimaryPart
end

UserInputService.InputBegan:Connect(function(Input: InputObject, GPE: boolean)
	if GPE then
		return
	end

	local Action = NPC_Ineractions.ActiveActions[Input.KeyCode]

	if Action then
		RunAction(Action)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(ProximityPrompt: ProximityPrompt)
	local Model = ProximityPrompt:FindFirstAncestorOfClass("Model")
	if not Model or not Model.PrimaryPart then
		return
	end

	SetupUI(Model)
end)

Classy.create("NPC", function(NPC: Instance)
	task.spawn(function()
		SetupPrompt(NPC)
	end)

	return {
		Init = function() end,
		Destroy = function() end,
	}
end)

return NPC_Ineractions
