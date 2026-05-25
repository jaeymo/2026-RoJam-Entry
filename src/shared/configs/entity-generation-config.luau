--!strict
local ENTITY_GENERATION_CONFIG = {
	useOnlyAggressive = false,
	useOnlyPassive = true,

	-- temporary system
	getSpawnAmount = function(_: any)
		return math.random(4, 8)
	end,
}

return table.freeze(ENTITY_GENERATION_CONFIG) :: typeof(ENTITY_GENERATION_CONFIG)
