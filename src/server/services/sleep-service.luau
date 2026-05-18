--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local SignalRegistry = require(ServerScriptService["signal-registry"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local network = Jaegar:GetNetwork()

local SleepService = {
	sleepCount = 0,
}

export type SleepService = typeof(SleepService)

function SleepService.initiateSleepProcess(self: SleepService)
	print("bang")
	network:Broadcast("playerSlept")
end

function SleepService.finishSleepProcess(self: SleepService)
	print("bang bang")
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
