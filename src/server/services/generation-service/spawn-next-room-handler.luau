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

	-- jaeymo set this to true so the collision spawners are disabled for now
	local flag = true

	janitor:Add(instance.Touched:Connect(function(hit: BasePart)
		if flag then
			return
		end

		if not hit.Parent then
			return
		end

		if not hit.Parent:HasTag("Character") then
			print(hit, 2)
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
