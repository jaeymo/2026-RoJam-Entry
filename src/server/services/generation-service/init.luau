--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local GenerationConfig = require(script.config)
local GenerationFactory = require(script.factory)
local GenerationTypes = require(script.types)
local SignalRegistry = require(ServerScriptService["signal-registry"])

local GenerationService = {
	roomChain = {} :: {
		[number]: Room, -- the index of the loaded room = its room model
	},
}

local WORLD_ORIGIN = CFrame.new(GenerationConfig.worldOrigin)

export type GenerationService = typeof(GenerationService)

export type Room = GenerationTypes.Room

local function getNodesFromRoom(roomModel: Room): (BasePart, BasePart)
	return roomModel.Nodes.Room:FindFirstChild("Enter") :: BasePart,
		roomModel.Nodes.Room:FindFirstChild("Exit") :: BasePart
end

function GenerationService.initiateGenerationProcess(self: GenerationService)
	self.roomChain = {}
	self:generateNext()
end

function GenerationService.generateNext(self: GenerationService)
	local newRoom = GenerationFactory:getNewRoomAsset("room-template")
	if not newRoom then
		error(`[{script.Name}] Game broke get jaeymo and call him a stupid dumb idiot.`)
	end

	local startNode, _ = getNodesFromRoom(newRoom)
	local spawnCFrame = WORLD_ORIGIN

	if next(self.roomChain) then
		local lastRoom = self.roomChain[#self.roomChain]
		local _, exitNode = getNodesFromRoom(lastRoom)
		spawnCFrame = exitNode.CFrame
	end

	newRoom.PrimaryPart = startNode
	newRoom:PivotTo(spawnCFrame)
	newRoom.Parent = GenerationConfig.parent

	self.roomChain[#self.roomChain + 1] = newRoom
end

function GenerationService.unload(self: GenerationService)
	local firstRoom = table.remove(self.roomChain, 1)

	if firstRoom then
		firstRoom:Destroy()
	end
end

function GenerationService.jaegarInit(self: GenerationService)
	self:initiateGenerationProcess()

	SignalRegistry.spawnNextRoomTouched:Connect(function()
		self:generateNext()
	end)
end

return GenerationService
