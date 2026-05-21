--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Classy = require(ReplicatedStorage.packages.classy)

local CharacterFollower = {}
CharacterFollower.__index = CharacterFollower

export type CharacterFollower = typeof(setmetatable(
	{} :: {
		taggedModel: Model,
		targetModel: Model,

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
end

function CharacterFollower.Start(self: CharacterFollower)
	self.janitor:Add(RunService.RenderStepped:Connect(function()
		self.taggedModel:PivotTo(self.targetModel:GetPivot())
	end))
end

function CharacterFollower.ApplyOffset(self: CharacterFollower, newOffset: Vector3) end

function CharacterFollower.ShakeOffset(self: CharacterFollower, newOffset: Vector3) end

CharacterFollower.classy = Classy.create("CharacterFollower", CharacterFollower, {})

Classy.registerGlobal("CharacterFollower", CharacterFollower.classy)

return CharacterFollower
