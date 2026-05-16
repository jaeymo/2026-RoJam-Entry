--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EntityFactory = require(script["entity-factory"])
local ResourceAllocator = require(ReplicatedStorage.packages["resource-allocator"])
local SignalRegistry = require(ServerScriptService["signal-registry"])

local EntityService = {}

export type EntityService = typeof(EntityService)

function EntityService.loadEntitiesIntoRoom(self: EntityService, roomModel: Model)
	local entityList = {
		["test-a"] = { Weight = 1, Cost = 1 },
		["test-b"] = { Weight = 1, Cost = 1 },
	}

	local allocator = ResourceAllocator.new()
	allocator:BatchAddItems(entityList)

	local allEntitySpawns = {} :: { BasePart }

	for _, v in roomModel:GetDescendants() do
		if v:HasTag("EntitySpawnNode") and v:IsA("BasePart") then
			table.insert(allEntitySpawns, v)
		end
	end

	local allocatedEntities = allocator:Allocate(math.round(#allEntitySpawns / 2))

	for entityName, amount in allocatedEntities do
		for _ = 1, amount do
			local newEntityModel = EntityFactory:getNewEntityModel(entityName)
			if not newEntityModel then
				warn(`[{script.Name}] Failed to make new entity: {entityName}`)
				continue
			end

			local randomIndex = math.random(1, #allEntitySpawns)

			local chosenNode = allEntitySpawns[randomIndex]
			table.remove(allEntitySpawns, randomIndex)

			newEntityModel:PivotTo(chosenNode.CFrame * CFrame.new(0, 3, 0))
			newEntityModel.Parent = workspace
		end
	end
end

function EntityService.jaegarInit(self: EntityService)
	SignalRegistry.roomSpawned:Connect(function(roomModel)
		self:loadEntitiesIntoRoom(roomModel)
	end)
end

return EntityService
