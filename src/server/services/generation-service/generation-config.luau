--!strict
local GENERATION_CONFIG = {
	worldOrigin = Vector3.yAxis * 100,
	parent = workspace:WaitForChild("runtime"):WaitForChild("map"),
}

return table.freeze(GENERATION_CONFIG) :: typeof(GENERATION_CONFIG)
