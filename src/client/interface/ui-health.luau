--// Services //--
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Modules //--
local Viewer = require(ReplicatedStorage.packages.viewer)

local camShaker = require(ReplicatedStorage.client.controllers["camera-controller"]).shaker

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")
local vignette = Main:WaitForChild("WavyVignette") :: ImageLabel

local Health = Main:WaitForChild("Health") :: Frame
local Bar = Health:WaitForChild("Bar") :: Frame
local Title = Health:WaitForChild("Title") :: TextLabel

local BacteriaGui = Health:WaitForChild("Bacteria")
local guiFill = Health:WaitForChild("Fill")
local blackFill = Health:WaitForChild("BlackFill")

local OuterFrame = Health:WaitForChild("OuterFrame")
local WingsFill = OuterFrame:WaitForChild("wings-fill")
local bgFill = OuterFrame:WaitForChild("bg-fill")
local foreFill = OuterFrame:WaitForChild("foreground-fill")

local title = Health:WaitForChild("Title")

local Character = Player.Character or Player.CharacterAdded:Wait()

local CurrentHealth = Character:GetAttribute("Health") or 100
local MaxHealth = Character:GetAttribute("MaxHealth") or 100

local OriginalBarColor = Bar.BackgroundColor3
local CurrentBarColor = OriginalBarColor
local CurrentBarColorName = "None"

local HealthTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PulseTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local FlowerConfig = require(ReplicatedStorage.shared.configs["flower-config"])

--// Main Code //--
local UiHealth = {}
local bacteriaGuis = {}

local updHealthThread
local previousMidPoint

local function UpdateHealth()
	local HealthPercent = math.clamp(CurrentHealth / 100, 0, 1)
	local MaxHealthPercent = math.clamp(MaxHealth / 100, 0, 1)

	local BarSize = Bar.Size
	local HealthSize = Health.Size

	local midPointOffset = 0.1

	if not previousMidPoint then
		previousMidPoint = HealthPercent - midPointOffset
	end

	if updHealthThread then
		task.cancel(updHealthThread)
		updHealthThread = nil
		previousMidPoint = HealthPercent
	end

	updHealthThread = task.spawn(function()
		local startTick = os.clock()
		while task.wait() do
			local elapsedTick = os.clock() - startTick
			local t = elapsedTick / HealthTweenInfo.Time
			if elapsedTick >= HealthTweenInfo.Time then
				return
			end

			blackFill.UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(
					math.clamp(math.lerp(previousMidPoint - 0.2, HealthPercent - 0.2, t), 0.01, HealthPercent),
					1
				),
				NumberSequenceKeypoint.new(
					math.clamp(math.lerp(previousMidPoint, HealthPercent, t), 0.1, HealthPercent),
					0.1
				),
				NumberSequenceKeypoint.new(1, 0.1),
			})
		end
		previousMidPoint = HealthPercent

		updHealthThread = nil
	end)

	-- TweenService:Create(Health, HealthTweenInfo, {
	-- 	Size = UDim2.new(0.218 * MaxHealthPercent, 0, HealthSize.Y.Scale, HealthSize.Y.Offset),
	-- }):Play()
end

local beatingConnection
local function StartBeatingPulse()
	local beatTime = 1
	local startTick = os.clock()
	local beatTweenPlaying = false

	beatingConnection = RunService.PostSimulation:Connect(function()
		local elaspedTick = os.clock() - startTick

		if beatTweenPlaying then
			return
		end

		if elaspedTick >= beatTime then
			startTick = os.clock()
			local tween = TweenService:Create(
				vignette,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 1, true),
				{ ImageTransparency = math.clamp(vignette.ImageTransparency - 0.25, 0, 1) }
			)
			tween:Play()
			beatTweenPlaying = true
			tween.Completed:Once(function()
				beatTweenPlaying = false
			end)
		end
		vignette.ImageColor3 = CurrentBarColor
		vignette.ImageTransparency = CurrentHealth / 100
	end)
end

local function HideHealth()
	for _, desc in pairs(Health:GetDescendants()) do
		if not desc:HasTag("VisibleHealthGui") then
			continue
		end

		if desc:IsA("UIStroke") then
			TweenService
				:Create(
					desc,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Transparency = 1 }
				)
				:Play()
		elseif desc:IsA("ImageLabel") then
			TweenService:Create(
				desc,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ ImageTransparency = 1 }
			):Play()
		elseif desc:IsA("TextLabel") then
			TweenService:Create(
				desc,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ TextTransparency = 1 }
			):Play()
		elseif desc:IsA("Frame") then
			TweenService:Create(
				desc,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundTransparency = 1 }
			):Play()
		end
	end
	TweenService:Create(
		Health,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ BackgroundTransparency = 1 }
	):Play()
end

local function ShowHealth()
	for _, desc in pairs(Health:GetDescendants()) do
		if not desc:HasTag("VisibleHealthGui") then
			continue
		end

		if desc:IsA("UIStroke") then
			TweenService
				:Create(
					desc,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Transparency = 0 }
				)
				:Play()
		elseif desc:IsA("ImageLabel") then
			TweenService:Create(
				desc,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ ImageTransparency = 0 }
			):Play()
		elseif desc:IsA("TextLabel") then
			TweenService:Create(
				desc,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ TextTransparency = 0 }
			):Play()
		elseif desc:IsA("Frame") then
			TweenService:Create(
				desc,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ BackgroundTransparency = 0 }
			):Play()
		end
	end
	TweenService:Create(
		Health,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ BackgroundTransparency = 0 }
	):Play()
