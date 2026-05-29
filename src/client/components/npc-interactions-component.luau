--!nocheck

--[[
	this isnt a component!!! f u maxx
	-- jaeymo btw
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
local InfectedController = require(ReplicatedStorage.client.controllers["infected-controller"])
local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local Viewer = require(ReplicatedStorage.packages.viewer)

--// Variables //--
local RESET_DURATION = 2

local ActiveConfig = {}

local UsedDialogue = {}
local UsedOutOfMessage = {}
local UsedInfectionDialogue = {}

local Prompts = {}

local Network = Jaegar:GetNetwork()

local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")

local ScreenGui = PlayerGui:WaitForChild("ui-assets"):WaitForChild("NPCInteraction")

local FirstList = ScreenGui:WaitForChild("FirstList") :: Frame

local TalkFrame = FirstList:WaitForChild("Talk") :: Frame
local TreatmentFrame = FirstList:WaitForChild("Treatment") :: Frame

local SecondList = ScreenGui:WaitForChild("SecondList") :: Frame

local GarlicFrame = SecondList:WaitForChild("Garlic") :: Frame
local EmeraldsFrame = SecondList:WaitForChild("Emeralds") :: Frame
-- local ExitFrame = SecondList:WaitForChild("Exit") :: Frame

local Sound = ScreenGui:WaitForChild("Sounds"):WaitForChild("Select") :: Sound

local Character = Player.Character or Player.CharacterAdded:Wait()

--// Main Code //--
local NPC_Interactions = {}

NPC_Interactions.Cooldown = false
NPC_Interactions.ActiveNPC = nil :: Model?

NPC_Interactions.ActiveActions = {}
NPC_Interactions.ActiveActions[Enum.KeyCode.E] = "Exit"

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

local function RunInfectedInteraction()
	local NPC = NPC_Interactions.ActiveNPC
	if not NPC then
		return
	end

	local Level = NPC:GetAttribute("InfectedLevel") or 0
	if Level <= 0 then
		print(NPC)
		print(1)
		return
	end

	local Pools = ActiveConfig.InfectedLevel
	if not Pools then
		print(2)
		return
	end

	local Pool = Pools[Level]
	if not Pool or #Pool <= 0 then
		print(3)
		return
	end

	UsedInfectionDialogue[Level] = UsedInfectionDialogue[Level] or {}

	local Message = GetUniqueDialogue(Pool, UsedInfectionDialogue[Level])
	NPC_Interactions.SystemMessage(NPC, Message)
end

local function RunHealedInteraction()
	local NPC = NPC_Interactions.ActiveNPC
	if not NPC then
		return
	end

	local Pools = Config.Healed
	local RandomMessage = Pools[math.random(1, #Pools)]

	NPC_Interactions.SystemMessage(NPC, RandomMessage)
end

local function RunTalk()
	local NPC = NPC_Interactions.ActiveNPC
	if not NPC then
		return
	end

	if NPC:HasTag("HealedInfection") then
		RunHealedInteraction()
		return
	end

	if (NPC:GetAttribute("InfectedLevel") or 0) >= 0 then
		RunInfectedInteraction()
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

	local UsedConfig = ActiveConfig.Dialogue

	local Dialogue = GetUniqueDialogue(UsedConfig, UsedDialogue[FoundConfig], false)

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

local function RunTreatment(prompt: ProximityPrompt)
	if NPC_Interactions.ActiveNPC then
		if NPC_Interactions.ActiveNPC:HasTag("HealedInfection") then
			print("ALREADY HEALED")
			NPC_Interactions.runAction("Exit", prompt)
			return
		end
	end

	FirstList.Visible = false
	SecondList.Visible = true

	GarlicFrame.Amount.Text = tostring(Player:GetAttribute("Garlic") or 0)
	EmeraldsFrame.Amount.Text = tostring(Player:GetAttribute("Emeralds") or 0)

	table.clear(NPC_Interactions.ActiveActions)

	NPC_Interactions.ActiveActions[Enum.KeyCode.One] = "Garlic"
	NPC_Interactions.ActiveActions[Enum.KeyCode.Two] = "Emeralds"
	NPC_Interactions.ActiveActions[Enum.KeyCode.E] = "Exit"

	GarlicFrame.Keybind.Text = "1"
	EmeraldsFrame.Keybind.Text = "2"
end

local function CloseUI()
	ScreenGui.Enabled = false

	FirstList.Visible = true
	SecondList.Visible = false

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

local function RunAction(Action: string, Prompt: ProximityPrompt)
	if Action == "Exit" and Prompt then
		Prompt.Enabled = true
		print(debug.traceback())
	end

	Sound:Play()

	if Action ~= "Treatment" then
		Network:SendServer("endDialogueConversation", NPC_Interactions.ActiveNPC)
		ReplicatedStorage["global-data"].isInDialogue.Value = false
	end

	if Action == "Talk" then
		if NPC_Interactions.Cooldown then
			return
		end

		NPC_Interactions.Cooldown = true

		SetPromptsState(false)

		RunTalk()
		CloseUI()

		task.delay(RESET_DURATION, function()
			NPC_Interactions.Cooldown = false
			SetPromptsState(true)
		end)
	elseif Action == "Treatment" then
		RunTreatment(Prompt)
	elseif Action == "Garlic" or Action == "Emeralds" then
		InfectedController:treatEntity(
			NPC_Interactions.ActiveNPC,
			NPC_Interactions.ActiveNPC:GetAttribute("InfectedLevel"),
			Action
		)
		RunAction("Exit")
	elseif Action == "Exit" then
		if NPC_Interactions.Cooldown then
			return
		end

		NPC_Interactions.Cooldown = true

		SetPromptsState(false)

		CloseUI()

		task.delay(RESET_DURATION, function()
			NPC_Interactions.Cooldown = false
			SetPromptsState(true)
		end)
	else
		if NPC_Interactions.Cooldown then
			return
		end

		NPC_Interactions.Cooldown = true

		SetPromptsState(false)

		local Functions = ActiveConfig.Functions

		if Functions and Functions[Action] then
			Functions[Action](NPC_Interactions.ActiveNPC)
		end

		CloseUI()

		task.delay(RESET_DURATION, function()
			NPC_Interactions.Cooldown = false
			SetPromptsState(true)
		end)
	end
end

local function SetupUI(NPC: Instance, Prompt: ProximityPrompt)
	Prompt.Enabled = false
	SecondList.Visible = false
	FirstList.Visible = true

	TalkFrame.Visible = true
	TreatmentFrame.Visible = true

	NPC_Interactions.ActiveActions = {}

	Network:SendServer("startDialogueConversation", NPC)
	ReplicatedStorage["global-data"].isInDialogue.Value = true

	NPC_Interactions.ActiveActions[Enum.KeyCode.One] = "Talk"
	NPC_Interactions.ActiveActions[Enum.KeyCode.Two] = "Treatment"
	NPC_Interactions.ActiveActions[Enum.KeyCode.E] = "Exit"

	TalkFrame.Keybind.Text = "1"
	TreatmentFrame.Keybind.Text = "2"

	NPC_Interactions.ActiveNPC = NPC
	ActiveConfig = GetConfigForNPC(NPC)

	ScreenGui.Enabled = true

	task.spawn(function()
		while NPC_Interactions.ActiveNPC == NPC do
			if NPC_Interactions.ActiveNPC:HasTag("Dead") or NPC_Interactions.ActiveNPC:HasTag("AggressiveAI") then
				task.spawn(function()
					RunAction("Exit", Prompt)
				end)
			end
			task.wait()
		end
	end)

	task.spawn(function()
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local RootPart = Character:FindFirstChild("HumanoidRootPart")

		while ScreenGui.Enabled and NPC_Interactions.ActiveNPC == NPC do
			task.wait(0.1)

			if not RootPart or not RootPart.Parent then
				Character = Player.Character or Player.CharacterAdded:Wait()
				RootPart = Character:FindFirstChild("HumanoidRootPart")
			end

			local NPCRoot = NPC:FindFirstChild("HumanoidRootPart") or NPC.PrimaryPart
			if not NPCRoot or not RootPart then
				break
			end

			local Distance = (RootPart.Position - NPCRoot.Position).Magnitude

			if Distance > 12 then
				RunAction("Exit", Prompt)
				break
			end
		end
	end)
end

local function SetupPrompt(NPC: Instance)
	if NPC:HasTag("AggressiveAI") then
		return
	end

	local PrimaryPart = NPC:WaitForChild("Client") and NPC:WaitForChild("Client"):WaitForChild("HumanoidRootPart")
	if not PrimaryPart then
		warn(`[{script.Name}] Failed to get primary part for: {NPC:GetFullName()}`)
		return
	end

	if PrimaryPart:FindFirstChild("NPCPrompt") then
		return
	end

	local Prompt = Instance.new("ProximityPrompt")
	Prompt.Name = "NPCPrompt"
	Prompt.ClickablePrompt = false
	Prompt.ActionText = ""
	Prompt.RequiresLineOfSight = false
	Prompt.Parent = PrimaryPart

	table.insert(Prompts, Prompt)
end

function NPC_Interactions.runAction(actionName: string, prompt: ProximityPrompt)
	RunAction(actionName, prompt)
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

	local Model = ProximityPrompt.Parent and ProximityPrompt.Parent.Parent and ProximityPrompt.Parent.Parent.Parent
	if not Model or not Model.PrimaryPart then
		return
	end

	if Model:HasTag("Dead") then
		return
	end

	SetupUI(Model, ProximityPrompt)
end)

Viewer.WatchAttribute(Character, "Health", function(_)
	if ScreenGui.Enabled then
		RunAction("Exit")
	end
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
