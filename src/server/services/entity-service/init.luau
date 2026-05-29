--!strict
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local testCharacters = ReplicatedStorage.assets.entities:FindFirstChild("test") :: Folder

local EntityFactory = require(script["entity-factory"])
local EntityGenerationConfig = require(ReplicatedStorage.shared.configs["entity-generation-config"])
local InfectedConfig = require(ReplicatedStorage.shared.configs["infected-config"])
local Lucky = require(ReplicatedStorage.shared.utils.lucky)
local MutationsConfig = require(ReplicatedStorage.shared.configs["mutations-config"])
local NpcEmployer = require(ReplicatedStorage.shared.utils["npc-employer"])
local ResourceAllocator = require(ReplicatedStorage.packages["resource-allocator"])
local SignalRegistry = require(ServerScriptService["signal-registry"])

local INFECTED_WEIGHTS = {
	["0"] = {
		Weight = InfectedConfig[0].Weight,
		Name = "0",
	},
	["1"] = {
		Weight = InfectedConfig[1].Weight,
		Name = "1",
	},
	["2"] = {
		Weight = InfectedConfig[2].Weight,
		Name = "2",
	},
}

local EntityService = {}

export type EntityService = typeof(EntityService)

local function getRandomInfectedLevel(): number
	local randomSelection = Lucky:chooseWeighted(INFECTED_WEIGHTS) :: { Name: string, Weight: number }
	if not randomSelection then
		warn(`[{script.Name}] Failed to select random infected weight`)
		return math.random(1, 3) - 1
	end

	return tonumber(randomSelection.Name) :: number
end

function EntityService.loadEntitiesIntoRoom(_: EntityService, roomModel: Model)
	local parent = Instance.new("Folder")
	parent.Name = roomModel:GetAttribute("GUID") :: string
	parent.Parent = workspace:WaitForChild("runtime"):WaitForChild("entities")

	local passiveEntitySpawns = {} :: { BasePart }
	local aggressiveEntitySpawns = {} :: { BasePart }

	for _, v in roomModel:GetDescendants() do
		if not v:IsA("BasePart") then
			continue
		end

		if v:HasTag("PassiveSpawnNode") then
			table.insert(passiveEntitySpawns, v)
		elseif v:HasTag("AggressiveSpawnNode") then
			table.insert(aggressiveEntitySpawns, v)
		end
	end

	local generatedWeights = EntityGenerationConfig.getEntitySpawnWeights()
	local entityStateAllocator = ResourceAllocator.new()

	entityStateAllocator:BatchAddItems({
		["Passive"] = { Weight = generatedWeights.Passive, Cost = 1 },
		["Aggressive"] = { Weight = generatedWeights.Aggressive, Cost = 1 },
	})

	local totalEntityCount = EntityGenerationConfig:getSpawnAmount()
	local allocatedStates = entityStateAllocator:Allocate(totalEntityCount)

	if EntityGenerationConfig.useOnlyAggressive then
		allocatedStates = {
			["Aggressive"] = totalEntityCount,
		}
	elseif EntityGenerationConfig.useOnlyPassive then
		allocatedStates = {
			["Passive"] = totalEntityCount,
		}
	end

	local passiveAmount = allocatedStates["Passive"] or 0
	local aggressiveAmount = allocatedStates["Aggressive"] or 0

	for _ = 1, passiveAmount do
		local jobData = NpcEmployer:getAJob()
		if not jobData.Name then
			warn("Could not assign job")
			continue
		end

		local newEntityModel = EntityFactory:getNewEntityModel(jobData.Name)
		if not newEntityModel then
			warn(`[{script.Name}] Failed to make new entity: {jobData.Name}`)
			continue
		end

		local randomIndex = math.random(1, #passiveEntitySpawns)
		local chosenNode = passiveEntitySpawns[randomIndex]

		newEntityModel:SetAttribute("GUID", HttpService:GenerateGUID(false))
		newEntityModel:PivotTo(chosenNode.CFrame * CFrame.new(0, 3, 0))

		local infectedLevel = getRandomInfectedLevel()
		newEntityModel:SetAttribute("InfectedLevel", infectedLevel)

		newEntityModel:SetAttribute("JobWeapon", jobData.Weapon)
		newEntityModel:SetAttribute("JobName", jobData.Name)
		newEntityModel:SetAttribute("DamageMultiplier", jobData.DamageMultiplier)
		newEntityModel:SetAttribute("HealthMultiplier", jobData.HealthMultiplier)
		newEntityModel:SetAttribute("DeathTollCollected", false)

		newEntityModel.Parent = parent

		newEntityModel:AddTag("Ragdoll")
		newEntityModel:AddTag("Entity")

		if Lucky:roll(MutationsConfig.MutationChance) then
			local chosenMutation = Lucky:chooseWeighted(MutationsConfig.Mutations)
			if chosenMutation then
				newEntityModel:AddTag(`{chosenMutation.Name}Mutation`)
			end
		end

		-- local tag = math.random() >= 0.5 and "PassiveAI" or "WanderingAI"
		newEntityModel:AddTag("WanderingAI")

		task.delay(1, function()
			newEntityModel:AddTag("Dialogue")
		end)

		task.wait(0.1) -- fun lil wait
	end

	for _ = 1, aggressiveAmount do
		local jobData = NpcEmployer:getAJob()
		if not jobData.Name then
			warn("Could not assign job")
			continue
		end

		local newEntityModel = EntityFactory:getNewEntityModel(jobData.Name)
		if not newEntityModel then
			warn(`[{script.Name}] Failed to make new entity: {jobData.Name}`)
			continue
		end

		local randomIndex = math.random(1, #aggressiveEntitySpawns)
		local chosenNode = aggressiveEntitySpawns[randomIndex]

		local infectedLevel = getRandomInfectedLevel()
		newEntityModel:SetAttribute("InfectedLevel", infectedLevel)

		newEntityModel:SetAttribute("GUID", HttpService:GenerateGUID(false))
		newEntityModel:PivotTo(chosenNode.CFrame * CFrame.new(0, 3, 0))
		newEntityModel.Parent = parent

		newEntityModel:SetAttribute("DeathTollCollected", false)
		newEntityModel:SetAttribute("JobWeapon", jobData.Weapon)
		newEntityModel:SetAttribute("JobName", jobData.Name)
		newEntityModel:SetAttribute("DamageMultiplier", jobData.DamageMultiplier)
		newEntityModel:SetAttribute("HealthMultiplier", jobData.HealthMultiplier)

		newEntityModel:AddTag("Ragdoll")
		newEntityModel:AddTag("Entity")
		newEntityModel:AddTag("AggressiveAI")

		-- less chance
		if Lucky:roll(MutationsConfig.AggressiveMutationChance) then
			local chosenMutation = Lucky:chooseWeighted(MutationsConfig.Mutations, { "Aggressive" }) -- blacklists aggressive mutation
			if chosenMutation then
				newEntityModel:AddTag(`{chosenMutation.Name}Mutation`)
			end
		end

		task.wait(0.1) -- fun lil wait
	end
end

function EntityService.jaegarInit(self: EntityService)
	SignalRegistry.roomInitialized:Connect(function(roomModel)
		if roomModel:HasTag("Safezone") then
			return
		end
		self:loadEntitiesIntoRoom(roomModel)
	end)
end

return EntityService
