--!strict
local CONFIG = {
	worldOrigin = Vector3.yAxis * 100,
	parent = workspace:WaitForChild("runtime"):WaitForChild("map"),
}

return table.freeze(CONFIG) :: typeof(CONFIG)
