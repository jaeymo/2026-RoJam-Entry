--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local SignalRegistry = require(ServerScriptService["signal-registry"])

local network = Jaegar:GetNetwork()

local DialogueService = {}

export type DialogueService = typeof(DialogueService)

function DialogueService.startConversation(_: DialogueService, targetEntity: Model)
	SignalRegistry.conversationStarted:Fire(targetEntity)
end

function DialogueService.stopConversation(_: DialogueService, targetEntity: Model)
	SignalRegistry.conversationEnded:Fire(targetEntity)
end

function DialogueService.jaegarInit(self: DialogueService)
	network:OnServer("startDialogueConversation", function(_: Player, targetEntity: Instance)
		self:startConversation(targetEntity :: Model)
	end)

	network:OnServer("endDialogueConversation", function(_: Player, targetEntity: Instance)
		self:stopConversation(targetEntity :: Model)
	end)
end

return DialogueService
