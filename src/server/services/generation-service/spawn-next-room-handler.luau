--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)
local SignalRegistry = require(ServerScriptService["signal-registry"])

local SpawnNextRoomHandler = {}

export type SpawnNextRoomHandler = typeof(SpawnNextRoomHandler)

Classy.create("SpawnNextRoom", function(instance, janitor)
	if not instance:IsA("BasePart") then
		return instance
	end

	local flag = false

	print(instance)

	janitor:Add(instance.Touched:Connect(function(hit: BasePart)
		print(hit)
		if flag then
			return
		end

		if not hit.Parent then
			print(1, hit)
			return
		end

		if not hit.Parent:HasTag("Character") then
			print(2, hit)
			return
		end

		print(hit)

		flag = true
		SignalRegistry.spawnNextRoomTouched:Fire()
	end))

	return instance
end, {
	ClassNames = { "BasePart" },
})

return SpawnNextRoomHandler
