--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ENTITY_GENERATION_CONFIG = {
	useOnlyAggressive = true,
	useOnlyPassive = false,

	-- temporary system
	getSpawnAmount = function(_: any)
		local roomLevel = ReplicatedStorage["global-data"].room.Value

		local normalized = math.min(roomLevel / 50, 1)
		local scaled = 4 + (26 * normalized ^ 1.35)

		local variance = math.random(-1, 2)

		return math.clamp(math.floor(scaled + variance), 4, 30) -- 30 is max entities
	end,
}

return ENTITY_GENERATION_CONFIG :: typeof(ENTITY_GENERATION_CONFIG)
