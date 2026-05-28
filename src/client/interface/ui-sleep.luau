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

local Continue = SleepFrame:WaitForChild("Continue") :: TextButton
local Leave = SleepFrame:WaitForChild("Leave") :: TextButton

--// Main Code //--
local UiSleep = {}

local function Tween(Object: Instance, Time: number, Properties: {})
	local TweenObject =
		TweenService:Create(Object, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Properties)

	TweenObject:Play()

	return TweenObject
end

local function SetupHover(Button: TextButton)
	local Hover = Button:FindFirstChild("Hover")

	Button.MouseEnter:Connect(function()
		if Button.TextTransparency > 0 then
			return
		end

		Tween(Button, 0.2, {
			TextColor3 = Color3.fromRGB(200, 0, 0),
		})

		if Hover then
			Hover.Visible = true
		end
	end)

	Button.MouseLeave:Connect(function()
		Tween(Button, 0.2, {
			TextColor3 = Color3.fromRGB(255, 255, 255),
		})

		if Hover then
			Hover.Visible = false
		end
	end)
end

local function TweenOut()
	Continue.Modal = false
	ReplicatedStorage["global-data"].isSleeping.Value = false
	Player.CameraMode = Enum.CameraMode.LockFirstPerson

	Tween(SleepFrame, 2, { BackgroundTransparency = 1 })
	Tween(TextLabel, 1, { TextTransparency = 1 })
	Tween(CurrentDay, 1, { TextTransparency = 1 })
	Tween(NewDay, 1, { TextTransparency = 1 })
	Tween(Continue, 1, { TextTransparency = 1 })
	Tween(Leave, 1, { TextTransparency = 1 })
end

local function Sleep(OldDay: number)
	ReplicatedStorage["global-data"].isSleeping.Value = true
	SleepFrame.Visible = true
	SleepFrame.BackgroundTransparency = 1

	TextLabel.TextTransparency = 1

	CurrentDay.TextTransparency = 1
	NewDay.TextTransparency = 1

	Continue.TextTransparency = 1
	Leave.TextTransparency = 1

	CurrentDay.Position = UDim2.fromScale(0.576, 0.5)
	NewDay.Position = UDim2.fromScale(0.576, 0.432)

	if OldDay > 1 then
		TextLabel.Text = "Days:"
	end

	CurrentDay.Text = tostring(OldDay)
	NewDay.Text = tostring(OldDay + 1)

	UserInputService.MouseIconEnabled = false
	Continue.Modal = true

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

	Tween(CurrentDay, 1, { Position = UDim2.fromScale(0.576, 0.576), TextTransparency = 1 })

	local NewTween = Tween(NewDay, 1, { Position = UDim2.fromScale(0.576, 0.5), TextTransparency = 0 })
	NewTween.Completed:Wait()

	if OldDay < 10 then
		Leave.Visible = false
		Leave.Active = false
		Leave.AutoButtonColor = false

		Continue.Position = UDim2.fromScale(0.485, 0.625)

		Tween(Continue, 0.5, {
			TextTransparency = 0,
		})
	else
		Leave.Visible = true
		Leave.Active = true
		Leave.AutoButtonColor = true

		Continue.Position = UDim2.fromScale(0.33, 0.625)

		Tween(Continue, 0.5, {
			TextTransparency = 0,
		})

		Tween(Leave, 0.5, {
			TextTransparency = 0,
		})
	end
end

function UiSleep.jaegarInit()
	SetupHover(Continue)
	SetupHover(Leave)

	Continue.MouseButton1Click:Connect(function()
		TweenOut()
	end)

	Leave.MouseButton1Click:Connect(function()
		TweenOut()
	end)

	Network:OnClient("playerSlept", function(CurrentDayNumber)
		Sleep(CurrentDayNumber)
	end)
end

return UiSleep
