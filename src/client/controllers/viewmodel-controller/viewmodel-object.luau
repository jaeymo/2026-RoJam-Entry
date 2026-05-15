--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local domain = ReplicatedStorage.client.domain

local CharacterState = require(domain.character["character-state"])
local Spring = require(ReplicatedStorage.packages.spring)
local ViewmodelSettings = require(script.Parent["viewmodel-settings"])

local viewmodelAssets = ReplicatedStorage.assets.viewmodel
local baseRig = viewmodelAssets:FindFirstChild("rig") :: Model
local camera = workspace.CurrentCamera

local MAX_ROLL_ANGLE = ViewmodelSettings.maxRollAngle
local ROLL_DAMPING = ViewmodelSettings.rollDamping
local ROLL_SPEED = ViewmodelSettings.rollSpeed
local SCALE = ViewmodelSettings.scale
local OCCLUSION_FADE_DURATION = ViewmodelSettings.occlusionFadeDuration

local YAW_MAX_ANGLE = ViewmodelSettings.yawMaxAngle
local YAW_SENSITIVITY = ViewmodelSettings.yawSensitivity
local PITCH_MAX_ANGLE = ViewmodelSettings.pitchMaxAngle
local PITCH_SENSITIVITY = ViewmodelSettings.pitchSensitivity
local PITCH_SPEED = ViewmodelSettings.pitchSpeed
local PITCH_DAMPING = ViewmodelSettings.pitchDamping
local YAW_SPEED = ViewmodelSettings.yawSpeed
local YAW_DAMPING = ViewmodelSettings.yawDamping

local JUMP_VERTICAL_SPEED = ViewmodelSettings.jumpVerticalSpeed
local JUMP_VERTICAL_DAMPING = ViewmodelSettings.jumpVerticalDamping
local JUMP_HORIZONTAL_SPEED = ViewmodelSettings.jumpHorizontalSpeed
local JUMP_HORIZONTAL_DAMPING = ViewmodelSettings.jumpHorizontalDamping
local JUMP_VERTICAL_IMPULSE = ViewmodelSettings.jumpVerticalImpulse
local JUMP_HORIZONTAL_IMPULSE = ViewmodelSettings.jumpHorizontalImpulse
local JUMP_RANDOM_DIRECTION_MIN = ViewmodelSettings.jumpRandomDirectionMin
local JUMP_RANDOM_DIRECTION_MAX = ViewmodelSettings.jumpRandomDirectionMax

local STEP_INTERVAL_BASE = ViewmodelSettings.stepIntervalBase
local STEP_INTERVAL_SPEED_REDUCTION = ViewmodelSettings.stepIntervalSpeedReduction
local IMPACT_DURATION = ViewmodelSettings.impactDuration
local REBOUND_END = ViewmodelSettings.reboundEnd
local SETTLE_END = ViewmodelSettings.settleEnd
local REBOUND_HEIGHT = ViewmodelSettings.reboundHeight
local HORIZONTAL_AMPLITUDE = ViewmodelSettings.horizontalAmplitude
local VERTICAL_AMPLITUDE = ViewmodelSettings.verticalAmplitude
local INITIAL_BOB_PROGRESS = ViewmodelSettings.initialBobProgress
local BOBBLE_SPEED_NORMALIZATION = ViewmodelSettings.bobbleSpeedNormalization
local MOVE_DIRECTION_THRESHOLD = ViewmodelSettings.moveDirectionThreshold
local MOVEMENT_SPEED_THRESHOLD = ViewmodelSettings.movementSpeedThreshold
local BOBBLE_VERTICAL_SPEED = ViewmodelSettings.bobbleVerticalSpeed
local BOBBLE_VERTICAL_DAMPING = ViewmodelSettings.bobbleVerticalDamping
local BOBBLE_HORIZONTAL_SPEED = ViewmodelSettings.bobbleHorizontalSpeed
local BOBBLE_HORIZONTAL_DAMPING = ViewmodelSettings.bobbleHorizontalDamping
local BOBBLE_LATERAL_CYCLE_DIVISOR = ViewmodelSettings.bobbleLateralCycleDivisor

local ViewmodelObject = {}
ViewmodelObject.__index = ViewmodelObject

type Spring = Spring.Spring<number>

