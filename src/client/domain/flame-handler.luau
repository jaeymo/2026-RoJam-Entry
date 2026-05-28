--!nocheck

--// Services //--
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local assetsFolder = ReplicatedStorage.assets

local AncestorUtil = require(ReplicatedStorage.shared.utils["find-first-ancestor-with-tag"])

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local Network = Jaegar:GetNetwork()

--// Typecheck //--
export type FlameProperties = {
	LifeTime: number?,
	FlammableStartup: number?,
	BurnTick: number?,
	DestroyOnBurn: boolean?,
	BurnoutCooldown: number?,
	BurnDamage: number?,
	FlameTransmission: number?,
	FlameVFX: Instance?,
	HitboxOverlapParams: OverlapParams?,
}

type InternalFlameProperties = {
	LifeTime: number,
	FlammableStartup: number,
	BurnTick: number,
	DestroyOnBurn: boolean,
	BurnoutCooldown: number,
	BurnDamage: number,
	FlameTransmission: number,
	FlameVFX: Instance?,
}

--// Variables //--
local Default_Properties: InternalFlameProperties = {
	LifeTime = 2,
	FlammableStartup = 0.25,
	BurnTick = 0.5,
	DestroyOnBurn = false,
	BurnoutCooldown = 5,
	BurnDamage = 5,
	FlameTransmission = 1,
	FlameVFX = nil,
	HitboxOverlapParams = OverlapParams.new(),
}

--// Main Code //--
local FlameHandler = {}

local ActiveFlames = {}
local BurningParts = {}
local BurnCooldowns = {}

local function ResolveProperties(Properties: FlameProperties?): InternalFlameProperties
	local NewProperties: InternalFlameProperties = table.clone(Default_Properties)

	if not Properties then
		return NewProperties
	end

	if Properties.LifeTime ~= nil then
		assert(typeof(Properties.LifeTime) == "number", "LifeTime must be a number")
		NewProperties.LifeTime = Properties.LifeTime
	end

	if Properties.FlammableStartup ~= nil then
		assert(typeof(Properties.FlammableStartup) == "number", "FlammableStartup must be a number")
		NewProperties.FlammableStartup = Properties.FlammableStartup
	end

	if Properties.BurnDamage ~= nil then
		assert(typeof(Properties.BurnDamage) == "number", "BurnDamage must be a number")
		NewProperties.BurnDamage = Properties.BurnDamage
	end

	if Properties.FlameTransmission ~= nil then
		assert(typeof(Properties.FlameTransmission) == "number", "FlameTransmission must be a number")
		assert(
			Properties.FlameTransmission >= 0 and Properties.FlameTransmission <= 1,
			"FlameTransmission must be between 0 and 1"
		)

		NewProperties.FlameTransmission = Properties.FlameTransmission
	end

	if Properties.FlameVFX ~= nil then
		assert(typeof(Properties.FlameVFX) == "Instance", "FlameVFX must be an Instance or a Folder")
		NewProperties.FlameVFX = Properties.FlameVFX
	end

	return NewProperties
end

local function CreateHitbox(Position: Vector3, Size: Vector3): Part
	local Hitbox = Instance.new("Part")
	Hitbox.Name = "FlameHitbox"

	Hitbox.CastShadow = false

	Hitbox.Anchored = true
	Hitbox.CanCollide = false
	Hitbox.CanQuery = false
	Hitbox.CanTouch = true

	Hitbox.Transparency = 0.8
	Hitbox.Color = Color3.fromRGB(255, 75, 0)

	Hitbox.Size = Size
	Hitbox.Position = Position

	Hitbox.Parent = workspace.runtime.hitboxes

	return Hitbox
end

function FlameHandler:DamageHumanoid(CharModel: Humanoid, Properties: FlameProperties)
	Network:SendServer("damageNPC", CharModel, 1)
end

