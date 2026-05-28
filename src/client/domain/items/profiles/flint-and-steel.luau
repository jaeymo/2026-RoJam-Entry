--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local charState = require(ReplicatedStorage.client.domain.character["character-state"])
local flameConnector = require(ReplicatedStorage.client.domain["flame-handler"])
local raydar = require(ReplicatedStorage.shared.utils.raydar)

local ViewmodelController
local HitboxController

local FlintAndSteel = {}

export type FlintAndSteel = typeof(FlintAndSteel)

function FlintAndSteel.equip(self: FlintAndSteel)
	ViewmodelController.animationObject:Play("ViewModelFNSIdle")
	ViewmodelController:getViewmodel():setArmVisible("left")
end

function FlintAndSteel.unequip(self: FlintAndSteel)
	ViewmodelController.animationObject:Stop("ViewModelFNSIdle")
end

function FlintAndSteel.primary(self: FlintAndSteel)
	ViewmodelController.animationObject:Play("ViewModelFNSSpark")

	ViewmodelController.animationObject:GetTrack("ViewModelFNSSpark"):GetMarkerReachedSignal("hit"):Wait()

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
		return
	end
end

function FlintAndSteel.secondary(self: FlintAndSteel)
	ViewmodelController.animationObject:Stop("ViewModelFNSSpark")
	ViewmodelController.animationObject:Play("ViewModelSandThrow")
	ViewmodelController.animationObject:GetTrack("ViewModelSandThrow"):GetMarkerReachedSignal("hit"):Wait()

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
end

return FlintAndSteel
