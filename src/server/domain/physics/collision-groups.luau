--!strict
local PhysicsService = game:GetService("PhysicsService")

-- a map of collision groups to what they can collide with
local COLLISION_GROUPS = {
	BarrierCollision = {
		CanCollide = { "Entity", "PlayerCharacter" },
	},
	EntityCollision = {
		CanCollide = { "Entity", "PlayerCharacter", "IgnoreEntities" },
	},

	PlayerCharacter = {
		CanCollide = { "Entity", "PlayerCharacter", "BarrierCollision", "EntityCollision", "IgnoreEntities" },
	},
	PassiveEntity = {
		CanCollide = { "Entity", "PlayerCharacter", "BarrierCollision", "EntityCollision", "PathWall" },
		CannotCollide = { "PassiveEntity" },
	},
	Entity = {
		CanCollide = {
			"Entity",
			"PlayerCharacter",
			"BarrierCollision",
			"EntityCollision",
			"PathWall",
			"PassiveEntity",
			"CollisionHitbox",
		},
	},
	MapMesh = {
		CanCollide = {},
	},
	IgnorePlayers = {
		CanCollide = { "EntityCollision", "Entity", "PathWall", "CollisionHitbox" },
	},
	IgnoreEntities = {
		CanCollide = { "EntityCollision", "PlayerCharacter", "PathWall", "CollisionHitbox" },
	},
	IgnoreCharacters = {
		CanCollide = { "EntityCollision" },
	},

	CollisionHitbox = {
		CanCollide = { "CollisionHitbox", "Entity", "IgnoreEntities" },
	},
	PathNode = {
		CanCollide = { "PathCast" },
	},
	PathWall = {
		CanCollide = { "Entity", "PassiveEntity", "PathCast", "IgnoreEntities" },
	},
	PathCast = {
		CanCollide = { "EntityCollision", "PathNode", "PathWall" },
	},
} :: {
	[string]: { CanCollide: { string }, CannotCollide: { string } },
}

for v in COLLISION_GROUPS do
	PhysicsService:RegisterCollisionGroup(v)
end

for name, collisionData in COLLISION_GROUPS do
	local collided = {} :: { [string]: boolean }

	local canCollideData = collisionData.CanCollide
	for _, canCollideName in canCollideData do
		-- if name == "Entity" then
		-- 	print(name, canCollideName)
		-- end
		PhysicsService:CollisionGroupSetCollidable(name, canCollideName, true)
		collided[canCollideName] = true
	end

	local cannotCollideData = collisionData.CannotCollide
	if cannotCollideData then
		for _, cannotCollideName in cannotCollideData do
			PhysicsService:CollisionGroupSetCollidable(name, cannotCollideName, false)
		end
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
