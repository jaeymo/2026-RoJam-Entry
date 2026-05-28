--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()

local network = Jaegar:GetNetwork()

local TELEPORT_ID = 120390719683979

local WorldStateService = {}

export type WorldStateService = typeof(WorldStateService)

function WorldStateService.restartGameSession(_: WorldStateService, player: Player)
	if RunService:IsStudio() then
		warn("WOULD'VE TELEPORTED PLAYER TO REJOIN.")
		return
	end

	TeleportService:Teleport(TELEPORT_ID, player)
end

function WorldStateService.jaegarInit(self: WorldStateService)
	ReplicatedStorage["global-data"].room.Value = 1

	network:OnServer("restartGameSession", function(player: Player)
		self:restartGameSession(player)
	end)
end

return WorldStateService
