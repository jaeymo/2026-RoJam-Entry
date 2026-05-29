--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Viewer = require(ReplicatedStorage.packages.viewer)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
local main = playerGui:WaitForChild("ui-assets"):WaitForChild("Main") :: ScreenGui
local fireChargeImage = main:WaitForChild("FireImage") :: ImageLabel
local fireChargeText = main:WaitForChild("FireCharge") :: TextLabel
local sandChargeImage = main:WaitForChild("SandImage") :: ImageLabel
local sandChargeText = main:WaitForChild("SandCharge") :: TextLabel

local UiCharge = {}

export type UiCharge = typeof(UiCharge)

function UiCharge.jaegarInit()
	fireChargeText.Visible = false
	fireChargeImage.Visible = false
	sandChargeImage.Visible = false
	sandChargeText.Visible = false

	ReplicatedStorage["global-data"].currentWeaponName.Changed:Connect(function()
		if ReplicatedStorage["global-data"].currentWeaponName.Value == "FlintAndSteel" then
			fireChargeText.Visible = true
			fireChargeImage.Visible = true
			sandChargeImage.Visible = true
			sandChargeText.Visible = true
		else
			fireChargeText.Visible = false
			fireChargeImage.Visible = false
			sandChargeImage.Visible = false
			sandChargeText.Visible = false
		end
	end)

	Viewer.WatchAttribute(Players.LocalPlayer, "FireCharge", function(charge: number)
		fireChargeText.Text = tostring(charge)
	end)

	Viewer.WatchAttribute(Players.LocalPlayer, "SandCharge", function(charge: number)
		sandChargeText.Text = tostring(charge)
	end)
end

return UiCharge
