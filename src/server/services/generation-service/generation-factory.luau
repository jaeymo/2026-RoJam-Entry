--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GenerationTypes = require(script.Parent.types)

local mapAssets = ReplicatedStorage.assets.map

local GenerationFactory = {}

export type GenerationFactory = typeof(GenerationFactory)

local function getPhaseFolder(phase: string): Folder?
	local phaseFolder = mapAssets:FindFirstChild(phase) :: Folder?
	if not phaseFolder then
		warn(`[{script.Name}] Failed to find phase folder for: {phase}`)
		return
	end

	return phaseFolder
end

local function handleNewRoom(roomModel: Model): GenerationTypes.Room
	local room = roomModel:Clone()
	room:WaitForChild("Nodes"):WaitForChild("Room")

	return room :: GenerationTypes.Room
end

function GenerationFactory.getNewRoomAssetFrom(
	_: GenerationFactory,
	roomName: string,
	phase: string
): GenerationTypes.Room?
	local phaseFolder = getPhaseFolder(phase)
	if not phaseFolder then
		return
	end

	local room = phaseFolder:FindFirstChild(roomName)
	if not room then
		warn(`[{script.Name}] Failed to find map room by the name of: {roomName}`)
		return
	end

	if not room:IsA("Model") then
		warn(`[{script.Name}] Room is not a model: {room}`)
		return
	end

	return handleNewRoom(room)
end

function GenerationFactory.getRandomRoomFromPhase(_: GenerationFactory, phase: string): GenerationTypes.Room?
	local phaseFolder = getPhaseFolder(phase)
	if not phaseFolder then
		return
	end

	local room = phaseFolder:GetChildren()[math.random(1, #phaseFolder:GetChildren())] :: Instance?
	if not room then
		error(`[{script.Name}] Something wrong... get jaeymo`)
	end

	return handleNewRoom(room :: Model)
end

function GenerationFactory.getRandomSafezoneFolder(_: GenerationFactory): Folder?
	local safezoneFolder = getPhaseFolder("safezone")
	if not safezoneFolder then
		return
	end

	local safezones = safezoneFolder:GetChildren()

	local selectedSafezone = safezones[math.random(1, #safezones)]

	if not selectedSafezone then
		return
	end

	return selectedSafezone :: Folder
end

function GenerationFactory.getSafezoneRoom(_: GenerationFactory, tier: string, roomType: string): GenerationTypes.Room?
	local safezoneRoot = getPhaseFolder("safezone")

	if not safezoneRoot then
		return
	end

	local tierFolder = safezoneRoot:FindFirstChild(tier)

	if not tierFolder then
		warn(`[{script.Name}] Failed to find safezone tier: {tier}`)
		return
	end

	local room = tierFolder:FindFirstChild(roomType)

	if not room then
		warn(`[{script.Name}] Failed to find safezone room: {roomType}`)
		return
	end

	if not room:IsA("Model") then
		warn(`[{script.Name}] Safezone room is not model`)
		return
	end

	return handleNewRoom(room)
end

return GenerationFactory
