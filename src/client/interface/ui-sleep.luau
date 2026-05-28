--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Modules //--
local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local Network = Jaegar:GetNetwork()

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local SleepFrame = Main:WaitForChild("Sleep") :: Frame

local TextLabel = SleepFrame:WaitForChild("TextLabel") :: TextLabel
local NewDay = SleepFrame:WaitForChild("NewDay") :: TextLabel
local CurrentDay = SleepFrame:WaitForChild("OldDay") :: TextLabel

--// Main Code //--
local UiSleep = {}

local function Tween(Object: Instance, Time: number, Properties: {})
	local TweenObject =
		TweenService:Create(Object, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Properties)

	TweenObject:Play()

	return TweenObject
end

local function TweenOut()
	ReplicatedStorage["global-data"].isSleeping.Value = false
	Player.CameraMode = Enum.CameraMode.LockFirstPerson

	Tween(SleepFrame, 2, { BackgroundTransparency = 1 })
	Tween(TextLabel, 1, { TextTransparency = 1 })
	Tween(CurrentDay, 1, { TextTransparency = 1 })
	Tween(NewDay, 1, { TextTransparency = 1 })
end

local function Sleep(OldDay: number)
	ReplicatedStorage["global-data"].isSleeping.Value = true
	SleepFrame.Visible = true
	SleepFrame.BackgroundTransparency = 1

	TextLabel.TextTransparency = 1

	CurrentDay.TextTransparency = 1
	NewDay.TextTransparency = 1

	CurrentDay.Position = UDim2.fromScale(0.599, 0.5)
	NewDay.Position = UDim2.fromScale(0.599, 0.432)

	if OldDay > 1 then
		TextLabel.Text = "Days:"
	end

	CurrentDay.Text = tostring(OldDay)
	NewDay.Text = tostring(OldDay + 1)

	UserInputService.MouseIconEnabled = false

	local Black = Tween(SleepFrame, 2, { BackgroundTransparency = 0 })
	Black.Completed:Wait()

	Player.CameraMode = Enum.CameraMode.Classic
	UserInputService.MouseIconEnabled = true

	Network:SendServer("playerSlept")

	task.wait(0.5)

	Tween(TextLabel, 0.5, { TextTransparency = 0 })
	local CurrentDayTween = Tween(CurrentDay, 0.5, { TextTransparency = 0 })
	CurrentDayTween.Completed:Wait()

	task.wait(0.5)

	Tween(CurrentDay, 1, { Position = UDim2.fromScale(0.599, 0.576), TextTransparency = 1 })

	local NewTween = Tween(NewDay, 1, { Position = UDim2.fromScale(0.599, 0.5), TextTransparency = 0 })
	NewTween.Completed:Wait()

	task.wait(0.5)

	TweenOut()
end

function UiSleep.jaegarInit()
	Network:OnClient("playerSlept", function(CurrentDayNumber)
		Sleep(CurrentDayNumber)
	end)
end

return UiSleep
