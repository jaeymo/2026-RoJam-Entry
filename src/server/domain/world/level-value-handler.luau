--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SignalRegistry = require(ServerScriptService["signal-registry"])

SignalRegistry.roomEntered:Connect(function()
	ReplicatedStorage["global-data"].room.Value += 1
end)

return {}
