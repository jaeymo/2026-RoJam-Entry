--!strict
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local GenerationConfig = require(script["generation-config"])
local GenerationFactory = require(script["generation-factory"])
local GenerationTypes = require(script.types)
local SignalRegistry = require(ServerScriptService["signal-registry"])

local WORLD_ORIGIN = CFrame.new(GenerationConfig.worldOrigin)

local ROOM_TYPE = {
	NORMAL = "normal",

	SAFEZONE_START = "safezoneStart",
	SAFEZONE = "safezone",
	SAFEZONE_EXIT = "safezoneExit",
}

local SAFEZONE_ROOM_TYPES = {
	[ROOM_TYPE.SAFEZONE_START] = true,
	[ROOM_TYPE.SAFEZONE] = true,
	[ROOM_TYPE.SAFEZONE_EXIT] = true,
}

local GenerationService = {
	currentRoomGenerationIndex = 0,
	roomInitializedIndex = 0,
	unloadedRoomCount = 0,

	roomPlan = {} :: {
		[number]: {
			phase: string,
			roomType: string,
		},
	},

	roomChain = {} :: {
		[number]: Room,
	},

	loadedSections = {} :: {
		[number]: {
			safezoneStartIndex: number,
			startIndex: number,
			endIndex: number,
		},
	},
}

export type GenerationService = typeof(GenerationService)
export type Room = GenerationTypes.Room

local function getNodesFromRoom(roomModel: Room): (BasePart, BasePart)
	return roomModel.Nodes.Room:FindFirstChild("Enter") :: BasePart,
		roomModel.Nodes.Room:FindFirstChild("Exit") :: BasePart
end

local function isSectionBoundary(roomType: string): boolean
	return roomType == ROOM_TYPE.SAFEZONE_EXIT
end

local function appendSafezoneSequence(
	roomPlan: { [number]: { phase: string, roomType: string } },
	index: number,
	phase: string
): number
	roomPlan[index] = {
		phase = phase,
		roomType = ROOM_TYPE.SAFEZONE_START,
	}

	index += 1

	roomPlan[index] = {
		phase = phase,
		roomType = ROOM_TYPE.SAFEZONE,
	}

	index += 1

	roomPlan[index] = {
		phase = phase,
		roomType = ROOM_TYPE.SAFEZONE_EXIT,
	}

	index += 1

	return index
end

local function buildFinitePhase(
	roomPlan: { [number]: { phase: string, roomType: string } },
	startIndex: number,
	phaseData
): number
	local index = startIndex

	local roomsRemaining = phaseData.length
	local safezoneConfig = phaseData.safezones

	local distanceUntilSafezone = math.random(safezoneConfig.minSpacing, safezoneConfig.maxSpacing)

	while roomsRemaining > 0 do
		roomPlan[index] = {
			phase = phaseData.name,
			roomType = ROOM_TYPE.NORMAL,
		}

		index += 1
		roomsRemaining -= 1
		distanceUntilSafezone -= 1

		local shouldGenerateSafezone = safezoneConfig.enabled and roomsRemaining > 0 and distanceUntilSafezone <= 0
		if shouldGenerateSafezone then
			index = appendSafezoneSequence(roomPlan, index, phaseData.name)

			distanceUntilSafezone = math.random(safezoneConfig.minSpacing, safezoneConfig.maxSpacing)
		end
	end

	if safezoneConfig.enabled and safezoneConfig.guaranteedAtEnd then
		index = appendSafezoneSequence(roomPlan, index, phaseData.name)
	end

	return index
end

local function buildInitialRoomPlan(): {
	[number]: {
		phase: string,
		roomType: string,
	},
}
	local roomPlan = {}
	local index = 1

	index = buildFinitePhase(roomPlan, index, GenerationConfig.gamePhases.early)
	index = buildFinitePhase(roomPlan, index, GenerationConfig.gamePhases.middle)

	return roomPlan
end

