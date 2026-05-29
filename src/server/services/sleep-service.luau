--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local PlayerHitController = require(ServerScriptService.domain.player["playerhit-controller"])
local SignalRegistry = require(ServerScriptService["signal-registry"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local network = Jaegar:GetNetwork()

local SleepService = {
	sleepCount = 0,
}

export type SleepService = typeof(SleepService)

function SleepService.initiateSleepProcess(self: SleepService)
	local player = Players:GetPlayers()[1]
	if player then
		PlayerHitController.Deinfect(player)
	end

	network:Broadcast("playerSlept", self.sleepCount)
end

function SleepService.finishSleepProcess(self: SleepService)
	for _, v in CollectionService:GetTagged("Entity") do
		v:Destroy()
	end

	self.sleepCount += 1
	SignalRegistry.playerSlept:Fire()
end

function SleepService.jaegarInit(self: SleepService)
	Viewer.WatchTag("SleepProximityPrompt", false, function(instance: Instance)
		local proxy = instance :: ProximityPrompt
		local tempFlag = false

		proxy.Triggered:Connect(function(_: Player)
			if tempFlag then
				return
			end

			tempFlag = true
			self:initiateSleepProcess()
		end)
	end)

	network:OnServer("playerSlept", function()
		self:finishSleepProcess()
	end)
end

return SleepService
