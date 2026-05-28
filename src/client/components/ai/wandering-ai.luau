--!nocheck
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assetsFolder = ReplicatedStorage:WaitForChild("assets")
local AnimationFolder = assetsFolder:WaitForChild("animations")
local VfxFolder = assetsFolder:WaitForChild("particles")
local enitityFolder = assetsFolder:WaitForChild("entities")

local BetterAnimation = require(ReplicatedStorage.packages["better-animation"])
local Classy = require(ReplicatedStorage.packages.classy)
local Ragdoller = require(ReplicatedStorage.packages.ragdoller)

local Plr = Players.LocalPlayer
local LocalChar = Plr.Character or Plr.CharacterAdded:Wait()

local WanderingAI = {}
WanderingAI.__index = WanderingAI

export type WanderingAI = typeof(setmetatable(
	{} :: {
		serverEntity: Model,
		clientEntity: Model,

		currentState: string,
		animController: BetterAnimation.BetterAnimation?,
		human: Humanoid,

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

function WanderingAI.isInitialized(self: WanderingAI): boolean
	return self.serverEntity:GetAttribute("Initialized")
end

function WanderingAI.CreateAIModel(self: WanderingAI, serverModel: Model)
	local entityAsset = enitityFolder:FindFirstChild(serverModel.Name, true)
	if not entityAsset then
		warn(serverModel, entityAsset)
	end

	local clientModel
	if not self:isInitialized() then
		clientModel = entityAsset:WaitForChild("Client"):Clone()
		clientModel:PivotTo(serverModel:GetPivot())
		clientModel.PrimaryPart = clientModel:WaitForChild("HumanoidRootPart")
		clientModel.Parent = serverModel
	else
		clientModel = serverModel:WaitForChild("Client")
	end

	clientModel:AddTag("Ragdoll")

	self.clientEntity = clientModel
	self.human = self.clientEntity:WaitForChild("Humanoid")

	local objVal = Instance.new("ObjectValue")
	objVal.Name = "TargetModel"
	objVal.Value = serverModel
	objVal.Parent = clientModel

	clientModel.PrimaryPart.Anchored = true
end

function WanderingAI.Init(self: WanderingAI)
	self:CreateAIModel(self.serverEntity)

	self.clientEntity:AddTag("CharacterFollower")

	self.animController = BetterAnimation.new(HttpService:GenerateGUID()) :: BetterAnimation.BetterAnimation
	self.animController:RegisterAnimator(self.human:WaitForChild("Animator"))
	self.animController:RegisterAnimationsFromInstance(AnimationFolder)

	local sweatFxAsset = VfxFolder:WaitForChild("Sweat"):Clone()
	sweatFxAsset.Parent = self.clientEntity:WaitForChild("HumanoidRootPart")
	sweatFxAsset.Enabled = false

	self.serverEntity:SetAttribute("Initialized", true)

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

	self.human:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	repeat
		task.wait()
	until Classy.getGloballyRegistered("CharacterFollower"):GetApplied(self.clientEntity)

	self.characterFollower = Classy.getGloballyRegistered("CharacterFollower"):GetApplied(self.clientEntity):GetData()
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

function WanderingAI.Dialogue(self: WanderingAI)
	self.animController:StopAll()

	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(LocalChar)
	end
end

function WanderingAI.ExitDialogue(self: WanderingAI)
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(nil)
	end
end

function WanderingAI.OnDied(self: WanderingAI)
	self.animController:StopAll()
	self.characterFollower:Stop()

	self.clientEntity.PrimaryPart.Anchored = false
	Ragdoller:activateRagdoll(self.clientEntity)

	-- local root = self.clientEntity:FindFirstChild("HumanoidRootPart")
	-- if not root then
	-- 	return
	-- end

	-- local head = self.clientEntity:FindFirstChild("Head")
	-- if not head then
	-- 	warn("get jaeymo")
	-- 	return
	-- end

	-- local bv = Instance.new("BodyVelocity")
	-- bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	-- bv.P = 1e6
	-- bv.Velocity = Vector3.new(0, math.random(-15, 15), 0) + (-root.CFrame.LookVector * 100) * -1
	-- bv.Parent = head

	-- task.delay(0.2, function()
	-- 	bv:Destroy()
	-- end)
end

function WanderingAI.Destroy(self: WanderingAI)
	self.animController:StopAll()

	if self.serverEntity:HasTag("Dead") then
		self:OnDied()
	end
end

WanderingAI.classy = Classy.create("WanderingAI", WanderingAI, {
	Nuke = false,
})

Classy.registerGlobal("WanderingAI", WanderingAI.classy)

return WanderingAI
