--!strict
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local AIR = Enum.Material.Air

local CharacterState = {}

export type CharacterState = typeof(CharacterState)

function CharacterState.getHumanoid(_: CharacterState): Humanoid?
	return player.Character and player.Character:FindFirstChild("Humanoid") :: Humanoid?
end

function CharacterState.getRoot(_: CharacterState): BasePart?
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function CharacterState.getSpeed(self: typeof(CharacterState)): number
	local root = self:getRoot()
	if not root then
		return 0
	end

	local velocity = root.AssemblyLinearVelocity
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
end

function CharacterState.getMoveDirection(self: typeof(CharacterState)): Vector3
	local humanoid = self:getHumanoid()
	return humanoid and humanoid.MoveDirection or Vector3.zero
end

function CharacterState.getFacingDirection(_: typeof(CharacterState)): Vector3
	return camera.CFrame.LookVector
end

function CharacterState.isOnGround(self: typeof(CharacterState)): boolean
	local humanoid = self:getHumanoid()
	return humanoid ~= nil and humanoid.FloorMaterial ~= AIR
end

function CharacterState.isInAir(self: typeof(CharacterState)): boolean
	return not self:isOnGround()
end

return CharacterState
