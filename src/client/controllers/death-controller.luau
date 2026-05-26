--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Modules //--
local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])
local Viewer = require(ReplicatedStorage.packages.viewer)

--// Variables //--
local Player = Players.LocalPlayer

local PlayerGui = Player.PlayerGui

local DeathFrame: CanvasGroup = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main"):WaitForChild("Death")

local YouHave = DeathFrame:WaitForChild("YouHave")
local Died = DeathFrame:WaitForChild("Died")

local Retry = DeathFrame:WaitForChild("Retry")
local Return = DeathFrame:WaitForChild("Return")

local Sounds = DeathFrame:WaitForChild("Sounds")

local TweenInfoFast = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoHover = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

--// Main Code //--
local DeathController = {}

DeathFrame.GroupTransparency = 1

YouHave.Position = UDim2.fromScale(0.442, 0.47)
YouHave.TextTransparency = 1

Died.Position = UDim2.fromScale(0.602, 0.47)
Died.TextTransparency = 1

Retry.Position = UDim2.fromScale(0.38, 0.625)
Retry.TextTransparency = 1

Return.Position = UDim2.fromScale(0.62, 0.625)
Return.TextTransparency = 1

local function Tween(Object, Properties, Info)
	return TweenService:Create(Object, Info or TweenInfoFast, Properties)
end

local function SetupHover(Button: TextButton)
	local Hover = Button:FindFirstChild("Hover")

	Button.MouseEnter:Connect(function()
		Tween(Button, { TextColor3 = Color3.fromRGB(220, 0, 0) }, TweenInfoHover):Play()

		if Hover then
			Hover.Visible = true
		end

		Sounds.Select:Play()
	end)

	Button.MouseLeave:Connect(function()
		Tween(Button, { TextColor3 = Color3.fromRGB(255, 255, 255) }, TweenInfoHover):Play()

		if Hover then
			Hover.Visible = false
		end
	end)
end

local function handleDeath()
	Player.CameraMode = Enum.CameraMode.Classic

	Tween(DeathFrame, {
		GroupTransparency = 0,
	}, TweenInfo.new(2)):Play()

	task.wait(1.5)

	local YouHaveTween = Tween(YouHave, {
		Position = UDim2.fromScale(0.442, 0.5),
		TextTransparency = 0,
	})

	YouHaveTween:Play()
	YouHaveTween.Completed:Wait()

	Died.Position = UDim2.fromScale(0.602, 0.5)

	task.spawn(function()
		local Amplitude = 5
		local Frequency = 70
		local OriginalPosition = Died.Position

		while
			CharacterState:getCharacter()
			and ((CharacterState:getCharacter() :: Model):GetAttribute("Health") :: number) <= 0
		do
			local xOffset = math.sin(tick() * Frequency) * Amplitude
			local yOffset = math.sin(tick() * Frequency * 1.3) * Amplitude

			Died.Position = UDim2.new(
				OriginalPosition.X.Scale,
				OriginalPosition.X.Offset + xOffset,
				OriginalPosition.Y.Scale,
				OriginalPosition.Y.Offset + yOffset
			)

			task.wait(0.01)
		end
	end)

	local DiedTween = Tween(Died, {
		TextTransparency = 0,
	})

	DiedTween:Play()
	DiedTween.Completed:Wait()

	task.wait(1)

	local ReturnTween = Tween(Return, {
		Position = UDim2.fromScale(0.6, 0.625),
		TextTransparency = 0,
	})

	local RetryTween = Tween(Retry, {
		Position = UDim2.fromScale(0.4, 0.625),
		TextTransparency = 0,
	})

	ReturnTween:Play()
	RetryTween:Play()

	SetupHover(Return)
	SetupHover(Retry)
end

function DeathController.jaegarInit(self: typeof(DeathController))
	repeat
		task.wait()
	until CharacterState:getCharacter()

	Viewer.WatchAttribute(CharacterState:getCharacter() :: Model, "Health", function(health: number)
		if health <= 0 then
			handleDeath()
		end
	end)
end

return DeathController
