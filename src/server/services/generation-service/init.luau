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

	unloadedRoomCount = 0,

	roomChain = {} :: {
		[number]: Room, -- the index of the loaded room = its room model
	},

	phaseMap = {} :: {
		[number]: string,
	},

	loadedSections = {} :: {
		[number]: {
			safezoneStartIndex: number,
			startIndex: number,
			endIndex: number,
		},
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

local function isSectionBoundary(phase: string): boolean
	return phase == "safezoneExit"
end

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

local function appendSafezone(phaseTable: { [number]: string }, index: number): number
	for _, safezonePhase in SAFEZONE_SEQUENCE do
		phaseTable[index] = safezonePhase
		index += 1
	end

	return index
end

local function generateLateGame(phaseTable: { [number]: string })
	local index = #phaseTable + 1
	local maxRooms = GenerationConfig.lateGameGeneration.maxRooms

	while index <= maxRooms do
		local stretchLength = math.random(
			GenerationConfig.lateGameGeneration.minLateStretch,
			GenerationConfig.lateGameGeneration.maxLateStretch
		)

		for _ = 1, stretchLength do
			if index > maxRooms then
				break
			end

			phaseTable[index] = "late"
			index += 1
		end

		if index <= maxRooms then
			index = appendSafezone(phaseTable, index)
		end
	end
end

function GenerationService.initiateGenerationProcess(self: GenerationService)
	self.phaseMap = buildPhaseTable(GenerationConfig.gamePhases)
	generateLateGame(self.phaseMap)

	self.roomChain = {}
	self:generateNextSection()
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

function GenerationService.generateNextSection(self: GenerationService)
	local sectionStartIndex = self.currentRoomGenerationIndex + 1
	local sectionEndIndex = sectionStartIndex
	local safezoneStartIndex = -1

	while true do
		local nextIndex = self.currentRoomGenerationIndex + 1
		local phase = self.phaseMap[nextIndex]

		if not phase then
			break
		end

		self:generateNext()

		sectionEndIndex = self.currentRoomGenerationIndex

		if phase == "safezoneStart" then
			safezoneStartIndex = self.currentRoomGenerationIndex
		end

		if isSectionBoundary(phase) then
			break
		end
	end

	self.loadedSections[#self.loadedSections + 1] = {
		startIndex = sectionStartIndex,
		endIndex = sectionEndIndex,
		safezoneStartIndex = safezoneStartIndex,
	}
end

function GenerationService.unloadLastSection(self: GenerationService)
	if #self.loadedSections <= 2 then
		return
	end

	local section = table.remove(self.loadedSections, 1)

	if not section then
		return
	end

	local roomCount = section.endIndex - section.startIndex + 1

	for _ = 1, roomCount do
		local room = table.remove(self.roomChain, 1)

		if room then
			room:Destroy()
		end
	end
end

function GenerationService.unloadAllBefore(self: GenerationService, generationIndex: number)
	local roomsToRemove = generationIndex - self.unloadedRoomCount - 1

	for _ = 1, roomsToRemove do
		local room = table.remove(self.roomChain, 1)

		if room then
			room:Destroy()
			self.unloadedRoomCount += 1
		end
	end
end

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

	SignalRegistry.playerSlept:Connect(function()
		local currentSection = self.loadedSections[1]

		if currentSection then
			self:unloadAllBefore(currentSection.safezoneStartIndex)
		end

		self:generateNextSection()

		table.remove(self.loadedSections, 1)
	end)
end

return GenerationService