function FlameHandler:Spawn(Position: Vector3, Size: Vector3, Properties: FlameProperties?, SourcePart: BasePart?)
	if typeof(Position) ~= "Vector3" or typeof(Size) ~= "Vector3" then
		warn("Position/Size need to be a Vector3")
		return
	end

	local FlamePropertiesResolved = ResolveProperties(Properties)

	if SourcePart then
		if BurningParts[SourcePart] then
			return
		end

		local Cooldown = BurnCooldowns[SourcePart]

		if Cooldown and Cooldown > tick() then
			return
		end

		BurningParts[SourcePart] = true
	end

	local visualModel
	if (Size).Magnitude > 13 then
		visualModel = ReplicatedStorage.assets.particles.BigFlames:Clone()
	else
		visualModel = ReplicatedStorage.assets.particles.SmallFlames:Clone()
	end
	local Hitbox = CreateHitbox(Position, Size)
	visualModel:PivotTo(CFrame.new(Position))
	visualModel.Parent = Hitbox

	task.spawn(function()
		for _, desc in pairs(Hitbox:GetDescendants()) do
			if desc:IsA("Light") then
				local initBrightness = desc.Brightness
				local initRange = desc.Range
				desc.Brightness = 0
				desc.Range = desc.Range * 0.95
				desc.Enabled = true
				TweenService:Create(
					desc,
					TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
					{ Brightness = initBrightness, Range = initRange }
				):Play()
			end
		end
	end)

	table.insert(ActiveFlames, {
		Hitbox = Hitbox,
		OverlapParams = Properties and Properties.HitboxOverlapParams or Default_Properties.HitboxOverlapParams,
		SourcePart = SourcePart,

		StartTime = tick(),
		LastBurnTick = 0,

		Properties = FlamePropertiesResolved,
	})

	--[[
	if FlamePropertiesResolved.FlameVFX then

	end]]

	return Hitbox
end

local UpdateRate = 0.25
local Accumulator = 0

