--!nocheck
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationFolder = ReplicatedStorage:WaitForChild("assets"):WaitForChild("animations")
local VfxFolder = ReplicatedStorage:WaitForChild("assets"):WaitForChild("particles")

local BetterAnimation = require(ReplicatedStorage.packages["better-animation"])
local Classy = require(ReplicatedStorage.packages.classy)

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI

local stateDelay = 0.25 -- optional

export type AggressiveAI = typeof(setmetatable(
	{} :: {
		entity: Model,

		currentState: string,
		animController: BetterAnimation.BetterAnimation,
		human: Humanoid,
		sweatFx: { ParticleEmitter },

		IdleDelay: thread?,
		janitor: Classy.Janitor,
	},
	AggressiveAI
))

function AggressiveAI.new(entity: Instance, janitor: Classy.Janitor): AggressiveAI
	local animController = BetterAnimation.new(HttpService:GenerateGUID())

	return setmetatable({
		entity = entity :: Model,
		human = entity:WaitForChild("Humanoid") :: Humanoid,
		animController = animController,
		sweatFx = {},
		currentState = "None",
		janitor = janitor,
	}, AggressiveAI)
end

function AggressiveAI.Init(self: AggressiveAI)
	self.animController = BetterAnimation.new(HttpService:GenerateGUID()) :: BetterAnimation.BetterAnimation
	self.animController:RegisterAnimator(self.human:WaitForChild("Animator") :: Animator)
	self.animController:RegisterAnimationsFromInstance(AnimationFolder)

	local sweatFxAsset = VfxFolder:WaitForChild("Sweat"):Clone() :: ParticleEmitter
	sweatFxAsset.Parent = self.entity:WaitForChild("HumanoidRootPart")
	sweatFxAsset.Enabled = false

	-- for _, child in pairs(self.entity:GetChildren()) do
	-- 	if not child:IsA("BasePart") or child == self.entity.PrimaryPart then
	-- 		continue
	-- 	end

	-- 	local fx = sweatFxAsset:Clone()
	-- 	fx.Parent = child
	-- 	fx.Enabled = false

	self.sweatFx[#self.sweatFx + 1] = sweatFxAsset
	-- end

	self.janitor:Add(self.entity:GetAttributeChangedSignal("State"):Connect(function()
		local oldState = self.currentState
		local exitFunc = self["Exit" .. oldState]

		if exitFunc then
			exitFunc(self)
		end

		local newState = self.entity:GetAttribute("State") :: string
		local func = self[newState]

		if func then
			func(self)
		end

		self.currentState = newState
	end))

	self.janitor:Add(self.entity:GetAttributeChangedSignal("Recovering"):Connect(function()
		if self.entity:GetAttribute("Recovering") then
			self:Recovering()
		else
			self:ExitRecovering()
		end
	end))

	local newState = self.entity:GetAttribute("State") :: string
	local func = self[newState]

	if func then
		func(self)
	end
end

function AggressiveAI.Destroy(self: AggressiveAI)
	self.janitor:Cleanup()
end

function AggressiveAI.Chasing(self: AggressiveAI)
	self.animController:Stop("AggressiveStumble")
	self.animController:Play("AggressiveStumbleChase", true)
end

function AggressiveAI.ExitChasing(self: AggressiveAI) end

function AggressiveAI.Hunting(self: AggressiveAI)
	self.animController:Stop("AggressiveStumbleChase")
	self.animController:Play("AggressiveStumble", true)
end

function AggressiveAI.ExitHunting(self: AggressiveAI) end

function AggressiveAI.Idle(self: AggressiveAI)
	if self.IdleDelay then
		task.cancel(self.IdleDelay)
		self.IdleDelay = nil
	end

	self.IdleDelay = task.spawn(function()
		task.wait(stateDelay)
		if self.entity:GetAttribute("State") ~= "Idle" then
			return
		end
		self.animController:Stop("AggressiveStumbleChase")
		self.animController:Stop("AggressiveStumble")
		self.animController:Play("AggressiveStumbleIdle")
	end)
end

function AggressiveAI.ExitIdle(self: AggressiveAI)
	if self.IdleDelay then
		task.cancel(self.IdleDelay)
		self.IdleDelay = nil
	end
	self.animController:Stop("AggressiveStumbleIdle")
end

function AggressiveAI.ExhaustedWalk(self: AggressiveAI)
	self.animController:GetTrack("AggressiveStumbleIdle"):AdjustSpeed(0.5)
	self.animController:GetTrack("AggressiveStumble"):AdjustSpeed(0.5)
	self.animController:GetTrack("AggressiveStumbleChase"):AdjustSpeed(0.5)
end

function AggressiveAI.ExitExhaustedWalk(self: AggressiveAI)
	self.animController:GetTrack("AggressiveStumbleIdle"):AdjustSpeed(1)
	self.animController:GetTrack("AggressiveStumble"):AdjustSpeed(1)
	self.animController:GetTrack("AggressiveStumbleChase"):AdjustSpeed(1)
end

function AggressiveAI.Recovering(self: AggressiveAI)
	for _, fx in pairs(self.sweatFx) do
		fx.Enabled = true
	end
end

function AggressiveAI.ExitRecovering(self: AggressiveAI)
	for _, fx in pairs(self.sweatFx) do
		fx.Enabled = false
	end
end

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
