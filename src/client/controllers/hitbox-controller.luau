--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Raydar = require(ReplicatedStorage.shared.utils.raydar)

local LocalPlayer = game:GetService("Players").LocalPlayer
local LocalChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local signals = require("../client-signal-registry")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local Network = Jaegar:GetNetwork()

local HitboxController = {}

export type HitboxController = typeof(HitboxController)

local PART_CACHE = Instance.new("Part")
PART_CACHE.Anchored = true
PART_CACHE.CastShadow = false
PART_CACHE.CanCollide = false
PART_CACHE.CanQuery = false
PART_CACHE.Transparency = 0.85
PART_CACHE.Color = Color3.fromRGB(255, 0, 0)

function HitboxController.CreateBox(CFrame, Size)
	local box = PART_CACHE:Clone()
	box.CFrame = CFrame
	box.Size = Size
	box.Parent = workspace.runtime.hitboxes
	return box
end

function HitboxController.CheckForHumanoids(CFrame: CFrame, Size: Vector3, Debug: boolean?)
	local rayTypeParams = Raydar.RayTypes.AimForPlayers.GetParams()

	local params = OverlapParams.new()
	params.FilterType = rayTypeParams.FilterType
	params.FilterDescendantsInstances = rayTypeParams.FilterDescendantsInstances
	params.CollisionGroup = rayTypeParams.CollisionGroup

	if Debug then
		local box = HitboxController.CreateBox(CFrame, Size)
		Debris:AddItem(box, 3)
	end

	local touching = workspace:GetPartBoundsInBox(CFrame, Size, params)
	local humans = {}

	for _, otherPart: BasePart in pairs(touching) do
		local hasModelParent = otherPart:FindFirstAncestorWhichIsA("Model")
		if not hasModelParent then
			continue
		end

		local humanoid = (otherPart:FindFirstAncestorWhichIsA("Model") :: Model):FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			continue
		end

		if table.find(humans, humanoid) then
			continue
		end
		table.insert(humans, humanoid)
	end

	return humans
end

function HitboxController.CheckEnemyHitbox(CFrame, Size, hitboxData)
	local humans = HitboxController.CheckForHumanoids(CFrame, Size)
	local plrHuman = LocalChar:FindFirstChildWhichIsA("Humanoid")

	for _, human in pairs(humans) do
		if human == plrHuman then
			signals.plrHit:Fire(hitboxData)

			task.spawn(function()
				Network:SendServer("sendHit")
			end)
		end
	end
end

Network:OnClient("spawnEnemyHitbox", function(CFrame, Size, hitboxData)
	HitboxController.CheckEnemyHitbox(CFrame, Size, hitboxData)
end)

return HitboxController
