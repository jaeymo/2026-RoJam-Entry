--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Modules //--
local Viewer = require(ReplicatedStorage.packages.viewer)

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local Health = Main:WaitForChild("Health") :: Frame
local Bar = Health:WaitForChild("Bar") :: Frame

local Character = Player.Character or Player.CharacterAdded:Wait()

local CurrentHealth = Character:GetAttribute("Health") or 100
local MaxHealth = Character:GetAttribute("MaxHealth") or 100

local OriginalBarColor = Bar.BackgroundColor3
local CurrentBarColor = OriginalBarColor

local HealthTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PulseTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--// Main Code //--
local UiHealth = {}

local function UpdateHealth()
	local HealthPercent = math.clamp(CurrentHealth / MaxHealth, 0, 1)
	local MaxHealthPercent = math.clamp(MaxHealth / 100, 0, 1)

	local BarSize = Bar.Size
	local HealthSize = Health.Size

	TweenService:Create(Bar, HealthTweenInfo, {
		Size = UDim2.new(HealthPercent, 0, BarSize.Y.Scale, BarSize.Y.Offset),
	}):Play()

	TweenService:Create(Health, HealthTweenInfo, {
		Size = UDim2.new(0.218 * MaxHealthPercent, 0, HealthSize.Y.Scale, HealthSize.Y.Offset),
	}):Play()
end

local function PulseDamage()
	local RedTween = TweenService:Create(Bar, PulseTweenInfo, { BackgroundColor3 = Color3.fromRGB(255, 60, 60) })
	local BackTween = TweenService:Create(Bar, PulseTweenInfo, { BackgroundColor3 = CurrentBarColor })

	RedTween:Play()

	RedTween.Completed:Once(function()
		BackTween:Play()
	end)
end

task.spawn(function()
	while true do
		TweenService
			:Create(Health, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = 0.5 })
			:Play()

		task.wait(2)

		TweenService
			:Create(Health, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = -3 })
			:Play()

		task.wait(2)
	end
end)

Viewer.WatchAttribute(Character, "Health", function(NewValue)
	NewValue = tonumber(NewValue) or 0

	if NewValue < CurrentHealth then
		PulseDamage()
	end

	CurrentHealth = NewValue

	UpdateHealth()
end)

Viewer.WatchAttribute(Character, "MaxHealth", function(NewValue)
	MaxHealth = tonumber(NewValue) or 100

	UpdateHealth()
end)

Viewer.WatchAttribute(Player, "Infected", function(Value)
	if Value then
		CurrentBarColor = Value

		TweenService:Create(
			Bar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Value }
		):Play()
	else
		CurrentBarColor = OriginalBarColor

		TweenService:Create(
			Bar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundColor3 = OriginalBarColor }
		):Play()
	end
end)

UpdateHealth()

return UiHealth
