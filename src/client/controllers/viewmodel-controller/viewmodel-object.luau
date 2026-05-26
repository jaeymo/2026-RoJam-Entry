--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])
local Janitor = require(ReplicatedStorage.packages.janitor)
local Spring = require(ReplicatedStorage.packages.spring)

local YAW_MAX_ANGLE = 3.5
local PITCH_MAX_ANGLE = 2
local MAX_ROLL_ANGLE = 2.25
local SCALE = 0.2

local ViewmodelObject = {}
ViewmodelObject.__index = ViewmodelObject

export type ViewmodelObject = typeof(setmetatable(
	{} :: {
		camera: Camera,
		rig: Model,
		root: BasePart,
		mouseDelta: Vector2,
		left: BasePart,
		right: BasePart,
		janitor: Janitor.Janitor,
		springs: { [string]: Spring.Spring<number> },
		item: {
			motor: Motor6D?,
			model: Model?,
		},
	},
	ViewmodelObject
))

function ViewmodelObject.new(rig: Model): ViewmodelObject
	return setmetatable({
		camera = workspace.CurrentCamera,
		rig = rig,
		root = rig.PrimaryPart :: BasePart,
		left = rig:FindFirstChild("LeftArm") :: BasePart,
		right = rig:FindFirstChild("RightArm") :: BasePart,
		janitor = Janitor.new(),
		mouseDelta = Vector2.zero,
		springs = {},
		item = {},
	}, ViewmodelObject)
end

function ViewmodelObject.init(self: ViewmodelObject)
	self.rig:ScaleTo(SCALE)

	self:_makeSpring("pitch", 15, 0.5)
	self:_makeSpring("yaw", 11, 0.45)
	self:_makeSpring("roll", 12, 1)
	self:_makeSpring("jumpV", 1, 1)
	self:_makeSpring("jumpH", 1, 1)
end

local function makeFirstCapital(str: string): string
	if str == "" then
		return str
	end

	return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

function ViewmodelObject.setArmVisible(self: ViewmodelObject, armName: string)
	local arm = self[armName] :: BasePart?
	if not arm then
		warn(`[{script.Name}] Failed to get arm: {armName}`)
		return
	end

	local meshes = self.rig:FindFirstChild("Static/Meshes") :: Folder
	arm.Transparency = 0

	for _, v in (meshes:FindFirstChild(makeFirstCapital(armName)) :: Folder):GetDescendants() do
		if not v:IsA("BasePart") or not v:IsA("MeshPart") then
			continue
		end

		v.Transparency = 0
	end
end

function ViewmodelObject.setArmInvisible(self: ViewmodelObject, armName: string)
	local arm = self[armName] :: BasePart?
	if not arm then
		warn(`[{script.Name}] Failed to get arm: {armName}`)
		return
	end

	local meshes = self.rig:FindFirstChild("Static/Meshes") :: Folder
	arm.Transparency = 0

	for _, v in (meshes:FindFirstChild(makeFirstCapital(armName)) :: Folder):GetDescendants() do
		if not v:IsA("BasePart") or not v:IsA("MeshPart") then
			continue
		end

		v.Transparency = 1
	end
end

function ViewmodelObject.enable(self: ViewmodelObject)
	self.rig.Parent = self.camera
	self.janitor:Add(RunService.RenderStepped:Connect(function(dt: number)
		self:update(dt)
	end))
end

function ViewmodelObject.disable(self: ViewmodelObject)
	self.rig.Parent = nil
	self.janitor:Cleanup()
end

function ViewmodelObject.onJump(self: ViewmodelObject)
	self.springs["jumpH"]:Impulse(0.1 * (math.random() > 0.5 and -1 or 1))
	self.springs["jumpV"]:Impulse(0.25)
end

function ViewmodelObject.onLand(self: ViewmodelObject)
	self.springs["jumpH"]:Impulse(0.1 * (math.random() > 0.5 and -1 or 1))
	self.springs["jumpV"]:Impulse(-0.25)
end

function ViewmodelObject.updateMouseDelta(self: ViewmodelObject, mouseDelta: Vector2)
	self.mouseDelta = mouseDelta
end

function ViewmodelObject.update(self: ViewmodelObject, dt: number)
	self.rig:PivotTo(self.camera.CFrame * self:getSway(dt) * self:getRoll())
end

function ViewmodelObject.equip(self: ViewmodelObject, item: Model)
	if not item.PrimaryPart then
		warn(`[{script}] ItemModel is missing primary part: {item:GetFullName()}`)
		return
	end

	local motor = Instance.new("Motor6D")
	motor.Name = "ItemRoot"
	motor.Part0 = self.root
	motor.Part1 = item.PrimaryPart
	motor.Parent = self.root

	if item.Name == "Scepter" then
		motor.C0 = CFrame.new(Vector3.new(0.235, -0.315, -0.435)) * CFrame.Angles(0, math.rad(-90), 0)
	end

	self.item.motor = motor
	self.item.model = item

	item:ScaleTo(SCALE)
	item.Parent = self.rig
end

function ViewmodelObject.unequip(self: ViewmodelObject)
	if self.item.model then
		self.item.model.Parent = nil
	end

	if self.item.motor then
		self.item.motor:Destroy()
	end

	table.clear(self.item)
end

function ViewmodelObject.getRoll(self: ViewmodelObject): CFrame
	local root = CharacterState:getRoot()
	if not root then
		return CFrame.new()
	end

	local targetRoll = 0

	if CharacterState:isOnGround() then
		local moveDir = CharacterState:getMoveDirection()
		targetRoll = -moveDir:Dot(root.CFrame.RightVector) * math.rad(MAX_ROLL_ANGLE) -- roll range
	end

	self.springs["roll"].Target = targetRoll
	return CFrame.Angles(0, 0, self.springs["roll"].Position)
end

function ViewmodelObject.getSway(self: ViewmodelObject, dt: number): CFrame
	local pitchSpring = self.springs["pitch"]
	local yawSpring = self.springs["yaw"]

	local yawAngleRad = math.rad(YAW_MAX_ANGLE)
	local yawTarget = math.clamp(-self.mouseDelta.X * 0.0008 * yawAngleRad / dt, -yawAngleRad, yawAngleRad)

	local pitchAngleRad = math.rad(PITCH_MAX_ANGLE)
	local pitchTarget = math.clamp(-self.mouseDelta.Y * 0.004 * pitchAngleRad / dt, -pitchAngleRad, pitchAngleRad)

	yawSpring.Target = yawTarget
	pitchSpring.Target = pitchTarget

	self.mouseDelta = Vector2.zero
	return CFrame.Angles(pitchSpring.Position, yawSpring.Position, 0)
end

function ViewmodelObject._makeSpring(self: ViewmodelObject, springName: string, speed: number, damper: number)
	local spring = Spring.new()
	spring.Damper = damper
	spring.Speed = speed

	self.springs[springName] = spring
end

return ViewmodelObject
