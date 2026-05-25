--!strict
local ENTITY_GENERATION_CONFIG = {
	useOnlyAggressive = true,
	useOnlyPassive = false,

	-- temporary system
	getSpawnAmount = function(_: any)
		return math.random(4, 4)
	end,
}

return table.freeze(ENTITY_GENERATION_CONFIG) :: typeof(ENTITY_GENERATION_CONFIG)
