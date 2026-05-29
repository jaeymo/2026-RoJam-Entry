--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)
local ToolTipConfig = require(ReplicatedStorage.shared.configs["tool-tip-config"])
local ToolTipController = require(ReplicatedStorage.client.controllers["tool-tip-controller"])

local EntityComponent = {}
EntityComponent.__index = EntityComponent

export type EntityComponent = typeof(setmetatable(
	{} :: {
		instance: Instance,
		janitor: Classy.Janitor,
	},
	EntityComponent
))

function EntityComponent.new(instance: Instance, janitor: Classy.Janitor): EntityComponent
	return setmetatable({
		instance = instance,
		janitor = janitor,
	}, EntityComponent)
end

local ringsChance = 0.2
local level1Chance = 0.2
local necroChance = 0.4

function EntityComponent.cleanPestillence(self: EntityComponent, model)
	local infectionLevel = self.instance:GetAttribute("InfectedLevel")

	for _, v in pairs(model.Level1:GetChildren()) do
		if infectionLevel < 1 or math.random() < level1Chance then
			v:Destroy()
		end
	end

	local spawnNecrosis = false
	if math.random() <= necroChance then
		spawnNecrosis = true
	end
	for _, v in pairs(model.Level2:GetChildren()) do
		if infectionLevel ~= 2 or not spawnNecrosis then
			v:Destroy()
		end
	end
	for _, v in pairs(model.Rings:GetChildren()) do
		if infectionLevel < 1 or math.random() < ringsChance then
			v:Destroy()
		end
	end
end

function EntityComponent.AddInfectionModel(self: EntityComponent)
	local random = math.random()
	if random < 0.4 then
		local w = Instance.new("WeldConstraint")
		local model = ReplicatedStorage.assets.models.InfectedArm:Clone()

		local limb = self.instance.Client["Right Arm"]
		model.Parent = limb
		model:PivotTo(limb.CFrame)
		w.Part0 = model.PrimaryPart
		w.Part1 = limb
		w.Parent = limb

		self:cleanPestillence(model)
	elseif random > 0.4 and random > 0.8 then
		local w = Instance.new("WeldConstraint")
		local model = ReplicatedStorage.assets.models.InfectedArm:Clone()

		local limb = self.instance.Client["Left Arm"]
		model.Parent = limb
		model:PivotTo(limb.CFrame)
		w.Part0 = model.PrimaryPart
		w.Part1 = limb
		w.Parent = limb

		self:cleanPestillence(model)
	else
		for i = 1, 2 do
			local model = ReplicatedStorage.assets.models.InfectedArm:Clone()
			if i == 1 then
				local w = Instance.new("WeldConstraint")
				local limb = self.instance.Client["Right Arm"]
				model:PivotTo(limb.CFrame)
				w.Part0 = model.PrimaryPart
				w.Part1 = limb
				w.Parent = limb
				model.Parent = limb
			else
				local w = Instance.new("WeldConstraint")
				local limb = self.instance.Client["Left Arm"]
				model.Parent = limb
				model:PivotTo(limb.CFrame)
				w.Part0 = model.PrimaryPart
				w.Part1 = limb
				w.Parent = limb
			end

			self:cleanPestillence(model)
		end
	end
end

function EntityComponent.AddLevel1Infection(self: EntityComponent) end

function EntityComponent.AddLevel2Infection(self: EntityComponent) end

function EntityComponent.Init(self: EntityComponent)
	if self.instance:GetAttribute("InfectedLevel") then
		self.instance:WaitForChild("Client")
		self:AddInfectionModel()
	end

	self.janitor:Add(self.instance:GetAttributeChangedSignal("DeathTollCollected"):Connect(function()
		ToolTipController:handleToolTip(self.instance, "deathTollCollected")
	end))
end

EntityComponent.classy = Classy.create("Entity", EntityComponent, {})

return EntityComponent
