local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])

local materials = ReplicatedStorage.assets.sounds.FootstepSounds:Clone()
materials.Parent = SoundService

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

local WALK_PLAYBACK_SPEED = 0.975
local SPRINT_PLAYBACK_SPEED = 1.35
local FOOTSTEP_FADE_TIME = 0.15
local FOOTSTEP_VOLUME = 0.35

local FootstepsController = {}

export type FootstepsController = typeof(FootstepsController)

local function fadeIn(sound: Sound)
	TweenService:Create(sound, TweenInfo.new(FOOTSTEP_FADE_TIME), {
		Volume = FOOTSTEP_VOLUME,
	}):Play()
end

local function fadeOut(sound: Sound)
	local tween = TweenService:Create(sound, TweenInfo.new(FOOTSTEP_FADE_TIME), {
		Volume = 0,
	})

	tween:Play()

	tween.Completed:Once(function()
		if sound.Volume <= 0.01 then
			sound:Stop()
		end
	end)
end

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
		local moving = speed > 8

		if moving then
			local material = getMaterial()
			local materialSound = materials:FindFirstChild(material) :: Sound?

			if not materialSound then
				return
			end

			if currentSound ~= materialSound or not materialSound.IsPlaying then
				if currentSound then
					fadeOut(currentSound)
				end

				currentSound = materialSound
				currentSound.Looped = true

				if not currentSound.IsPlaying then
					currentSound.Volume = 0
					currentSound:Play()

					fadeIn(currentSound)
				end
			end

			local sprinting = ReplicatedStorage["global-data"].isSprinting.Value
			currentSound.PlaybackSpeed = sprinting and SPRINT_PLAYBACK_SPEED or WALK_PLAYBACK_SPEED
			lastMaterial = material
		else
			if currentSound then
				fadeOut(currentSound)
				currentSound = nil
			end

			lastMaterial = nil
		end
	end)
end

return FootstepsController