function GenerationService.initiateGenerationProcess(self: GenerationService)
	self.roomPlan = buildInitialRoomPlan()

	self:extendLateGame(GenerationConfig.lateGameGeneration.maxRooms)

	self.roomChain = {}
	self:generateNextSection()
	self:initializeNext()
end

function GenerationService.generateNext(self: GenerationService)
	local nextRoomIndex = self.currentRoomGenerationIndex + 1

	if nextRoomIndex + 25 > #self.roomPlan then
		self:extendLateGame(nextRoomIndex + 100)
	end

	local roomData = self.roomPlan[nextRoomIndex]
	if not roomData then
		error(`[{script.Name}] Missing room plan entry`)
	end

	local newRoom: Room?

	if SAFEZONE_ROOM_TYPES[roomData.roomType] then
		newRoom = GenerationFactory:getSafezoneRoom(roomData.phase, roomData.roomType)
	else
		newRoom = GenerationFactory:getRandomRoomFromPhase(roomData.phase)
	end

	if not newRoom then
		error(`[{script.Name}] Failed to generate room "{roomData.phase}" "{roomData.roomType}"`)
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
	newRoom:SetAttribute("GUID", HttpService:GenerateGUID(false))
	newRoom.Parent = GenerationConfig.parent

	self.currentRoomGenerationIndex = nextRoomIndex
	self.roomChain[#self.roomChain + 1] = newRoom

	SignalRegistry.roomSpawned:Fire(newRoom)
end

function GenerationService.initializeNext(self: GenerationService)
	self.roomInitializedIndex += 1

	local roomModel = self.roomChain[self.roomInitializedIndex]
	if not roomModel then
		warn(`[{script.Name}] Failed to get room for: {self.roomInitializedIndex}, `, self.roomChain)
		return
	end

	SignalRegistry.roomInitialized:Fire(roomModel)
end

function GenerationService.generateNextSection(self: GenerationService)
	local sectionStartIndex = self.currentRoomGenerationIndex + 1
	local sectionEndIndex = sectionStartIndex

	local safezoneStartIndex = -1

	while true do
		local nextIndex = self.currentRoomGenerationIndex + 1
		local roomData = self.roomPlan[nextIndex]

		if not roomData then
			break
		end

		self:generateNext()

		sectionEndIndex = self.currentRoomGenerationIndex

		if roomData.roomType == ROOM_TYPE.SAFEZONE_START then
			safezoneStartIndex = self.currentRoomGenerationIndex
		end

		if isSectionBoundary(roomData.roomType) then
			break
		end
	end

	self.loadedSections[#self.loadedSections + 1] = {
		startIndex = sectionStartIndex,
		endIndex = sectionEndIndex,
		safezoneStartIndex = safezoneStartIndex,
	}
end

function GenerationService.extendLateGame(self: GenerationService, targetRoomCount: number)
	local latePhase = GenerationConfig.gamePhases.late
	local safezoneConfig = latePhase.safezones

	local index = #self.roomPlan + 1

	local distanceUntilSafezone = math.random(safezoneConfig.minSpacing, safezoneConfig.maxSpacing)

	while #self.roomPlan < targetRoomCount do
		self.roomPlan[index] = {
			phase = "late",
			roomType = ROOM_TYPE.NORMAL,
		}

		index += 1
		distanceUntilSafezone -= 1

		local shouldGenerateSafezone = safezoneConfig.enabled and distanceUntilSafezone <= 0

		if shouldGenerateSafezone then
			index = appendSafezoneSequence(self.roomPlan, index, "late")

			distanceUntilSafezone = math.random(safezoneConfig.minSpacing, safezoneConfig.maxSpacing)
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

function GenerationService.jaegarInit(self: GenerationService)
	SignalRegistry.roomExitReached:Connect(function()
		self:initializeNext()

		local nextRoom = self.roomChain[self.roomInitializedIndex]
		if nextRoom then
			SignalRegistry.roomEntered:Fire(nextRoom)
		end
	end)

	task.delay(3.25, function()
		self:initiateGenerationProcess()
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