export type ViewmodelObject = typeof(setmetatable(
	{} :: {
		rig: Model,
		root: BasePart,
		clothing: Model?,
		item: {
			model: Model?,
			motor: Motor6D?,
		},
		rightArm: BasePart,
		leftArm: BasePart,
		delta: Vector2,
		bobbleClock: number,
		wasBobbling: boolean,
		springs: {
			bobbleHorizontal: Spring,
			bobbleVertical: Spring,
			jumpHorizontal: Spring,
			jumpVertical: Spring,
			pitch: Spring,
			roll: Spring,
			yaw: Spring,
		},
	},
	ViewmodelObject
))

local function handleOcclusion(rig: Model, tweenTransparency: number, duration: number?)
	local info = TweenInfo.new(duration or OCCLUSION_FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, v in rig:GetDescendants() do
		if v.Name == "root" or v.Name == "Root" then
			continue
		end

		if v:IsA("BasePart") then
			TweenService:Create(v, info, { Transparency = tweenTransparency }):Play()
		end
	end
end

function ViewmodelObject.new(): ViewmodelObject
	local rig = baseRig:Clone()

	return setmetatable({
		rig = rig,
		root = rig:FindFirstChild("Root") :: BasePart,
		rightArm = (rig:FindFirstChild("Static/Meshes") :: Folder):FindFirstChild("RightArm") :: BasePart,
		leftArm = (rig:FindFirstChild("Static/Meshes") :: Folder):FindFirstChild("LeftArm") :: BasePart,
		item = {},
		delta = Vector2.zero,
		bobbleClock = 0,
		wasBobbling = false,
		springs = {} :: any,
	}, ViewmodelObject)
end

function ViewmodelObject.init(self: ViewmodelObject)
	self.rig:ScaleTo(SCALE)

	self:makeSpring("roll", ROLL_SPEED, ROLL_DAMPING)
	self:makeSpring("yaw", YAW_SPEED, YAW_DAMPING)
	self:makeSpring("pitch", PITCH_SPEED, PITCH_DAMPING)
	self:makeSpring("jumpVertical", JUMP_VERTICAL_SPEED, JUMP_VERTICAL_DAMPING)
	self:makeSpring("jumpHorizontal", JUMP_HORIZONTAL_SPEED, JUMP_HORIZONTAL_DAMPING)
	self:makeSpring("bobbleVertical", BOBBLE_VERTICAL_SPEED, BOBBLE_VERTICAL_DAMPING)
	self:makeSpring("bobbleHorizontal", BOBBLE_HORIZONTAL_SPEED, BOBBLE_HORIZONTAL_DAMPING)
end

function ViewmodelObject.enable(self: ViewmodelObject)
	self.rig.Parent = camera
	handleOcclusion(self.rig, 0)
end

function ViewmodelObject.disable(self: ViewmodelObject)
	self.rig.Parent = nil
	handleOcclusion(self.rig, 1, 0)
end

function ViewmodelObject.equip(self: ViewmodelObject, itemModel: Model)
	if not itemModel.PrimaryPart then
		warn(`[{script}] ItemModel is missing primary part: {itemModel:GetFullName()}`)
		return
	end

	local motor = Instance.new("Motor6D")
	motor.Part0 = self.root
	motor.Part1 = itemModel.PrimaryPart
	motor.Parent = self.root

	self.item.motor = motor
	self.item.model = itemModel

	itemModel:ScaleTo(SCALE)
	itemModel.Parent = self.root
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

function ViewmodelObject.updateDelta(self: ViewmodelObject, delta: Vector2)
	self.delta = delta
end

function ViewmodelObject.makeSpring(self: ViewmodelObject, springName: string, speed: number, damping: number)
	local spring = Spring.new(0)
	spring.Speed = speed
	spring.Damper = damping

	self.springs[springName] = spring
end

local function randomSwayDirection()
	return (math.random() > 0.5 and 1 or -1)
		* math.random(JUMP_RANDOM_DIRECTION_MIN * 100, JUMP_RANDOM_DIRECTION_MAX * 100)
		/ 100
end

function ViewmodelObject.onJump(
	self: ViewmodelObject,
	multipliers: {
		vertical: number,
		horizontal: number,
	}?
)
	self.springs.jumpHorizontal:Impulse(
		randomSwayDirection() * JUMP_HORIZONTAL_IMPULSE * (multipliers and multipliers.horizontal or 1)
	)
	self.springs.jumpVertical:Impulse(JUMP_VERTICAL_IMPULSE * (multipliers and multipliers.vertical or 1))
end

function ViewmodelObject.onLand(
	self: ViewmodelObject,
	multipliers: {
		vertical: number,
		horizontal: number,
	}?
)
	self.springs.jumpHorizontal:Impulse(-JUMP_HORIZONTAL_IMPULSE * (multipliers and multipliers.horizontal or 1))
	self.springs.jumpVertical:Impulse(-JUMP_VERTICAL_IMPULSE * (multipliers and multipliers.vertical or 1))
end

function ViewmodelObject.update(self: ViewmodelObject, dt: number)
	self.root.CFrame = camera.CFrame * self:getRoll() * self:getSway(dt) * self:getBobble(dt) * self:getJump()
end

function ViewmodelObject.getRoll(self: ViewmodelObject): CFrame
	local root = CharacterState:getRoot()
	if not root then
		return CFrame.new()
	end

	local targetRoll = 0

	if CharacterState:isOnGround() then
		local moveDirection = CharacterState:getMoveDirection()
		local right = root.CFrame.RightVector
		local relative = moveDirection:Dot(right)
		targetRoll = -relative * math.rad(MAX_ROLL_ANGLE) -- max roll angle
	end

	self.springs.roll.Target = targetRoll
	return CFrame.Angles(0, 0, self.springs.roll.Position)
end

function ViewmodelObject.getSway(self: ViewmodelObject, dt: number): CFrame
	local pitchSpring = self.springs.pitch
	local yawSpring = self.springs.yaw

	local yawAngleRad = math.rad(YAW_MAX_ANGLE)
	local yawTarget = math.clamp(-self.delta.X * YAW_SENSITIVITY * yawAngleRad / dt, -yawAngleRad, yawAngleRad)

	local pitchAngleRad = math.rad(PITCH_MAX_ANGLE)
	local pitchTarget =
		math.clamp(-self.delta.Y * PITCH_SENSITIVITY * pitchAngleRad / dt, -pitchAngleRad, pitchAngleRad)

	yawSpring.Target = yawTarget
	pitchSpring.Target = pitchTarget

	self.delta = Vector2.zero
	return CFrame.Angles(pitchSpring.Position, yawSpring.Position, 0)
end

function ViewmodelObject.getJump(self: ViewmodelObject): CFrame
	return CFrame.new(self.springs.jumpHorizontal.Position, self.springs.jumpVertical.Position, 0)
end

function ViewmodelObject.getBobble(self: ViewmodelObject, dt: number): CFrame
	local horizontalSpring = self.springs.bobbleHorizontal
	local verticalSpring = self.springs.bobbleVertical

	local moveDirection = CharacterState:getMoveDirection()
	local speed = CharacterState:getSpeed()
	local isMoving = moveDirection.Magnitude > MOVE_DIRECTION_THRESHOLD and speed > MOVEMENT_SPEED_THRESHOLD
	local grounded = CharacterState:isOnGround()

	if isMoving and grounded then
		local speedAlpha = math.clamp(speed / BOBBLE_SPEED_NORMALIZATION, 0, 1)
		local stepInterval = STEP_INTERVAL_BASE - (STEP_INTERVAL_SPEED_REDUCTION * speedAlpha)

		if not self.wasBobbling then
			self.wasBobbling = true
			self.bobbleClock = stepInterval * INITIAL_BOB_PROGRESS
		else
			self.bobbleClock += dt
		end

		local stepProgress = (self.bobbleClock % stepInterval) / stepInterval

		local verticalWave = 0
		if stepProgress < IMPACT_DURATION then
			verticalWave = -(stepProgress / IMPACT_DURATION)
		elseif stepProgress < REBOUND_END then
			verticalWave = -1
				+ ((stepProgress - IMPACT_DURATION) / (REBOUND_END - IMPACT_DURATION)) * (1 + REBOUND_HEIGHT)
		elseif stepProgress < SETTLE_END then
			verticalWave = REBOUND_HEIGHT - ((stepProgress - REBOUND_END) / (SETTLE_END - REBOUND_END)) * REBOUND_HEIGHT
		else
			verticalWave = 0
		end

		local lateralWave = math.sin((self.bobbleClock / (stepInterval * BOBBLE_LATERAL_CYCLE_DIVISOR)) * math.pi * 2)
		horizontalSpring.Target = lateralWave * HORIZONTAL_AMPLITUDE * speedAlpha
		verticalSpring.Target = verticalWave * VERTICAL_AMPLITUDE * speedAlpha
	else
		self.wasBobbling = false
		self.bobbleClock = 0
		horizontalSpring.Target = 0
		verticalSpring.Target = 0
	end

	return CFrame.new(horizontalSpring.Position, verticalSpring.Position, 0)
end

return ViewmodelObject
