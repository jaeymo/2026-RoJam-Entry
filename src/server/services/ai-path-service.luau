--!strict
local PathfindingService = game:GetService("PathfindingService")

local AIPathService = {}

export type AIPathService = typeof(AIPathService)

export type AgentParams = {
	AgentRadius: number, -- Default: 2
	AgentHeight: number, -- Default: 5
	AgentCanJump: boolean, -- Default: true
	AgentCanClimb: boolean, -- Default: false
	WaypointSpacing: number, -- Default: 4
	AgentCollisionGroupName: string,
	-- Costs can be used with PathfindingModifiers
	Costs: {
		Bridge: number,
		Minefield: number,
	},
}

function AIPathService.CreatePath(
	_: AIPathService,
	start: Vector3,
	goal: Vector3,
	agentParams: AgentParams?
): { Path: Path, Waypoints: { PathWaypoint } }
	local path = PathfindingService:CreatePath(agentParams)

	path:ComputeAsync(start, goal)

	if path.Status ~= Enum.PathStatus.Success then
		warn("Failed to ComputeAsync. Status:", path.Status.Name)
	end

	local data = {
		Path = path,
		Waypoints = path:GetWaypoints(),
	}

	return data
end

function AIPathService.CastPath(start: Vector3, goal: Vector3, agentParams: AgentParams) end

return AIPathService
