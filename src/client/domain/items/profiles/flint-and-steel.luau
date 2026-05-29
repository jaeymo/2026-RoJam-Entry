--!strict
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local charState = require(ReplicatedStorage.client.domain.character["character-state"])
local flameConnector = require(ReplicatedStorage.client.domain["flame-handler"])
local raydar = require(ReplicatedStorage.shared.utils.raydar)

local ViewmodelController
local HitboxController

local player = Players.LocalPlayer
local network = Jaegar:GetNetwork()

local FlintAndSteel = {
	onCooldown = false,
	secondaryCooldown = false,
}

export type FlintAndSteel = typeof(FlintAndSteel)

local flag = false

function FlintAndSteel.equip(self: FlintAndSteel)
	flag = true

	ViewmodelController.animationObject:StopAll()
	ViewmodelController.animationObject:Play("ViewModelFNSIdle")
	ViewmodelController:getViewmodel():setArmVisible("left")

	task.delay(0.2, function()
		if flag then
			ViewmodelController:getViewmodel():setArmVisible("left")
		end
	end)
end

function FlintAndSteel.unequip(self: FlintAndSteel)
	flag = false
	ViewmodelController.animationObject:StopAll()
end

local hitFlammable: BasePart? = nil

function FlintAndSteel.primary(self: FlintAndSteel)
	if self.onCooldown or self.secondaryCooldown then
		return
	end

	local isFreeOfCharge = false

	if not hitFlammable then
		local fireCharges = player:GetAttribute("FireCharge") :: number
		if fireCharges <= 0 then
			print("hell nah")
			ViewmodelController.animationObject:Play("ViewModelFNSSpark")
			return
		end
	else
		isFreeOfCharge = true
		print("FREE OF CHARGE!")
	end

	self.onCooldown = true

	if not isFreeOfCharge then
		network:SendServer("useCharge", "FireCharge")
	end

	ReplicatedStorage["global-data"].canSwitchToNewItem.Value = false

	task.delay(0.6, function()
		ReplicatedStorage["global-data"].canSwitchToNewItem.Value = true
	end)
	task.delay(0.8, function()
		self.onCooldown = false
	end)

	ViewmodelController.animationObject:Play("ViewModelFNSSpark")
	ViewmodelController.animationObject:GetTrack("ViewModelFNSSpark"):GetMarkerReachedSignal("hit"):Wait()

	ViewmodelController:getViewmodel():setArmVisible("left")
	local forwardDist = 10
	local downwardDist = 6

	local forwardResult = raydar:Fire(
		charState:getRoot().Position,
		charState:getFacingDirection(),
		forwardDist,
		raydar.RayTypes.AimForEntities,
		charState:getCharacter()
	)

	if forwardResult then
		flameConnector:Spawn(forwardResult.Position, Vector3.one * 6)
		return
	end

	local downwardResult = raydar:Fire(
		charState:getRoot().Position + charState:getFacingDirection() * forwardDist,
		Vector3.yAxis * -1,
		downwardDist,
		raydar.RayTypes.AimForEntities,
		charState:getCharacter()
	)

	if downwardResult then
		flameConnector:Spawn(downwardResult.Position, Vector3.one * 6, { DestroyOnBurn = true })
		ViewmodelController:getViewmodel():setArmVisible("left")
		return
	end
end

function FlintAndSteel.secondary(self: FlintAndSteel)
	if self.secondaryCooldown or self.onCooldown then
		return
	end

	local sandCharges = player:GetAttribute("SandCharge") :: number
	if sandCharges <= 0 then
		print("hell nah")
		return
	end

	network:SendServer("useCharge", "SandCharge")
	self.secondaryCooldown = true
	ReplicatedStorage["global-data"].canSwitchToNewItem.Value = false

	task.delay(1, function()
		self.secondaryCooldown = false
		ReplicatedStorage["global-data"].canSwitchToNewItem.Value = true
	end)

	ViewmodelController.animationObject:Stop("ViewModelFNSSpark")
	ViewmodelController.animationObject:Play("ViewModelSandThrow")
	ViewmodelController.animationObject:GetTrack("ViewModelSandThrow"):GetMarkerReachedSignal("hit"):Wait()

	ViewmodelController:getViewmodel():setArmVisible("left")

	for i = 1, 4 do
		local dir = charState:getFacingDirection()
		local pos = charState:getRoot().Position + dir * (4 * i)

		local result = raydar:Fire(
			pos + Vector3.yAxis * 5,
			(Vector3.yAxis * -1) + (dir / 1.5),
			60,
			raydar.RayTypes.HitWalls,
			charState:getCharacter()
		)

		pos = result and result.Position + Vector3.yAxis * 2 or pos

		local flammableHitbox = flameConnector:SpawnFlammable(pos, Vector3.one * 5.5)
		flammableHitbox.Transparency = 1

		local sandVessel = Instance.new("Part")
		sandVessel.CanCollide = false
		sandVessel.CanQuery = false
		sandVessel.CanTouch = false
		sandVessel.Transparency = 1
		sandVessel.Anchored = true
		sandVessel.Size = Vector3.one * 3
		sandVessel.Position = flammableHitbox.Position + Vector3.yAxis * 2
		sandVessel.Parent = workspace.runtime

		local sandSparkle = ReplicatedStorage.assets.particles.SandSparkle:Clone()
		local sandDust = ReplicatedStorage.assets.particles.SandDust:Clone()
		local flyingSandSparkle = ReplicatedStorage.assets.particles.FlyingSandSparkle:Clone()
		local flyingSandDust = ReplicatedStorage.assets.particles.FlyingSandDust:Clone()
		local sandSpawn = ReplicatedStorage.assets.particles.SandSpawn:Clone()

		flammableHitbox:GetAttributeChangedSignal("HasBurned"):Once(function()
			local boom = ReplicatedStorage.assets.particles.BOOM:Clone()
			boom.Parent = sandVessel

			sandDust.Enabled = false
			sandSparkle.Enabled = false

			task.spawn(function()
				for _ = 1, 3 do
					boom:Emit(5)
					sandSparkle:Destroy()
					sandDust:Destroy()
					task.wait(0.05)
				end
			end)

			Debris:AddItem(sandVessel, 5)
			flammableHitbox:Destroy()
		end)

		sandSparkle.Parent = sandVessel
		sandDust.Parent = sandVessel
		sandSpawn.Parent = sandVessel
		flyingSandSparkle.Parent = sandVessel
		flyingSandDust.Parent = sandVessel

		sandSpawn:Emit(1)
		flyingSandSparkle:Emit(100)
		flyingSandDust:Emit(100)

		task.wait(0.1)
	end
end

function FlintAndSteel.jaegarInit(_: FlintAndSteel)
	ViewmodelController = require(ReplicatedStorage.client.controllers["viewmodel-controller"])
	HitboxController = require(ReplicatedStorage.client.controllers["hitbox-controller"])

	local camera = workspace.CurrentCamera

	while task.wait(0.05) do
		local params = RaycastParams.new()
		params.IncludeInstances = CollectionService:GetTagged("Flammable")
		params.FilterType = Enum.RaycastFilterType.Include

		local ray = raydar:Fire(
			camera.CFrame.Position,
			workspace.CurrentCamera.CFrame.LookVector,
			10,
			raydar.RayTypes.Flammable
		)

		if ray and ray.Instance then
			hitFlammable = ray.Instance
		else
			hitFlammable = nil
		end
	end
end

return FlintAndSteel
