--!nocheck

--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Modules //--
local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])

--// Variables //--
local Player = Players.LocalPlayer

local PlayerGui = Player.PlayerGui
local Camera = workspace.CurrentCamera

local StaminaBar = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main"):WaitForChild("SprintBar")

local SprintBarTween
local FovTween

local Sprinting = false
local RegenDebounce = false

--// Config //--
local MAX_STAMINA = 100
local SPRINT_SPEED = 28
local WALK_SPEED = 16

local DRAIN_RATE = 20
local REGEN_RATE = 15

local BASE_FOV = 80
local SPRINT_FOV = 85
local FOV_TWEEN_TIME = 0.2

--// Runtime //--
local CurrentStamina = MAX_STAMINA

--// Main Code //--
local SprintController = {}

local function tweenFov(TargetFov: number)
	if not Camera then
		return
	end

	if FovTween then
		FovTween:Cancel()
		FovTween = nil
	end

	FovTween =
		TweenService:Create(Camera, TweenInfo.new(FOV_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			FieldOfView = TargetFov,
		})

	FovTween:Play()
end

local function TweenSprintBar(Transparency: number, Time: number)
	if SprintBarTween then
		SprintBarTween:Cancel()
		SprintBarTween = nil
	end

	SprintBarTween =
		TweenService:Create(StaminaBar, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = Transparency,
		})

	SprintBarTween:Play()
end

local function UpdateBar()
	local Ratio = math.clamp(CurrentStamina / MAX_STAMINA, 0, 1)

	StaminaBar.Size = UDim2.fromScale(Ratio, StaminaBar.Size.Y.Scale)

	StaminaBar.Position = UDim2.new(0.5 - (Ratio / 2), 0, StaminaBar.Position.Y.Scale, 0)
end

local function SetSprint(State: boolean)
	local Humanoid = CharacterState:getHumanoid()

	if not Humanoid then
		return
	end

	if State and CurrentStamina <= 0 then
		return
	end

	if Sprinting == State then
		return
	end

	Sprinting = State

	ReplicatedStorage["global-data"].isSprinting.Value = State

	Humanoid.WalkSpeed = State and SPRINT_SPEED or WALK_SPEED

	if State then
		TweenSprintBar(0, 0.25)
		tweenFov(SPRINT_FOV)
	else
		TweenSprintBar(1, 1)
		tweenFov(BASE_FOV)
	end
end

local function HandleRegen()
	if RegenDebounce then
		return
	end

	RegenDebounce = true

	task.delay(1, function()
		while not Sprinting and CurrentStamina < MAX_STAMINA do
			CurrentStamina = math.min(MAX_STAMINA, CurrentStamina + (REGEN_RATE * task.wait()))

			UpdateBar()
		end

		RegenDebounce = false
	end)
end

UserInputService.InputBegan:Connect(function(Input: InputObject, GPE: boolean)
	if GPE then
		return
	end

	if Input.KeyCode == Enum.KeyCode.LeftShift and CharacterState:getSpeed() > 0.01 then
		SetSprint(true)
	end
end)

UserInputService.InputEnded:Connect(function(Input: InputObject)
	if Input.KeyCode == Enum.KeyCode.LeftShift then
		SetSprint(false)

		HandleRegen()
	end
end)

RunService.PreRender:Connect(function(DeltaTime: number)
	if not Sprinting then
		return
	end

	CurrentStamina -= DRAIN_RATE * DeltaTime
	CurrentStamina = math.max(0, CurrentStamina)

	Player:SetAttribute("Stamina", CurrentStamina)

	UpdateBar()

	if CurrentStamina <= 0 then
		SetSprint(false)

		HandleRegen()
	end
end)

Camera.FieldOfView = BASE_FOV

UpdateBar()

return SprintController
