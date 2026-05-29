--!strict
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local repertoire = require(ReplicatedStorage.packages.repertoire)

local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])
local FindFirstAncestorWithTag = require(ReplicatedStorage.shared.utils["find-first-ancestor-with-tag"])
local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local ScepterConfig = require(ReplicatedStorage.shared.configs["scepter-config"])

local ViewmodelController
local HitboxController

local CameraShaker = require(ReplicatedStorage.client.controllers["camera-controller"]).shaker

local camera = workspace.CurrentCamera
local network = Jaegar:GetNetwork()

local Scepter = {
	cooldown = false,
}

export type Scepter = typeof(Scepter)

function Scepter.equip(_: Scepter)
	ViewmodelController.animationObject:Play("ViewModelScepterIdle")
	ViewmodelController:getViewmodel():setArmInvisible("left")
end

function Scepter.unequip(_: Scepter)
	ViewmodelController:getViewmodel():setArmVisible("left")
	ViewmodelController.animationObject:StopAll()
	-- ViewmodelController.animationObject:Stop("ViewModelScepterIdle")
end

local lastSelected: string? = nil
local randomAttackId: string? = nil

local function getRandomAttackName(): string
	local names = {
		"Batter",
		"Bonk",
		"Poke",
		"Peck",
	}

	if lastSelected then
		if lastSelected == "Batter" and math.random() >= ScepterConfig.chanceToFollowUpBatterWithPoke then
			return "Poke"
		end

		local index = table.find(names, lastSelected)
		if index then
			table.remove(names, index)
		end
	end

	local selection = names[math.random(1, #names)]
	lastSelected = selection

	return selection
end

local ScepterHitSwings = ReplicatedStorage.assets.sounds.ScepterSwings:GetChildren()

function Scepter.primary(self: Scepter)
	if self.cooldown then
		return
	end

	ReplicatedStorage["global-data"].canSwitchToNewItem.Value = false
	ViewmodelController:getViewmodel():setArmVisible("left")

	local scopedId = HttpService:GenerateGUID(false)
	randomAttackId = scopedId

	task.delay(2, function()
		if randomAttackId == scopedId then
			lastSelected = nil
		end
	end)

	if workspace.CurrentCamera.FieldOfView > 75 then
		TweenService:Create(
			workspace.CurrentCamera,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true),
			{
				FieldOfView = 75,
			}
		):Play()
	end

	local randomAttackName = getRandomAttackName()
	local attackData = ScepterConfig.attacks[randomAttackName]
	self:attack(randomAttackName, attackData)

	local newSwingSOund = ScepterHitSwings[math.random(1, #ScepterHitSwings)]
	newSwingSOund.PlaybackSpeed = math.random(90, 140) / 100
	repertoire.Accent(newSwingSOund):Spawn(workspace.CurrentCamera.CFrame.Position)
end

function Scepter.secondary(_self: Scepter) end

local normalHitAccent =
	repertoire.Accent(ReplicatedStorage.assets.particles.HitEffect):AddAction(repertoire.Actions.EmitCount):Props({
		Num = 1,
	})

local sweatCopy = ReplicatedStorage.assets.particles.Sweat:Clone()
sweatCopy.Enabled = false
local sweatAccent = repertoire.Accent(sweatCopy):AddAction(repertoire.Actions.EmitCount):Props({
	Num = 10,
})

local ScepterHitSounds = ReplicatedStorage.assets.sounds.ScepterHits:GetChildren()

function Scepter.handleNormalHit(self: Scepter, entityModel: Model)
	CameraShaker:ShakeOnce(1.5, 3, 0.1, 0.55)
	TweenService:Create(Lighting, TweenInfo.new(0.175, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true), {
		ExposureCompensation = -0.2,
	}):Play()

	local origin = entityModel:GetPivot().Position
	normalHitAccent:Spawn(origin)
	sweatAccent:Spawn(origin)

	repertoire.Accent(ScepterHitSounds[math.random(1, #ScepterHitSounds)]):Spawn(origin)
end

function Scepter.handleDeathHit(self: Scepter, entityModel: Model)
	local client = entityModel:FindFirstChild("Client")
	if client then
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.P = 1e6
		bv.Velocity = Vector3.new(0, math.random(15, 30), 0)
		bv.Parent = client:FindFirstChild("HumanoidRootPart")

		task.delay(0.2, function()
			bv:Destroy()
		end)

		repertoire.Accent(ScepterHitSounds[math.random(1, #ScepterHitSounds)]):Spawn(client:GetPivot().Position)
	end
end

function Scepter.attack(self: Scepter, attackName: string, attackData: ScepterConfig.AttackData)
	ViewmodelController.animationObject:StopAll()
	self.cooldown = true

	task.delay(1, function()
		ViewmodelController.animationObject:Play("ViewModelScepterIdle")
		ReplicatedStorage["global-data"].canSwitchToNewItem.Value = true
		self.cooldown = false
	end)

	local track = ViewmodelController.animationObject:GetTrack(`ViewModel{attackName}`) :: AnimationTrack
	if not track then
		warn(`[{script.Name}] No track with the name: ViewModel{attackName}`)
		return
	end

	ViewmodelController.animationObject:Play(`ViewModel{attackName}`)

	task.spawn(function()
		repeat
			task.wait()
		until track.IsPlaying == false

		ViewmodelController:getViewmodel():setArmInvisible("left")
	end)

	local c = track:GetMarkerReachedSignal("hit"):Once(function()
		local TIME = 0.4
		if attackName == "Batter" then
			TIME = 0.7
		end

		task.delay(TIME, function()
			-- ViewmodelController:getViewmodel():setArmInvisible("left")
			ReplicatedStorage["global-data"].canSwitchToNewItem.Value = true
		end)

		local hitboxCFrame = camera.CFrame + (camera.CFrame.LookVector * 4)
		local debugFlag = false

		local hits = HitboxController.CheckForHumanoids(hitboxCFrame, attackData.HitboxSize, debugFlag)
		if not next(hits) then
			return
		end

		local valid = {}
		for _, hit in hits do
			local entity = FindFirstAncestorWithTag(hit, "Entity") :: Model

			if entity then
				if entity:HasTag("Plague_Doctor") then
					continue
				end

				if entity:HasTag("Character") then
					continue
				end

				if entity:HasTag("Dead") then
					task.spawn(function()
						self:handleDeathHit(entity)
					end)
					continue
				end

				task.spawn(function()
					self:handleNormalHit(entity)
				end)
				table.insert(valid, entity)
			end
		end

		-- print(valid)
		network:SendServer("processScepterHits", valid, attackName)
	end)

	task.delay(5, function()
		if c then
			c:Disconnect()
		end
	end)
end

function Scepter.jaegarInit(_: Scepter)
	ViewmodelController = require(ReplicatedStorage.client.controllers["viewmodel-controller"])
	HitboxController = require(ReplicatedStorage.client.controllers["hitbox-controller"])
end

return Scepter
