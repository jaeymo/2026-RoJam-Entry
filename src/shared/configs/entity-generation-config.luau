--!strict
local ENTITY_GENERATION_CONFIG = {
	useOnlyAggressive = false,
	useOnlyPassive = true,

	-- temporary system
	getSpawnAmount = function(_: any)
		return math.random(1, 1)
	end,
}

return table.freeze(ENTITY_GENERATION_CONFIG) :: typeof(ENTITY_GENERATION_CONFIG)
