--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local domain = ReplicatedStorage.client.domain
local sounds = ReplicatedStorage.assets.sounds:FindFirstChild("FootstepSounds") :: Folder

local CharacterState = require(domain.character["character-state"])

local FootstepController = {}

export type FootstepController = typeof(FootstepController)

local function getMaterial(humanoid: Humanoid): string
	local floorMaterial = humanoid.FloorMaterial

	if not floorMaterial then
		floorMaterial = Enum.Material.Air
	end

	return floorMaterial.Name
end

function FootstepController.jaegarInit(self: FootstepController)
	local humanoid = CharacterState:getHumanoid() :: Humanoid

	repeat
		task.wait()
		humanoid = CharacterState:getHumanoid() :: any
	until humanoid

	local walking = false
	local lastMaterial: string?
	local lastPlayingSound: Sound?

	humanoid.Running:Connect(function(speed: number)
		if speed > humanoid.WalkSpeed / 2 then
			walking = true
		else
			walking = false
		end
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		if not humanoid then
			return
		end

		if walking then
			local material = getMaterial(humanoid)
			if not material then
				lastPlayingSound = nil
				return
			end

			if material == lastMaterial then
				return
			end

			if material ~= lastMaterial and lastMaterial ~= nil then
				if lastPlayingSound then
					lastPlayingSound:Stop()
					lastPlayingSound = nil
				end
			end

			local sound = sounds:FindFirstChild(material) :: Sound?
			if not sound then
				return
			end

			sound.PlaybackSpeed = humanoid.WalkSpeed / 12
			sound:Play()

			lastMaterial = material
			lastPlayingSound = sound
		else
			if lastPlayingSound then
				lastPlayingSound:Stop()
				lastPlayingSound = nil
			end
		end
	end)
end

return FootstepController
