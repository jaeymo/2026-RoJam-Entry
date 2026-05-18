--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SignalRegistry = require(ServerScriptService["signal-registry"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local TemporarySleepHandler = {}

export type TemporarySleepHandler = typeof(TemporarySleepHandler)

Viewer.WatchTag("SleepProximityPrompt", false, function(instance: Instance)
	local proxy = instance :: ProximityPrompt

	local tempFlag = false

	proxy.Triggered:Connect(function(_: Player)
		if tempFlag then
			return
		end

		tempFlag = true
		SignalRegistry.playerSlept:Fire()
	end)
end)

return TemporarySleepHandler
