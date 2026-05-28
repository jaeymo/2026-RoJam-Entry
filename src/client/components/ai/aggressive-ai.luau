--!nocheck
local CollectionService = game:GetService("CollectionService")
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
local Viewer = require(ReplicatedStorage.packages.viewer)

local Plr = Players.LocalPlayer
local LocalChar = Plr.Character or Plr.CharacterAdded:Wait()

local AggressiveAI = {}
AggressiveAI.__index = AggressiveAI

local stateDelay = 0.25 -- optional

export type AggressiveAI = typeof(setmetatable(
	{} :: {
		serverEntity: Model,
		clientEntity: Model,

		destroyed: boolean,
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
		currentWeapon = entity:GetAttribute("JobWeapon"),
		currentJob = entity:GetAttribute("JobName"),
		animController = animController,
		sweatFx = {},
		destroyed = false,
		currentState = "None",
		janitor = janitor,
	}, AggressiveAI)
end

function AggressiveAI.isInitialized(self: AggressiveAI): boolean
	return self.serverEntity:GetAttribute("Initialized")
end

function AggressiveAI.CreateAIModel(self: AggressiveAI, serverModel: Model)
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

function AggressiveAI.ApplyInfectedEffects(self: AggressiveAI)
	local infectionLvl = self.serverEntity:GetAttribute("InfectedLevel")
	if not infectionLvl then
		return
	end

	local flies = assetsFolder.particles.Flies
	local bubonicAura = assetsFolder.particles.BubonicAura
	local bubonicEmission = assetsFolder.particles.BubonicEmission
	local sweatDrips = assetsFolder.particles.SweatDrips

	-- if infectionLvl == 0 then
	if infectionLvl == 1 then
		local effect = bubonicEmission:Clone()
		effect.Parent = self.clientEntity.PrimaryPart
	elseif infectionLvl == 2 then
		local effect = bubonicEmission:Clone()
		effect.Parent = self.clientEntity.PrimaryPart

		effect = bubonicAura:Clone()
		effect.Parent = self.clientEntity.PrimaryPart

		effect = flies:Clone()
		effect.Parent = self.clientEntity.PrimaryPart

		effect = sweatDrips:Clone()
		effect.Parent = self.clientEntity.PrimaryPart
	end
end

function AggressiveAI.EquipWeapon(self: AggressiveAI)
	if not self.currentWeapon then
		return
	end

	local weaponAsset = ReplicatedStorage.assets.models["npc-weapons"]:FindFirstChild(self.currentWeapon)

	if not weaponAsset then
		return
	end

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

	local poseAnim = self.currentWeapon .. "Pose"
	local animInst = AnimationFolder.weapons:FindFirstChild(poseAnim)
	if animInst then
		self.animController:Play(poseAnim)
	end
end

function AggressiveAI.Init(self: AggressiveAI)
	if self.serverEntity:FindFirstChild("NPCPrompt", true) then
		self.serverEntity:FindFirstChild("NPCPrompt", true):Destroy()
	end
	self:CreateAIModel(self.serverEntity)

	self.clientEntity:AddTag("CharacterFollower")

	self.animController = BetterAnimation.new(HttpService:GenerateGUID()) :: BetterAnimation.BetterAnimation
	self.animController:RegisterAnimator(self.human:WaitForChild("Animator") :: Animator)
	self.animController:RegisterAnimationsFromInstance(AnimationFolder)

	local sweatFxAsset = VfxFolder:WaitForChild("Sweat"):Clone() :: ParticleEmitter
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

	local newState = self.serverEntity:GetAttribute("State") :: string
	local func = self[newState]

	if func then
		func(self)
	end

	self:ApplyInfectedEffects()
	self:EquipWeapon()

	self.human:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	self.human:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	if self.serverEntity:GetAttribute("InitialTransitionState") then
		task.spawn(function()
			self:Stunned()
		end)
	end

	repeat
		task.wait()
	until Classy.getGloballyRegistered("CharacterFollower"):GetApplied(self.clientEntity)

	self.characterFollower = Classy.getGloballyRegistered("CharacterFollower"):GetApplied(self.clientEntity):GetData()
end

function AggressiveAI.OnDied(self: AggressiveAI)
	self.characterFollower:Stop()

	self.clientEntity.PrimaryPart.Anchored = false
	Ragdoller:activateRagdoll(self.clientEntity)

	local root = self.clientEntity:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local head = self.clientEntity:FindFirstChild("Head")
	if not head then
		warn("get jaeymo")
		return
	end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.P = 1e6
	bv.Velocity = Vector3.new(0, math.random(-15, 15), 0) + (-root.CFrame.LookVector * 15) * -1
	bv.Parent = head

	task.delay(0.2, function()
		bv:Destroy()
	end)
end

function AggressiveAI.Destroy(self: AggressiveAI)
	self.destroyed = true
	self.animController:StopAll()

	if self.serverEntity:HasTag("Dead") then
		self:OnDied()
	end
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
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(LocalChar)
	end

	if self.IdleDelay then
		task.cancel(self.IdleDelay)
		self.IdleDelay = nil
	end

	self.IdleDelay = task.spawn(function()
		task.wait(stateDelay)

		if self.destroyed then
			return
		end

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

	if not self.currentWeapon then
		print("NO: ", self)
	end

	local attackAnimName = self.currentWeapon .. "Attack"
	local animInst = AnimationFolder.weapons:FindFirstChild(attackAnimName)

	if not self.currentWeapon or not animInst then
		attackAnimName = "AttackPunch1"
	end

	self.animController:Play(attackAnimName)
	self.animController:GetTrack(attackAnimName):GetMarkerReachedSignal("hit"):Wait()

	local dir = (self.serverEntity:GetPivot().Position - LocalChar:GetPivot().Position).Unit

	self.characterFollower:ShakeOffset({
		Duration = 0.25,
		Direction = -dir,
		Velocity = 1,
	})
end

function AggressiveAI.Stunned(self: AggressiveAI)
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(nil)
	end

	local anims = {
		"StunDown",
		"StunPoke",
	}

	self.animController:Play(anims[math.random(1, #anims)])
end
function AggressiveAI.Burning(self: AggressiveAI)
	if self.characterFollower then
		self.characterFollower:ChangeLookAtTarget(nil)
	end

	self.animController:Play("Burning")
	self.animController:GetTrack("Burning").TimePosition = math.random(
		0,
		self.animController:GetTrack("Burning").Length * 10
	) / 100

	local anims = {
		"StunDown",
		"StunPoke",
	}

	local bodyAura = self.clientEntity.Torso:FindFirstChild("AuraBodyFlame")
		or assetsFolder.particles.AuraBodyFlame:Clone()
	local bodyFloat = self.clientEntity.Torso:FindFirstChild("FloatBodyFlame")
		or assetsFolder.particles.FloatBodyFlame:Clone()
	local bodySmoke = self.clientEntity.Torso:FindFirstChild("FloatBodySmoke")
		or assetsFolder.particles.FloatBodySmoke:Clone()

	bodyAura.Parent = self.clientEntity.Torso
	bodyFloat.Parent = self.clientEntity.Torso
	bodySmoke.Parent = self.clientEntity.Torso

	bodyAura.Enabled = true
	bodyFloat.Enabled = true
	bodySmoke.Enabled = true

	local flameLightPart = self.clientEntity.Torso:FindFirstChild("FlameLighting") or assetsFolder.FlameLighting:Clone()
	flameLightPart.Position = self.clientEntity.Torso.Position
	flameLightPart.WeldConstraint.Part1 = self.clientEntity.Torso
	flameLightPart.Parent = self.clientEntity.Torso

	for _, light in pairs(flameLightPart:GetDescendants()) do
		if not light:IsA("Light") then
			continue
		end

		light.Enabled = true
	end

	self.animController:Play(anims[math.random(1, #anims)])

	self.burningConnection = task.spawn(function()
		while task.wait() do
			local bodyColor = self.clientEntity["Body Colors"]

			local h, s, v = bodyColor.HeadColor3:ToHSV()
			v = math.lerp(v, 0, 0.005)

			bodyColor.HeadColor3 = Color3.fromHSV(h, s, v)
			bodyColor.TorsoColor3 = Color3.fromHSV(h, s, v)
			bodyColor.RightArmColor3 = Color3.fromHSV(h, s, v)
			bodyColor.LeftArmColor3 = Color3.fromHSV(h, s, v)
			bodyColor.RightLegColor3 = Color3.fromHSV(h, s, v)
			bodyColor.LeftLegColor3 = Color3.fromHSV(h, s, v)
		end
	end)
end

function AggressiveAI.ExitBurning(self: AggressiveAI)
	local bodyAura = self.clientEntity.Torso:FindFirstChild("AuraBodyFlame")
	local bodyFloat = self.clientEntity.Torso:FindFirstChild("FloatBodyFlame")
	local bodySmoke = self.clientEntity.Torso:FindFirstChild("FloatBodySmoke")

	if self.burningConnection then
		task.cancel(self.burningConnection)
	end

	bodyAura.Enabled = false
	bodyFloat.Enabled = false
	bodySmoke.Enabled = false

	self.animController:Stop("Burning")

	local flameLightPart = self.clientEntity.Torso:FindFirstChild("FlameLighting")

	for _, light in pairs(flameLightPart:GetDescendants()) do
		if not light:IsA("Light") then
			continue
		end

		light.Enabled = false
	end
end

function AggressiveAI.ExitAttack(self: AggressiveAI) end

function AggressiveAI.Stun(self: AggressiveAI)
	self.characterFollower:ChangeLookAtTarget(nil)

	local anims = {
		"StunPoke",
		"StunDown",
	}

	self.animController:Play(anims[math.random(1, #anims)])
end

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

AggressiveAI.classy = Classy.create("AggressiveAI", AggressiveAI, {
	Nuke = false,
})

Classy.registerGlobal("AggressiveAI", AggressiveAI.classy)

return AggressiveAI
