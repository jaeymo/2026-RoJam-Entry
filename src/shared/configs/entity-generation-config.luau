--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ENTITY_GENERATION_CONFIG = {
	useOnlyAggressive = false,
	useOnlyPassive = false,

	-- temporary system
	getSpawnAmount = function(_: any)
		local roomLevel = ReplicatedStorage["global-data"].room.Value
		return math.random(4, 6)
	end,
}

return ENTITY_GENERATION_CONFIG :: typeof(ENTITY_GENERATION_CONFIG)
