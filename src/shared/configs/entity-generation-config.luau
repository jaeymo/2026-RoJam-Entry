--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- spawn scaling
local STARTING_ENTITY_COUNT = 4
local MAX_ENTITY_COUNT = 30
local TARGET_MAX_ROOM = 50
local SPAWN_GROWTH_EXPONENT = 1.35

local SPAWN_VARIANCE_MIN = -1
local SPAWN_VARIANCE_MAX = 2

-- weight scaling
local STARTING_PASSIVE_WEIGHT = 3
local STARTING_AGGRESSIVE_WEIGHT = 1

local ENDING_PASSIVE_WEIGHT = 1
local ENDING_AGGRESSIVE_WEIGHT = 5

local ENTITY_GENERATION_CONFIG = {
	useOnlyAggressive = false,
	useOnlyPassive = false,

	getSpawnAmount = function(_: any)
		local roomLevel = ReplicatedStorage["global-data"].room.Value
		local normalized = math.min(roomLevel / TARGET_MAX_ROOM, 1)
		local growthRange = MAX_ENTITY_COUNT - STARTING_ENTITY_COUNT
		local scaled = STARTING_ENTITY_COUNT + (growthRange * normalized ^ SPAWN_GROWTH_EXPONENT)
		local variance = math.random(SPAWN_VARIANCE_MIN, SPAWN_VARIANCE_MAX)

		return math.clamp(math.floor(scaled + variance), STARTING_ENTITY_COUNT, MAX_ENTITY_COUNT)
	end,

	getEntitySpawnWeights = function()
		local roomLevel = ReplicatedStorage["global-data"].room.Value
		local normalized = math.min(roomLevel / TARGET_MAX_ROOM, 1)

		local passiveWeight =
			math.floor(STARTING_PASSIVE_WEIGHT + ((ENDING_PASSIVE_WEIGHT - STARTING_PASSIVE_WEIGHT) * normalized))

		local aggressiveWeight = math.floor(
			STARTING_AGGRESSIVE_WEIGHT + ((ENDING_AGGRESSIVE_WEIGHT - STARTING_AGGRESSIVE_WEIGHT) * normalized)
		)

		return {
			Passive = passiveWeight,
			Aggressive = aggressiveWeight,
		}
	end,
}

return ENTITY_GENERATION_CONFIG :: typeof(ENTITY_GENERATION_CONFIG)
