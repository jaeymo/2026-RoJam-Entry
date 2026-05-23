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

local StaminaBar = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main"):WaitForChild("SprintBar")

local Tween

local Sprinting = false
local RegenDebounce = false

local MaxStamina = 100
local CurrentStamina = MaxStamina

local SprintSpeed = 20
local WalkSpeed = 16

local DrainRate = 20
local RegenRate = 15

--// Main Code //--
local SprintController = {}

local function TweenSprintBar(Transparency: number, Time: number)
	if Tween then
		Tween:Cancel()
		Tween = nil
	end

	Tween = TweenService:Create(
		StaminaBar,
		TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = Transparency }
	)

	Tween:Play()
end

local function UpdateBar()
	local Ratio = math.clamp(CurrentStamina / MaxStamina, 0, 1)
	StaminaBar.Size = UDim2.fromScale(Ratio, StaminaBar.Size.Y.Scale)
	StaminaBar.Position = UDim2.new(0.5 - (Ratio / 2), 0, StaminaBar.Position.Y.Scale, 0)
end

local function SetSprint(State: boolean)
	local Humanoid = CharacterState:getHumanoid()
	if not Humanoid then
		return
	end

	if State then
		if CurrentStamina <= 0 then
			return
		end

		local RootPart = CharacterState:getRoot()
		local MoveDirection = CharacterState:getMoveDirection()

		if not RootPart or MoveDirection.Magnitude <= 0 then
			return
		end

		local Forward = RootPart.CFrame.LookVector:Dot(MoveDirection.Unit)

		if Forward <= 0 then
			return
		end
	end

	if Sprinting == State then
		return
	end

	Sprinting = State

	Humanoid.WalkSpeed = State and SprintSpeed or WalkSpeed

	if State then
		TweenSprintBar(0, 0.25)
	else
		TweenSprintBar(1, 1)
	end
end

local function HandleRegen()
	if RegenDebounce then
		return
	end

	RegenDebounce = true

	task.delay(1, function()
		while not Sprinting and CurrentStamina < MaxStamina do
			CurrentStamina = math.min(MaxStamina, CurrentStamina + (RegenRate * task.wait()))

			UpdateBar()
		end

		RegenDebounce = false
	end)
end

UserInputService.InputBegan:Connect(function(Input: InputObject, GPE: boolean)
	if not GPE then
		warn("GPE")
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

	local RootPart = CharacterState:getRoot()
	local MoveDirection = CharacterState:getMoveDirection()

	if not RootPart or MoveDirection.Magnitude <= 0 then
		SetSprint(false)

		HandleRegen()

		return
	end

	local Forward = RootPart.CFrame.LookVector:Dot(MoveDirection.Unit)

	if Forward <= 0 then
		SetSprint(false)

		HandleRegen()

		return
	end

	CurrentStamina -= DrainRate * DeltaTime
	CurrentStamina = math.max(0, CurrentStamina)

	if Player then
		Player:SetAttribute("Stamina", CurrentStamina)
	end

	UpdateBar()

	if CurrentStamina <= 0 then
		SetSprint(false)

		HandleRegen()
	end
end)

UpdateBar()

return SprintController
