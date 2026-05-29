local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])

local materials = ReplicatedStorage.assets.sounds.FootstepSounds:Clone()
materials.Parent = SoundService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

local WALK_PLAYBACK_SPEED = 1.1
local SPRINT_PLAYBACK_SPEED = 1.45

local FootstepsController = {}

export type FootstepsController = typeof(FootstepsController)

local function getMaterial(): string
	local floorMaterial = hum.FloorMaterial

	local material = string.split(tostring(floorMaterial), "Enum.Material.")[2]

	return material or "Air"
end

function FootstepsController.jaegarInit()
	local lastMaterial: string? = nil
	local currentSound: Sound? = nil

	RunService.Heartbeat:Connect(function()
		local speed = CharacterState:getSpeed()
		local moving = speed > 0.5

		if moving then
			local material = getMaterial()
			local materialSound = materials:FindFirstChild(material) :: Sound?

			if not materialSound then
				return
			end

			if currentSound ~= materialSound or not materialSound.IsPlaying then
				if currentSound then
					currentSound:Stop()
				end

				currentSound = materialSound
				currentSound.Looped = true
				currentSound:Play()
			end

			local sprinting = ReplicatedStorage["global-data"].isSprinting.Value
			currentSound.PlaybackSpeed = sprinting and SPRINT_PLAYBACK_SPEED or WALK_PLAYBACK_SPEED
			lastMaterial = material
		else
			if currentSound then
				currentSound:Stop()
				currentSound = nil
			end

			lastMaterial = nil
		end
	end)
end

return FootstepsController
