--!nocheck
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationFolder = ReplicatedStorage:WaitForChild("assets"):WaitForChild("animations")
local VfxFolder = ReplicatedStorage:WaitForChild("assets"):WaitForChild("particles")

local BetterAnimation = require(ReplicatedStorage.packages["better-animation"])
local Classy = require(ReplicatedStorage.packages.classy)

local WanderingAI = {}
WanderingAI.__index = WanderingAI

local stateDelay = 0.25 -- optional

export type WanderingAI = typeof(setmetatable(
	{} :: {
		entity: Model,

		currentState: string,
		animController: BetterAnimation.BetterAnimation?,

		sweatFx: { ParticleEmitter },

		janitor: Classy.Janitor,
	},
	WanderingAI
))

function WanderingAI.new(entity: Instance, janitor: Classy.Janitor): WanderingAI
	return setmetatable({
		entity = entity :: Model,
		human = entity:WaitForChild("Humanoid"),
		sweatFx = {},
		currentState = "None",
		janitor = janitor,
	}, WanderingAI)
end

function WanderingAI.Init(self: WanderingAI)
	self.animController = BetterAnimation.new(HttpService:GenerateGUID()) :: BetterAnimation.BetterAnimation
	self.animController:RegisterAnimator(self.human:WaitForChild("Animator"))
	self.animController:RegisterAnimationsFromInstance(AnimationFolder)

	local sweatFxAsset = VfxFolder:WaitForChild("Sweat"):Clone()
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

	self.janitor:Add(task.spawn(function()
		while task.wait(math.random(3, 10)) do
			if self.entity:GetAttribute("State") == "Wandering" then
				self.animController:Play("ShakyIdle")
			end
		end
	end))

	local newState = self.entity:GetAttribute("State") :: string
	local func = self[newState]

	if func then
		func(self)
	end
end

function WanderingAI.Destroy(self: WanderingAI)
	self.janitor:Cleanup()
end

function WanderingAI.Resting(self: WanderingAI)
	self.animController:Play("ParanoidIdle", true)
end
function WanderingAI.ExitResting(self: WanderingAI)
	self.animController:Stop("ParanoidIdle")
end

function WanderingAI.Wandering(self: WanderingAI)
	self.animController:Play("Walk", true)
end

function WanderingAI.ExitWandering(self: WanderingAI)
	self.animController:Stop("Walk")
end

WanderingAI.classy = Classy.create("WanderingAI", WanderingAI, {})

Classy.registerGlobal("WanderingAI", WanderingAI.classy)

return WanderingAI