end

local maxBacterias = 8

local imgs = {
	"rbxassetid://121997832559585",
	"rbxassetid://78639237051978",
	"rbxassetid://117278176970725",
}

local function SpawnBacteria(index: number)
	local GuiColors = FlowerConfig.GuiColors[CurrentBarColorName]
	local newBacteria = BacteriaGui:Clone() :: ImageLabel
	newBacteria.Visible = true

	local randomSize = math.random(15, 22)
	newBacteria.Size = UDim2.fromOffset(randomSize, randomSize)

	newBacteria.Rotation = math.random(-180, 180)
	newBacteria.Position = UDim2.fromScale((index - 1) / maxBacterias, math.random(0, 30) / 100)
	newBacteria.ImageColor3 = GuiColors.Tertiary

	bacteriaGuis[#bacteriaGuis + 1] = {
		Instance = newBacteria,
		Thread = task.spawn(function()
			local num = 1
			local frameStart = os.clock()
			local framRate = 0.25
			local tweenPlaying = false
			local tweenComplete = false
			local tween =
				TweenService:Create(newBacteria, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					ImageTransparency = 1,
				})

			newBacteria.ImageTransparency = 1
			TweenService:Create(newBacteria, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				ImageTransparency = 0,
			}):Play()
			while task.wait() do
				local elapsedFrameTime = os.clock() - frameStart
				if elapsedFrameTime >= framRate then
					newBacteria.Image = imgs[num]
					num += 1
					frameStart = os.clock()
					if num > 3 then
						num = 1
					end
				end

				newBacteria.Position =
					UDim2.fromScale(newBacteria.Position.X.Scale + 0.0005, newBacteria.Position.Y.Scale)
				newBacteria.Rotation += 0.5

				if newBacteria.Position.X.Scale >= 0.875 then
					if tweenComplete then
						return
					end
					if tweenPlaying then
						continue
					end

					tween:Play()

					tween.Completed:Once(function()
						if not newBacteria.Parent then
							return
						end
						tweenComplete = true
						newBacteria:Destroy()
						SpawnBacteria(1)
					end)
				end
			end
		end),
	}
	newBacteria.Parent = Health
end

local function StartInfection()
	ReplicatedStorage.assets.sounds.hurt:Play()
	ReplicatedStorage.assets.sounds.sludge:Play()
	for _, v in pairs(bacteriaGuis) do
		v.Instance:Destroy()
		task.cancel(v.Thread)
	end

	ShowHealth()
	for i = 1, maxBacterias do
		SpawnBacteria(i)
	end

	local GuiColors = FlowerConfig.GuiColors[CurrentBarColorName]

	camShaker:Shake(camShaker.Presets.Explosion)

	local tween = TweenService:Create(
		Lighting.ColorCorrection,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ TintColor = GuiColors.Primary:Lerp(Color3.fromRGB(255, 255, 255), 0.3) }
	)

	local fov = workspace.CurrentCamera.FieldOfView

	TweenService:Create(
		workspace.CurrentCamera,
		TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
		{ FieldOfView = fov * 0.65 }
	):Play()

	tween:Play()

	tween.Completed:Once(function()
		TweenService:Create(
			Lighting.ColorCorrection,
			TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			{ TintColor = Color3.fromRGB(255, 255, 255) }
		):Play()
		TweenService:Create(
			workspace.CurrentCamera,
			TweenInfo.new(1.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			{ FieldOfView = fov }
		):Play()
	end)

	foreFill.ImageColor3 = GuiColors.Secondary
	WingsFill.ImageColor3 = GuiColors.Secondary
	bgFill.ImageColor3 = GuiColors.Secondary

	guiFill.BackgroundColor3 = GuiColors.Primary
	title.TextColor3 = GuiColors.Primary
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

Viewer.WatchAttribute(Players.LocalPlayer, "Infected", function(color: Color3?)
	local chosenColor

	for colorName, v in FlowerConfig.colors do
		if v == color then
			chosenColor = colorName
			break
		end
	end

	if chosenColor then
		local text = FlowerConfig.diseaseNames[chosenColor]
		Title.Text = text
	end
end)

Viewer.WatchAttribute(Character, "MaxHealth", function(NewValue)
	MaxHealth = tonumber(NewValue) or 100

	UpdateHealth()
end)

Viewer.WatchAttribute(Player, "Infected", function(Value)
	if Value then
		CurrentBarColor = Value
		for name, val in pairs(FlowerConfig.colors) do
			if val == Value then
				CurrentBarColorName = name
			end
		end
		StartInfection()
		StartBeatingPulse()

		TweenService:Create(
			Bar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Value }
		):Play()
	else
		HideHealth()
		for _, v in pairs(bacteriaGuis) do
			v.Instance:Destroy()
			task.cancel(v.Thread)
		end

		CurrentBarColor = OriginalBarColor

		TweenService:Create(
			Bar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundColor3 = OriginalBarColor }
		):Play()
	end
end)

UpdateHealth()
HideHealth()
-- StartInfection()

return UiHealth
