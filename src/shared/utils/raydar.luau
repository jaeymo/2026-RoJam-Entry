--!strict
local Raydar = {}

export type Raydar = typeof(Raydar)

Raydar.RayTypes = {
	HitWalls = {
		Name = "HitWalls",
		GetParams = function()
			local filter = {}

			local params = RaycastParams.new()
			params.CollisionGroup = "IgnoreEntities"

			return params
		end,
	},
}

function Raydar.Fire(_: Raydar, origin: Vector3, direction: Vector3, distance: number, raytype)
	raytype = (raytype and raytype.GetParams) and raytype.GetParams()
	if not raytype then
		local rayName = raytype and raytype.Name or nil
		warn("RayType: ", rayName)
		error("raytype nil or did not return rayparams. Make sure you are getting a raytype from Raydar.Raytypes")
	end
	local result = workspace:Raycast(origin, direction * distance, raytype)
	return result
end

return Raydar
