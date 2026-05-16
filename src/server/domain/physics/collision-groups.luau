--!strict
local PhysicsService = game:GetService("PhysicsService")

-- a map of collision groups to what they can collide with
local COLLISION_GROUPS = {
	BarrierCollision = { "Entity", "PlayerCharacter" },
	EntityCollision = { "Entity", "PlayerCharacter", "IgnoreEntities" },

	PlayerCharacter = { "Entity", "PlayerCharacter", "BarrierCollision" },
	Entity = { "Entity", "PlayerCharacter", "BarrierCollision", "EntityCollision" },

	MapMesh = {},
	IgnoreEntities = { "EntityCollision" },
} :: {
	[string]: { string },
}

for v in COLLISION_GROUPS do
	PhysicsService:RegisterCollisionGroup(v)
end

for name, canCollideData in COLLISION_GROUPS do
	local collided = {} :: { [string]: boolean }

	for _, canCollideName in canCollideData do
		PhysicsService:CollisionGroupSetCollidable(name, canCollideName, true)
		collided[canCollideName] = true
	end

	for otherName in COLLISION_GROUPS do
		if otherName == name then
			continue
		end

		if collided[otherName] then
			continue
		end

		PhysicsService:CollisionGroupSetCollidable(name, otherName, false)
	end
end

return table.freeze(COLLISION_GROUPS) :: typeof(COLLISION_GROUPS)
