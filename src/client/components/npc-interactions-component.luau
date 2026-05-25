--!nocheck

--[[
	this isnt a component!!!
]]

--// Services //--
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

--// Modules //--
local Classy = require(ReplicatedStorage.packages.classy)
local Config = require(ReplicatedStorage.shared.configs.dialogue)

--// Variables //--
local ActiveConfig = {}

local UsedDialogue = {}
local UsedOutOfMessage = {}
local UsedInfectionDialogue = {}

local Prompts = {}

local Keybinds = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
}

local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")

local ScreenGui = PlayerGui:WaitForChild("ui-assets"):WaitForChild("NPCInteraction")

local TradeFrame = ScreenGui:WaitForChild("List"):WaitForChild("Gird"):WaitForChild("Trade")
local TalkFrame = ScreenGui:WaitForChild("List"):WaitForChild("Gird"):WaitForChild("Talk")
local CureFrame = ScreenGui:WaitForChild("List"):WaitForChild("Gird"):WaitForChild("Cure")
local ExitFrame = ScreenGui:WaitForChild("List"):WaitForChild("Exit")

local Sound = ScreenGui:WaitForChild("List"):WaitForChild("Sounds"):WaitForChild("Select")

--// Main Code //--
local NPC_Interactions = {}

NPC_Interactions.Cooldown = false
NPC_Interactions.ActiveNPC = nil
NPC_Interactions.ActiveActions = {}

function NPC_Interactions.SystemMessage(Model: Model, Text: string)
	local Head = Model:FindFirstChild("Head") or Model.PrimaryPart
	if not Head then
		return
	end

	TextChatService:DisplayBubble(Head, Text)
end

local function GetConfigForNPC(NPC: Model)
	local FoundConfig = Config.NonAggressiveNPCs

	for Name, Table in Config do
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

local function GetUniqueDialogue(Pool: {}, UsedTable: {}, ResetOnEmpty: boolean?)
	local Available = {}

	for Index, Data in ipairs(Pool) do
		if not UsedTable[Index] then
			table.insert(Available, {
				Index = Index,
				Data = Data,
			})
		end
	end

	if #Available <= 0 then
		if not ResetOnEmpty then
			return nil
		end

		table.clear(UsedTable)

		for Index, Data in ipairs(Pool) do
			table.insert(Available, {
				Index = Index,
				Data = Data,
			})
		end
	end

	local Chosen = Available[math.random(1, #Available)]

	UsedTable[Chosen.Index] = true

	task.delay(30, function()
		UsedTable[Chosen.Index] = nil
	end)

	return Chosen.Data
end

local function RunTalk()
	local NPC = NPC_Interactions.ActiveNPC
	if not NPC then
		return
	end

	local FoundConfig = "NonAggressiveNPCs"

	for Name in Config do
		if Name ~= "NonAggressiveNPCs" and NPC:HasTag(Name) then
			FoundConfig = Name
			break
		end
	end

	UsedDialogue[FoundConfig] = UsedDialogue[FoundConfig] or {}
	UsedOutOfMessage[FoundConfig] = UsedOutOfMessage[FoundConfig] or {}

	local Dialogue = GetUniqueDialogue(ActiveConfig.Dialogue, UsedDialogue[FoundConfig], false)

	if not Dialogue then
		local Message = GetUniqueDialogue(ActiveConfig.OutOfMessages, UsedOutOfMessage[FoundConfig], true)

		NPC_Interactions.SystemMessage(NPC, Message)

		return
	end

	NPC_Interactions.SystemMessage(NPC, Dialogue.Text)

	if Dialogue.Followups and #Dialogue.Followups > 0 then
		task.delay(1.5, function()
			NPC_Interactions.SystemMessage(NPC, Dialogue.Followups[math.random(1, #Dialogue.Followups)])
		end)
	end
end

local function RunInfectedInteraction()
	local NPC = NPC_Interactions.ActiveNPC
	if not NPC then
		return
	end

	local Level = NPC:GetAttribute("Infected") or 0
	if Level <= 0 then
		return
	end

	local Pools = ActiveConfig.InfectedLevel
	if not Pools then
		return
	end

	local Pool = Pools[Level]
	if not Pool or #Pool <= 0 then
		return
	end

	UsedInfectionDialogue[Level] = UsedInfectionDialogue[Level] or {}

	local Message = GetUniqueDialogue(Pool, UsedInfectionDialogue[Level])

	NPC_Interactions.SystemMessage(NPC, Message)
end

local function CloseUI()
	ScreenGui.Enabled = false
	NPC_Interactions.ActiveNPC = nil
	NPC_Interactions.Cooldown = false

	ActiveConfig = {}
	table.clear(NPC_Interactions.ActiveActions)
end

local function SetPromptsState(State: boolean)
	for _, Prompt in Prompts do
		if Prompt and Prompt.Parent then
			Prompt.Enabled = State
		end
	end
end

local function RunAction(Action: string)
	if NPC_Interactions.Cooldown then
		return
	end

	SetPromptsState(false)
	NPC_Interactions.Cooldown = true

	Sound:Play()

	if Action == "Talk" then
		RunTalk()
		CloseUI()
	elseif Action == "Exit" then
		if NPC_Interactions.ActiveNPC and NPC_Interactions.ActiveNPC:GetAttribute("Infected") then
			RunInfectedInteraction()
		end

		CloseUI()
	else
		local Functions = ActiveConfig.Functions

		if Functions and Functions[Action] then
			Functions[Action](NPC_Interactions.ActiveNPC)
		end

		CloseUI()
	end

	task.delay(3, function()
		NPC_Interactions.Cooldown = false
		SetPromptsState(true)
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

	if not NPC:HasTag("Plague_Doctor") then
		table.insert(Actions, "Cure")
	end

	local Highest = #Actions + 1

	NPC_Interactions.ActiveActions = {}

	for Index, Action in ipairs(Actions) do
		NPC_Interactions.ActiveActions[Keybinds[Index]] = Action

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

	NPC_Interactions.ActiveActions[Keybinds[Highest]] = "Exit"
	ExitFrame.Keybind.Text = tostring(Highest)

	NPC_Interactions.ActiveNPC = NPC
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

	table.insert(Prompts, Prompt)
end

UserInputService.InputBegan:Connect(function(Input: InputObject, GPE: boolean)
	if GPE then
		return
	end

	local Action = NPC_Interactions.ActiveActions[Input.KeyCode]

	if Action then
		RunAction(Action)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(ProximityPrompt: ProximityPrompt)
	if ProximityPrompt.Name ~= "NPCPrompt" then
		return
	end

	local Model = ProximityPrompt:FindFirstAncestorOfClass("Model")
	if not Model or not Model.PrimaryPart then
		return
	end

	SetupUI(Model)
end)

Classy.create("Dialogue", function(NPC: Instance)
	task.spawn(function()
		SetupPrompt(NPC)
	end)

	return {
		Init = function() end,
		Destroy = function() end,
	}
end)

return NPC_Interactions
