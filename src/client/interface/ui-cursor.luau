--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UiCursor = {}

local signals = require("../client-signal-registry")

export type UiCursor = typeof(UiCursor)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Mouse = Player:GetMouse()

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local ToolTip = Main:WaitForChild("ToolTip") :: TextLabel
local TextLabel = ToolTip:WaitForChild("TextLabel") :: TextLabel

Mouse.Icon = "rbxassetid://135894365640631"
UserInputService.MouseIconEnabled = false

signals.itemEquipped:Connect(function()
	UserInputService.MouseIconEnabled = true
end)

signals.itemUnequipped:Connect(function()
	UserInputService.MouseIconEnabled = false
end)

RunService.PreRender:Connect(function()
	local Target = Mouse.Target

	if not Target or not UserInputService.MouseIconEnabled then
		ToolTip.Visible = false
		TextLabel.Visible = false
		return
	end

	local Character = Player.Character
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart") :: BasePart

	if not HumanoidRootPart then
		ToolTip.Visible = false
		TextLabel.Visible = false
		return
	end

	local Distance = (HumanoidRootPart.Position - Target.Position).Magnitude

	if Distance > 10 then
		ToolTip.Visible = false
		TextLabel.Visible = false
		return
	end

	local FoundTooltip: string? = nil

	local Attribute = Target:GetAttribute("ToolTip")

	if typeof(Attribute) == "string" then
		FoundTooltip = Attribute
	else
		local Current = Target.Parent

		while Current do
			local ParentAttribute = Current:GetAttribute("ToolTip")

			if typeof(ParentAttribute) == "string" then
				FoundTooltip = ParentAttribute
				break
			end

			Current = Current.Parent
		end
	end

	if FoundTooltip then
		TextLabel.Text = FoundTooltip

		TextLabel.Visible = true
		ToolTip.Visible = true
	else
		TextLabel.Visible = false
		ToolTip.Visible = false
	end
end)

return UiCursor
