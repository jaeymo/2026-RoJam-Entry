--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local maskingSGui = Instance.new("ScreenGui")
maskingSGui.IgnoreGuiInset = true
maskingSGui.Name = ""
maskingSGui.Parent = playerGui

local maskingFrame = Instance.new("Frame")
maskingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
maskingFrame.Size = UDim2.fromScale(1.5, 1.5)
maskingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
maskingFrame.Transparency = 1
maskingFrame.Position = UDim2.fromScale(0.5, 0.5)
maskingFrame.Parent = maskingSGui

local UiMasking = {}

export type UiMasking = typeof(UiMasking)

function UiMasking.mask(_: UiMasking, tweenInfo: TweenInfo?): Tween
	maskingFrame.Transparency = 1

	local info = tweenInfo or TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local t = TweenService:Create(maskingFrame, info, { Transparency = 0 })
	t:Play()

	return t
end

function UiMasking.unmask(_: UiMasking, tweenInfo: TweenInfo?)
	maskingFrame.Transparency = 0

	local info = tweenInfo or TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local t = TweenService:Create(maskingFrame, info, { Transparency = 1 })
	t:Play()

	return t
end

return UiMasking
