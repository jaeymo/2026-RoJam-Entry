--!nocheck
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assetsFolder = ReplicatedStorage:WaitForChild("assets")
local AnimationFolder = assetsFolder:WaitForChild("animations")
local VfxFolder = assetsFolder:WaitForChild("particles")
local enitityFolder = assetsFolder:WaitForChild("entities")

local BetterAnimation = require(ReplicatedStorage.packages["better-animation"])
local Classy = require(ReplicatedStorage.packages.classy)

local AIConfig = require(ReplicatedStorage.shared.configs["wandering-ai-config"])

local WanderingAI = {}
WanderingAI.__index = WanderingAI

local stateDelay = 0.25 -- optional

export type WanderingAI = typeof(setmetatable(
	{} :: {
		serverEntity: Model,
		clientEntity: Model,

		currentState: string,
		animController: BetterAnimation.BetterAnimation?,

		sweatFx: { ParticleEmitter },

		janitor: Classy.Janitor,
	},
	WanderingAI
))

function WanderingAI.new(entity: Instance, janitor: Classy.Janitor): WanderingAI
	return setmetatable({
		serverEntity = entity :: Model,
		sweatFx = {},
		currentState = "None",
		janitor = janitor,
	}, WanderingAI)
end

function WanderingAI.CreateAIModel(self: WanderingAI, serverModel: Model)
	local entityAsset = enitityFolder:FindFirstChild(serverModel.Name, true)
	if not entityAsset then
		warn(serverModel, entityAsset)
	end

	local clientModel = entityAsset:WaitForChild("Client"):Clone()
	clientModel:PivotTo(serverModel:GetPivot())
	clientModel.Parent = serverModel

	self.clientEntity = clientModel
	self.human = self.clientEntity:WaitForChild("Humanoid")

	local objVal = Instance.new("ObjectValue")
	objVal.Name = "TargetModel"
	objVal.Value = serverModel
	objVal.Parent = clientModel
end

function WanderingAI.Init(self: WanderingAI)
	self:CreateAIModel(self.serverEntity)

	self.animController = BetterAnimation.new(HttpService:GenerateGUID()) :: BetterAnimation.BetterAnimation
	self.animController:RegisterAnimator(self.human:WaitForChild("Animator"))
	self.animController:RegisterAnimationsFromInstance(AnimationFolder)

	local sweatFxAsset = VfxFolder:WaitForChild("Sweat"):Clone()
	sweatFxAsset.Parent = self.clientEntity:WaitForChild("HumanoidRootPart")
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

	self.janitor:Add(self.serverEntity:GetAttributeChangedSignal("State"):Connect(function()
		local oldState = self.currentState
		local exitFunc = self["Exit" .. oldState]

		if exitFunc then
			exitFunc(self)
		end

		local newState = self.serverEntity:GetAttribute("State") :: string
		local func = self[newState]

		if func then
			func(self)
		end

		self.currentState = newState
	end))

	self.janitor:Add(self.serverEntity:GetAttributeChangedSignal("Recovering"):Connect(function()
		if self.serverEntity:GetAttribute("Recovering") then
			self:Recovering()
		else
			self:ExitRecovering()
		end
	end))

	self.janitor:Add(task.spawn(function()
		while task.wait(math.random(3, 10)) do
			if self.serverEntity:GetAttribute("State") == "Wandering" then
				self.animController:Play("ShakyIdle")
			end
		end
	end))

	local newState = self.serverEntity:GetAttribute("State") :: string
	local func = self[newState]

	if func then
		func(self)
	end
end

function WanderingAI.Destroy(self: WanderingAI)
	-- self.janitor:Cleanup()
end

function WanderingAI.Resting(self: WanderingAI)
	self.currentIdle = "ParanoidIdle"
	self.animController:Play(self.currentIdle, true)
end
function WanderingAI.ExitResting(self: WanderingAI)
	self.animController:Stop(self.currentIdle)
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
