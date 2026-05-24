--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Viewer = require(ReplicatedStorage.packages.viewer)

local InitializeEntity = {}

export type InitializeEntity = typeof(InitializeEntity)

function InitializeEntity.jaegarInit(_: InitializeEntity)
	Viewer.WatchTag("Entity", false, function(instance: Instance)
		-- print(instance)
	end)
end

return InitializeEntity
