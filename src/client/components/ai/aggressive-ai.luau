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

local Plr = Players.LocalPlayer
local LocalChar = Plr.Character or Plr.CharacterAdded:Wait()

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI

local stateDelay = 0.25 -- optional

export type AggressiveAI = typeof(setmetatable(
	{} :: {
		serverEntity: Model,
		clientEntity: Model,

		characterFollower: any,

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
		serverEntity = entity :: Model,
		animController = animController,
		sweatFx = {},
		currentState = "None",
		janitor = janitor,
	}, AggressiveAI)
end

function AggressiveAI.CreateAIModel(self: AggressiveAI, serverModel: Model)
	local entityAsset = enitityFolder:FindFirstChild(serverModel.Name, true)
	if not entityAsset then
		warn(serverModel, entityAsset)
	end

	local clientModel = entityAsset:WaitForChild("Client"):Clone()
	clientModel:PivotTo(serverModel:GetPivot())
	clientModel.PrimaryPart = clientModel:WaitForChild("HumanoidRootPart")
	clientModel.Parent = serverModel

	self.clientEntity = clientModel
	self.human = self.clientEntity:WaitForChild("Humanoid")

	local objVal = Instance.new("ObjectValue")
	objVal.Name = "TargetModel"
	objVal.Value = serverModel
	objVal.Parent = clientModel

	clientModel.PrimaryPart.Anchored = true
end

function AggressiveAI.EquipWeapon(self: AggressiveAI)
	if not self.currentWeapon then
		return
	end

	local weaponAsset = ReplicatedStorage.assets.models["npc-weapons"]:FindFirstChild(self.currentWeapon)

	if not weaponAsset then
		return
	end

	self.clientEntity.Name = self.currentWeapon
	local arm = self.clientEntity["Right Arm"]

	weaponAsset = weaponAsset:Clone()

	local motor6D = weaponAsset.PrimaryPart:FindFirstChildWhichIsA("Motor6D")
	if not motor6D then
		motor6D = Instance.new("Motor6D")
		motor6D.Part1 = weaponAsset.PrimaryPart
		motor6D.Parent = weaponAsset.PrimaryPart
	end

	motor6D.Name = "Weapon"
	motor6D.Part0 = arm
	weaponAsset.Parent = self.clientEntity
end

function AggressiveAI.Init(self: AggressiveAI)
	self:CreateAIModel(self.serverEntity)

	self.clientEntity:AddTag("CharacterFollower")

	self.animController = BetterAnimation.new(HttpService:GenerateGUID()) :: BetterAnimation.BetterAnimation
	self.animController:RegisterAnimator(self.human:WaitForChild("Animator") :: Animator)
	self.animController:RegisterAnimationsFromInstance(AnimationFolder)

	local sweatFxAsset = VfxFolder:WaitForChild("Sweat"):Clone() :: ParticleEmitter
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

	local newState = self.serverEntity:GetAttribute("State") :: string
	local func = self[newState]

	if func then
		func(self)
	end

	self.currentJob = self.serverEntity:GetAttribute("JobName")
	self.currentWeapon = self.serverEntity:GetAttribute("JobWeapon")

	self:EquipWeapon()

	task.wait()
	self.characterFollower = Classy.getGloballyRegistered("CharacterFollower"):GetApplied(self.clientEntity):GetData()
end

function AggressiveAI.Destroy(self: AggressiveAI)
	-- self.janitor:Cleanup()
end

function AggressiveAI.Chasing(self: AggressiveAI)
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(nil)
	end

	self.animController:Stop("AggressiveStumbleIdle")

	if self.serverEntity:GetAttribute("Recovering") then
		self.animController:Stop("AggressiveStumbleChase")

		self.animController:Play("AggressiveStumble", true)
		self.animController:GetTrack("AggressiveStumble"):AdjustSpeed(0.5)
	else
		self.animController:Stop("AggressiveStumble")

		self.animController:Play("AggressiveStumbleChase", true)
	end
end

function AggressiveAI.ExitChasing(self: AggressiveAI) end

function AggressiveAI.Hunting(self: AggressiveAI)
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(nil)
	end

	self.animController:Stop("AggressiveStumbleIdle")
	self.animController:Stop("AggressiveStumbleChase")

	self.animController:Play("AggressiveStumble", true)
	if self.serverEntity:GetAttribute("Recovering") then
		self.animController:GetTrack("AggressiveStumble"):AdjustSpeed(0.5)
	end
end

function AggressiveAI.ExitHunting(self: AggressiveAI) end

function AggressiveAI.Idle(self: AggressiveAI)
	self.characterFollower:ChangeLookAtTarget(LocalChar)

	if self.IdleDelay then
		task.cancel(self.IdleDelay)
		self.IdleDelay = nil
	end

	self.IdleDelay = task.spawn(function()
		task.wait(stateDelay)
		if self.serverEntity:GetAttribute("State") ~= "Idle" then
			return
		end
		self.animController:Stop("AggressiveStumbleChase")
		self.animController:Stop("AggressiveStumble")
		self.animController:Play("AggressiveStumbleIdle")
		if self.serverEntity:GetAttribute("Recovering") then
			self.animController:GetTrack("AggressiveStumbleIdle"):AdjustSpeed(2)
		end
	end)
end

function AggressiveAI.ExitIdle(self: AggressiveAI)
	if self.IdleDelay then
		task.cancel(self.IdleDelay)
		self.IdleDelay = nil
	end
end

function AggressiveAI.ExhaustedWalk(self: AggressiveAI) end

function AggressiveAI.ExitExhaustedWalk(self: AggressiveAI) end

function AggressiveAI.Attack(self: AggressiveAI)
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(LocalChar)
	end

	self.animController:Play("AttackPunch1")
	self.animController:GetTrack("AttackPunch1"):GetMarkerReachedSignal("hit"):Wait()

	local dir = (self.serverEntity:GetPivot().Position - LocalChar:GetPivot().Position).Unit
	self.characterFollower:ShakeOffset({
		Duration = 0.25,
		Direction = -dir,
		Velocity = 1,
	})
end

function AggressiveAI.ExitAttack(self: AggressiveAI) end

function AggressiveAI.Recovering(self: AggressiveAI)
	for _, fx in pairs(self.sweatFx) do
		fx.Enabled = true
	end

	if self.animController:GetTrack("AggressiveStumbleChase").IsPlaying then
		self.animController:Stop("AggressiveStumbleChase")

		self.animController:Play("AggressiveStumble", true)
		self.animController:GetTrack("AggressiveStumble"):AdjustSpeed(0.8)
	end
end

function AggressiveAI.ExitRecovering(self: AggressiveAI)
	for _, fx in pairs(self.sweatFx) do
		fx.Enabled = false
	end

	self.animController:GetTrack("AggressiveStumble"):AdjustSpeed(1)
	self.animController:GetTrack("AggressiveStumbleIdle"):AdjustSpeed(1)
	self.animController:GetTrack("AggressiveStumbleChase"):AdjustSpeed(1)
end

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
