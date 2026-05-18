--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local GenerationConfig = require(script["generation-config"])
local GenerationFactory = require(script["generation-factory"])
local GenerationTypes = require(script.types)
local SignalRegistry = require(ServerScriptService["signal-registry"])

local GenerationService = {
	currentPhase = "Early" :: GamePhase,
	currentRoomGenerationIndex = 0,
	currentSafezone = nil :: Folder?,

	roomChain = {} :: {
		[number]: Room, -- the index of the loaded room = its room model
	},

	phaseMap = {} :: {
		[number]: string,
	},
}

local WORLD_ORIGIN = CFrame.new(GenerationConfig.worldOrigin)

export type GamePhase = "Early" | "Middle" | "Late"

export type GenerationService = typeof(GenerationService)

export type Room = GenerationTypes.Room

local function getNodesFromRoom(roomModel: Room): (BasePart, BasePart)
	return roomModel.Nodes.Room:FindFirstChild("Enter") :: BasePart,
		roomModel.Nodes.Room:FindFirstChild("Exit") :: BasePart
end

local SAFEZONE_PHASES = {
	["safezoneStart"] = true,
	["safezone"] = true,
	["safezoneExit"] = true,
} :: { [string]: true }

local SAFEZONE_SEQUENCE = {
	"safezoneStart",
	"safezone",
	"safezoneExit",
} :: { string }

local function getSafezoneTierFromIndex(phaseMap: { [number]: string }, currentIndex: number): string
	for i = currentIndex, 1, -1 do
		local phase = phaseMap[i]

		if phase == "early" or phase == "middle" or phase == "late" then
			return phase
		end
	end

	error(`[{script.Name}] Failed to resolve safezone tier`)
end

local function buildPhaseTable(phases: { [string]: number }): { [number]: string }
	local phaseTable = {}

	local orderedPhases = {
		{ name = "early", length = phases.early },
		{ name = "middle", length = phases.middle },
		{ name = "late", length = phases.late },
	}

	local round = 1

	for _, phaseData in orderedPhases do
		for _ = 1, phaseData.length do
			phaseTable[round] = phaseData.name
			round += 1
		end

		if phaseData.name ~= "late" then
			for _, safezonePhase in SAFEZONE_SEQUENCE do
				phaseTable[round] = safezonePhase
				round += 1
			end
		end
	end

	return phaseTable
end

function GenerationService.initiateGenerationProcess(self: GenerationService)
	self.phaseMap = buildPhaseTable(GenerationConfig.gamePhases)

	-- this works. dw, this is getting smited i just thought it was a funny bandaid fix
	for i = 0, 500 do
		self.phaseMap[#self.phaseMap + i - 1] = "late"
	end

	self.roomChain = {}
	self:generateNext()

	-- while task.wait(0.2) do
	-- 	self:generateNext()
	-- end
end

function GenerationService.generateNext(self: GenerationService)
	local nextRoomIndex = self.currentRoomGenerationIndex + 1
	local selectedPhase = self.phaseMap[nextRoomIndex]

	if not selectedPhase then
		warn(`[{script.Name}] No phase found for room index {nextRoomIndex}`)
		return
	end

	local newRoom: Room?

	if SAFEZONE_PHASES[selectedPhase] then
		local safezoneTier = getSafezoneTierFromIndex(self.phaseMap, nextRoomIndex)

		newRoom = GenerationFactory:getSafezoneRoom(safezoneTier, selectedPhase)
	else
		newRoom = GenerationFactory:getRandomRoomFromPhase(selectedPhase)
	end

	if not newRoom then
		error(`[{script.Name}] Failed to generate room for phase "{selectedPhase}"`)
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

	self.currentRoomGenerationIndex = nextRoomIndex
	self.roomChain[#self.roomChain + 1] = newRoom

	SignalRegistry.roomSpawned:Fire(newRoom)
end

-- function GenerationService.generateNext(self: GenerationService)
-- 	-- local shouldNextRoomBeSafezone = false

-- 	-- for _, v in self.phaseMap do
-- 	-- 	shouldNextRoomBeSafezone = v == self.currentRoomGenerationIndex + 1
-- 	-- 	if shouldNextRoomBeSafezone then
-- 	-- 		self.currentPhase = getNextPhase(self.currentPhase)
-- 	-- 		print("BREAKNIG")
-- 	-- 		break
-- 	-- 	end
-- 	-- end

-- 	-- local newRoom = nil :: Room?
-- 	-- newRoom = shouldNextRoomBeSafezone and GenerationFactory:getRandomRoomFromPhase("safezone")
-- 	-- 	or GenerationFactory:getRandomRoomFromPhase(self.currentPhase:lower())

-- 	-- if not newRoom then
-- 	-- 	error(`[{script.Name}] Game broke get jaeymo and call him a stupid dumb idiot.`)
-- 	-- end

-- 	-- local startNode, _ = getNodesFromRoom(newRoom)
-- 	-- local spawnCFrame = WORLD_ORIGIN

-- 	-- if next(self.roomChain) then
-- 	-- 	local lastRoom = self.roomChain[#self.roomChain]
-- 	-- 	local _, exitNode = getNodesFromRoom(lastRoom)
-- 	-- 	spawnCFrame = exitNode.CFrame
-- 	-- end

-- 	-- newRoom.PrimaryPart = startNode
-- 	-- newRoom:PivotTo(spawnCFrame)
-- 	-- newRoom.Parent = GenerationConfig.parent

-- 	-- self.currentRoomGenerationIndex += 1
-- 	-- self.roomChain[#self.roomChain + 1] = newRoom
-- 	-- SignalRegistry.roomSpawned:Fire(newRoom)

-- 	-- print(self)
-- end

function GenerationService.unload(self: GenerationService)
	local firstRoom = table.remove(self.roomChain, 1)

	if firstRoom then
		firstRoom:Destroy()
	end
end

function GenerationService.jaegarInit(self: GenerationService)
	task.delay(2, function()
		self:initiateGenerationProcess()

		SignalRegistry.spawnNextRoomTouched:Connect(function()
			self:generateNext()
		end)
	end)
end

return GenerationService
