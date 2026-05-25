--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EntityFactory = require(script["entity-factory"])
local Lucky = require(ReplicatedStorage.shared.utils.lucky)
local MutationsConfig = require(ReplicatedStorage.shared.configs["mutations-config"])
local NpcEmployer = require(ReplicatedStorage.shared.utils["npc-employer"])
local ResourceAllocator = require(ReplicatedStorage.packages["resource-allocator"])
local SignalRegistry = require(ServerScriptService["signal-registry"])

local EntityService = {}

export type EntityService = typeof(EntityService)

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

	local entityStateAllocator = ResourceAllocator.new()
	entityStateAllocator:BatchAddItems({
		["Passive"] = { Weight = 5, Cost = 1 },
		["Aggressive"] = { Weight = 1, Cost = 1 },
	})

	local totalEntityCount = math.random(2, 5)

	local allocatedStates = entityStateAllocator:Allocate(totalEntityCount)
	allocatedStates = {
		["Aggressive"] = totalEntityCount,
	}

	local passiveAmount = allocatedStates["Passive"] or 0
	local aggressiveAmount = allocatedStates["Aggressive"] or 0

	for _ = 1, passiveAmount do
		local newEntityModel = EntityFactory:getNewEntityModel("test-a")
		if not newEntityModel then
			warn(`[{script.Name}] Failed to make new entity: {"test-a"}`)
			continue
		end

		local randomIndex = math.random(1, #passiveEntitySpawns)
		local chosenNode = passiveEntitySpawns[randomIndex]

		newEntityModel:SetAttribute("GUID", HttpService:GenerateGUID(false))
		newEntityModel:PivotTo(chosenNode.CFrame * CFrame.new(0, 3, 0))

		local data = NpcEmployer:getAJob()
		newEntityModel:SetAttribute("JobWeapon", data.Weapon)
		newEntityModel:SetAttribute("JobName", data.Name)
		newEntityModel:SetAttribute("DamageMultiplier", data.DamageMultiplier)
		newEntityModel:SetAttribute("HealthMultiplier", data.HealthMultiplier)

		newEntityModel.Parent = workspace

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
		task.wait(0.1) -- fun lil wait
	end

	for _ = 1, aggressiveAmount do
		local newEntityModel = EntityFactory:getNewEntityModel("test-a")
		if not newEntityModel then
			warn(`[{script.Name}] Failed to make new entity: {"test-a"}`)
			continue
		end

		local randomIndex = math.random(1, #aggressiveEntitySpawns)
		local chosenNode = aggressiveEntitySpawns[randomIndex]

		newEntityModel:SetAttribute("GUID", HttpService:GenerateGUID(false))
		newEntityModel:PivotTo(chosenNode.CFrame * CFrame.new(0, 3, 0))
		newEntityModel.Parent = parent

		local data = NpcEmployer:getAJob()
		newEntityModel:SetAttribute("JobWeapon", data.Weapon)
		newEntityModel:SetAttribute("JobName", data.Name)
		newEntityModel:SetAttribute("DamageMultiplier", data.DamageMultiplier)
		newEntityModel:SetAttribute("HealthMultiplier", data.HealthMultiplier)

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
