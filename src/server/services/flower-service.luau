--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Classy = require(ReplicatedStorage.packages.classy)
local FlowerConfig = require(ReplicatedStorage.shared.configs["flower-config"])
local Lucky = require(ReplicatedStorage.shared.utils.lucky)
local SignalRegistry = require(ServerScriptService["signal-registry"])
local PlayerHitController

local REVERSED_COLOR_MAP = {} :: { [string]: string } -- color to name

do
	for name: string, color: Color3 in FlowerConfig.colors :: any do
		REVERSED_COLOR_MAP[tostring(color)] = name
	end
end

local function initializeTemporaryPrompt(node: BasePart, color: string)
	if not RunService:IsStudio() then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Heal"
	prompt:SetAttribute("Color", color)
	prompt.Parent = node

	prompt:AddTag("FlowerPrompt")
end

local FlowerService = {}

export type FlowerService = typeof(FlowerService)

function FlowerService.generateFlowersIntoMap(self: FlowerService, nodesFromRoom: { BasePart })
	local currentInfectedColor = self:getPlayerInfectionColor()
	local weights = {} :: { { Name: string, Weight: number } }

	for colorName: any in FlowerConfig.colors do
		table.insert(weights, {
			Name = colorName,
			Weight = 1,
		})
	end

	if currentInfectedColor then
		local nameFromColor = REVERSED_COLOR_MAP[tostring(currentInfectedColor)]
		if not nameFromColor then
			warn(`[{script.Name}] Failed to convert color to string: {currentInfectedColor}`)
			return
		end

		local weightEntry

		for _, v in weights do
			if v.Name == nameFromColor then
				weightEntry = v
				break
			end
		end

		if not weightEntry then
			warn(`[{script.Name}] wtf gangy? {currentInfectedColor}: {nameFromColor}: `, weights)
			return
		end

		weightEntry.Weight += math.random(1, 3)
	end

	local amountNodes = #nodesFromRoom
	if amountNodes <= 0 then
		warn(`[{script.Name}] No flower nodes for room`)
		return
	end

	local amountFlowersToSpawn = FlowerConfig.getAmountFlowersToSpawn(amountNodes)

	for _ = 1, amountFlowersToSpawn do
		local randomIndex = math.random(1, #nodesFromRoom)
		local node = nodesFromRoom[randomIndex]
		node.Name = "LJHLJHSGJLHSJLH"

		local chosenColor = Lucky:chooseWeighted(weights :: any)
		initializeTemporaryPrompt(node, chosenColor.Name)

		table.remove(nodesFromRoom, randomIndex)
	end
end

function FlowerService.useFlower(self: FlowerService, flowerColor: string): boolean
	local player = Players:GetPlayers()[1]
	if not player then
		return false
	end
	local currentInfection = self:getPlayerInfectionColor()
	if not currentInfection then
		print("no use")
		return false
	end

	local currentFlowerName = REVERSED_COLOR_MAP[tostring(currentInfection)]
	if not currentFlowerName then
		print("no use")
		return false
	end

	if flowerColor ~= currentFlowerName then
		warn(`[{script.Name}] no use`)
		return false
	end

	PlayerHitController.Deinfect(player)
	return true
end

function FlowerService.getPlayerInfectionColor(_: FlowerService): Color3?
	local player = Players:GetPlayers()[1]
	if not player then
		warn(`[{script.Name}] Player does not exist`)
		return nil
	end

	return player:GetAttribute("Infected") :: Color3?
end

function FlowerService._handleSuccessfulFlower(self: FlowerService, player: Player, flower: Model)
	print("SUCCESSFUL FLOWER: ", flower)
	PlayerHitController.Deinfect(player)
	flower:Destroy()
end

function FlowerService._handleUnsuccessfulFlower(self: FlowerService, flower: Model)
	print("UNSUCCESSFUL FLOWER: ", flower)
	flower:Destroy()
end

function FlowerService.jaegarInit(self: FlowerService)
	PlayerHitController = require(ServerScriptService.domain.player["playerhit-controller"])

	SignalRegistry.roomInitialized:Connect(function(roomModel: Model)
		local nodes = {} :: { BasePart }

		for _, v in roomModel:GetDescendants() do
			if not v:HasTag("FlowerSpawnNode") then
				continue
			end

			table.insert(nodes, v :: BasePart)
		end

		self:generateFlowersIntoMap(nodes)
	end)

	Classy.create("FlowerPrompt", function(prompt: Instance, janitor)
		if prompt.Parent then
			(prompt.Parent :: BasePart).Transparency = 0
			(prompt.Parent :: BasePart).Color = FlowerConfig.colors[prompt:GetAttribute("Color")]
		end

		janitor:Add((prompt :: ProximityPrompt).Triggered:Connect(function(player: Player)
			local color = prompt:GetAttribute("Color") :: string
			local successful = self:useFlower(color)

			local model = prompt.Parent :: any
			if successful then
				self:_handleSuccessfulFlower(player, model)
			else
				self:_handleUnsuccessfulFlower(model)
			end
		end))

		return prompt
	end, {
		ClassNames = { "ProximityPrompt" },
	})
end

return FlowerService