RunService.PostSimulation:Connect(function(DeltaTime)
	Accumulator += DeltaTime

	if Accumulator < UpdateRate then
		return
	end

	Accumulator = 0

	local CurrentTime = tick()

	for Index = #ActiveFlames, 1, -1 do
		local Flame = ActiveFlames[Index]
		if not Flame then
			continue
		end

		local Elasped = tick() - Flame.StartTime

		if Elasped >= Flame.Properties.LifeTime then
			if Flame.SourcePart then
				BurningParts[Flame.SourcePart] = nil

				if Flame.Properties.DestroyOnBurn then
					Flame.SourcePart:Destroy()
				else
					BurnCooldowns[Flame.SourcePart] = CurrentTime + Flame.Properties.BurnoutCooldown
				end
			end

			task.spawn(function()
				for _, desc in pairs(Flame.Hitbox:GetDescendants()) do
					if desc:IsA("Light") then
						TweenService:Create(
							desc,
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
							{ Brightness = 0, Range = desc.Range * 0.8 }
						):Play()
					elseif desc:IsA("ParticleEmitter") then
						desc.Enabled = false
					elseif desc:IsA("Model") then
						desc.Parent = workspace.runtime
						Debris:AddItem(desc, 20)
					end
				end

				task.wait(0.6)

				Flame.Hitbox:Destroy()
			end)

			table.remove(ActiveFlames, Index)
			continue
		end

		if Elasped < Flame.Properties.FlammableStartup then
			continue
		end

		if CurrentTime - Flame.LastBurnTick < Flame.Properties.BurnTick then
			continue
		end

		local Parts = workspace:GetPartsInPart(Flame.Hitbox)

		for _, Part in Parts do
			if not Part:IsA("BasePart") then
				continue
			end

			local hitEntity = AncestorUtil(Part, "Entity") or AncestorUtil(Part, "Dead")

			if hitEntity and hitEntity:HasTag("Dead") then
				local clientEntity = hitEntity.Client
				local bodyAura = clientEntity.Torso:FindFirstChild("AuraBodyFlame")
					or assetsFolder.particles.AuraBodyFlame:Clone()
				local bodyFloat = clientEntity.Torso:FindFirstChild("FloatBodyFlame")
					or assetsFolder.particles.FloatBodyFlame:Clone()
				local bodySmoke = clientEntity.Torso:FindFirstChild("FloatBodySmoke")
					or assetsFolder.particles.FloatBodySmoke:Clone()

				bodyAura.Parent = clientEntity.Torso
				bodyFloat.Parent = clientEntity.Torso
				bodySmoke.Parent = clientEntity.Torso

				bodyAura.Enabled = true
				bodyFloat.Enabled = true
				bodySmoke.Enabled = true

				local flameLightPart = clientEntity.Torso:FindFirstChild("FlameLighting")
					or assetsFolder.FlameLighting:Clone()
				flameLightPart.Position = clientEntity.Torso.Position
				flameLightPart.WeldConstraint.Part1 = clientEntity.Torso
				flameLightPart.Parent = clientEntity.Torso

				for _, light in pairs(flameLightPart:GetDescendants()) do
					if not light:IsA("Light") then
						continue
					end

					light.Enabled = true
				end
				local bodyColor = clientEntity["Body Colors"]
				local h, s, v = bodyColor.HeadColor3:ToHSV()

				local num = 100
				for i = 1, num do
					local newV = math.lerp(v, 0, i / num)

					bodyColor.HeadColor3 = Color3.fromHSV(h, s, newV)
					bodyColor.TorsoColor3 = Color3.fromHSV(h, s, newV)
					bodyColor.RightArmColor3 = Color3.fromHSV(h, s, newV)
					bodyColor.LeftArmColor3 = Color3.fromHSV(h, s, newV)
					bodyColor.RightLegColor3 = Color3.fromHSV(h, s, newV)
					bodyColor.LeftLegColor3 = Color3.fromHSV(h, s, newV)
					task.wait()
				end
			end

			if hitEntity then
				FlameHandler:DamageHumanoid(hitEntity)
			end

			if not Part:HasTag("Flammable") then
				continue
			end

			if BurningParts[Part] then
				continue
			end

			local Cooldown = BurnCooldowns[Part]

			if Cooldown and Cooldown > CurrentTime then
				continue
			end

			local NewLifetime = Flame.Properties.LifeTime * Flame.Properties.FlameTransmission

			if NewLifetime <= 0 then
				continue
			end

			--// later we can do humanoid take damage or something here

			FlameHandler:Spawn(Part.Position, Part.Size, {
				LifeTime = Flame.Properties.LifeTime * Flame.Properties.FlameTransmission,

				FlammableStartup = Flame.Properties.FlammableStartup,
				BurnTick = Flame.Properties.BurnTick,

				DestroyOnBurn = Flame.Properties.DestroyOnBurn,
				BurnoutCooldown = Flame.Properties.BurnoutCooldown,

				BurnDamage = Flame.Properties.BurnDamage,

				FlameTransmission = Flame.Properties.FlameTransmission,
				FlameVFX = Flame.Properties.FlameVFX,
			}, Part)
		end
	end
end)

-- warn("RUNNING FLAME COMP")
-- if RunService:IsClient() then
-- 	local LocalPlayer = Players.LocalPlayer
-- 	local Mouse = LocalPlayer:GetMouse()

-- 	UserInputService.InputBegan:Connect(function(Input: InputObject, GPE: boolean)
-- 		if GPE then
-- 			return
-- 		end

-- 		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
-- 			FlameHandler:Spawn(Mouse.Hit.Position, Vector3.new(12, 6, 12), {
-- 				LifeTime = 2,
-- 				FlammableStartup = 0.25,
-- 				BurnDamage = 5,
-- 				FlameTransmission = 1,
-- 				DestroyOnBurn = false,
-- 				BurnoutCooldown = 2,
-- 			})
-- 		end
-- 	end)
-- end

return FlameHandler
