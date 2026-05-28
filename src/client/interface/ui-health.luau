--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Modules //--
local Viewer = require(ReplicatedStorage.packages.viewer)

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local Health = Main:WaitForChild("Health") :: Frame
local Bar = Health:WaitForChild("Bar") :: Frame
local Title = Health:WaitForChild("Title") :: Frame

local BacteriaGui = Health:WaitForChild("Bacteria")
local guiFill = Health:WaitForChild("Fill")

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

local function UpdateHealth()
	local HealthPercent = math.clamp(CurrentHealth / MaxHealth, 0, 1)
	local MaxHealthPercent = math.clamp(MaxHealth / 100, 0, 1)

	local BarSize = Bar.Size
	local HealthSize = Health.Size

	TweenService:Create(Bar, HealthTweenInfo, {
		Size = UDim2.new(HealthPercent, 0, BarSize.Y.Scale, BarSize.Y.Offset),
	}):Play()

	TweenService:Create(Health, HealthTweenInfo, {
		Size = UDim2.new(0.218 * MaxHealthPercent, 0, HealthSize.Y.Scale, HealthSize.Y.Offset),
	}):Play()
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
	for _, v in pairs(bacteriaGuis) do
		v.Instance:Destroy()
		task.cancel(v.Thread)
	end

	ShowHealth()
	for i = 1, maxBacterias do
		SpawnBacteria(i)
	end

	local GuiColors = FlowerConfig.GuiColors[CurrentBarColorName]

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
