--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Classy = require(ReplicatedStorage.packages.classy)

local CharacterFollower = {}
CharacterFollower.__index = CharacterFollower

export type CharacterFollower = typeof(setmetatable(
	{} :: {
		taggedModel: Model,
		targetModel: Model,

		lookAtTarget: Model,

		offset: Vector3,

		janitor: Classy.Janitor,
	},
	CharacterFollower
))

function CharacterFollower.new(taggedModel: Instance, janitor: Classy.Janitor): CharacterFollower
	return setmetatable({
		taggedModel = taggedModel :: Model,
		janitor = janitor,
	}, CharacterFollower)
end

function CharacterFollower.Init(self: CharacterFollower)
	local targetModel = self.taggedModel:FindFirstChild("TargetModel")

	if not targetModel then
		error("Missing TargetModel object value under tagged model")
	else
		self.targetModel = targetModel.Value
	end

	self:Start()
	self.offset = Vector3.zero
end

function CharacterFollower.Start(self: CharacterFollower)
	self.janitor:Add(RunService.RenderStepped:Connect(function()
		local targetOrigin = self.targetModel:GetPivot()

		local lookAtPos

		if self.lookAtTarget then
			lookAtPos = self.lookAtTarget:GetPivot().Position
		end

		local targetCFrame

		if lookAtPos then
			targetCFrame = CFrame.new(targetOrigin.Position + self.offset, lookAtPos)
		else
			targetCFrame = targetOrigin * CFrame.new(self.offset)
		end

		self.taggedModel:PivotTo(targetCFrame)
	end))
end

function CharacterFollower.ChangeLookAtTarget(self: CharacterFollower, newChar: Model)
	self.lookAtTarget = newChar
end

function CharacterFollower.ApplyOffset(self: CharacterFollower, newOffset: Vector3)
	self.offset = newOffset
end

function CharacterFollower.ShakeOffset(
	self: CharacterFollower,
	effectInfo: {
		Duration: number,
		Direction: Vector3,
		Velocity: number,
		EasingStyle: string,
		EasingDirection: string,
		Reverse: boolean,
	}
)
	effectInfo = effectInfo or {}
	local Duration = effectInfo.Duration or 0.5
	local Direction = effectInfo.Direction or Vector3.zAxis
	local Velocity = effectInfo.Velocity or 10
	local EasingStyle = effectInfo.EasingStyle or "Quad"
	local EasingDirection = effectInfo.EasingDirection or "InOut"
	local Reverse = effectInfo.Reverse or true

	local numVal = Instance.new("Vector3Value")
	numVal.Value = Vector3.zero
	local Tween = TweenService:Create(
		numVal,
		TweenInfo.new(Duration, Enum.EasingStyle[EasingStyle], Enum.EasingDirection[EasingDirection], 0, Reverse),
		{
			Value = Direction * Velocity,
		}
	)

	Tween:Play()
	repeat
		self.offset = numVal.Value
		RunService.RenderStepped:Wait()
	until Tween.PlaybackState == Enum.PlaybackState.Completed
	numVal:Destroy()
end

CharacterFollower.classy = Classy.create("CharacterFollower", CharacterFollower, {})

Classy.registerGlobal("CharacterFollower", CharacterFollower.classy)

return CharacterFollower
