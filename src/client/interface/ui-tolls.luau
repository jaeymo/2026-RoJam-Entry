--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Roman = require(ReplicatedStorage.shared.utils.roman)
local Viewer = require(ReplicatedStorage.packages.viewer)

local UiTolls = {}

export type UiTolls = typeof(UiTolls)

local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)
local GOLD_COLOR = Color3.fromRGB(255, 215, 75)

local FLASH_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RETURN_TWEEN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function UiTolls.jaegarInit(_: UiTolls)
	local deathTolls = Players.LocalPlayer
		:WaitForChild("PlayerGui")
		:WaitForChild("ui-assets")
		:WaitForChild("Canvas")
		:WaitForChild("DeathTolls")
		:WaitForChild("Amount") :: TextLabel

	local currentAnimationId = 0

	local function animateKill(amountGained: number)
		currentAnimationId += 1
		local animationId = currentAnimationId

		local flashCount = math.clamp(amountGained, 1, 4)

		task.spawn(function()
			for _ = 1, flashCount do
				if animationId ~= currentAnimationId then
					return
				end

				local flashTween = TweenService:Create(deathTolls, FLASH_TWEEN_INFO, {
					TextColor3 = GOLD_COLOR,
				})

				flashTween:Play()
				flashTween.Completed:Wait()

				if animationId ~= currentAnimationId then
					return
				end

				local returnTween = TweenService:Create(deathTolls, RETURN_TWEEN_INFO, {
					TextColor3 = DEFAULT_COLOR,
					TextSize = 32,
				})

				returnTween:Play()
				returnTween.Completed:Wait()

				task.wait(0.03)
			end
		end)
	end

	local previousValue = 0

	Viewer.WatchAttribute(Players.LocalPlayer, "Tolls", function(newValue: number)
		if newValue == 0 then
			deathTolls.Text = "N"
		else
			deathTolls.Text = Roman.ToRoman(newValue)
		end

		local difference = newValue - previousValue

		if difference > 0 then
			animateKill(difference)
		end

		previousValue = newValue
	end, false)
end

return UiTolls
