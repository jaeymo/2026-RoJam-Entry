--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterState = require(ReplicatedStorage.client.domain.character["character-state"])
local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()

local ViewmodelController
local HitboxController

local camera = workspace.CurrentCamera
local network = Jaegar:GetNetwork()

local Scepter = {}

export type Scepter = typeof(Scepter)

function Scepter.equip(self: Scepter)
	-- print(self)
end

function Scepter.unequip(self: Scepter)
	-- print(self)
end

local lastSelected: string? = nil
local randomAttackId: string? = nil

local function getRandomAttackName(): string
	local names = {
		"Batter",
		"Bonk",
		"Poke",
		"Peck",
	}

	if lastSelected then
		local index = table.find(names, lastSelected)
		if index then
			table.remove(names, index)
		end
	end

	local selection = names[math.random(1, #names)]
	lastSelected = selection

	return selection
end

function Scepter.primary(self: Scepter)
	local scopedId = HttpService:GenerateGUID(false)
	randomAttackId = scopedId

	task.delay(3, function()
		if randomAttackId == scopedId then
			lastSelected = nil
		end
	end)

	local randomAttackName = getRandomAttackName()
	self:attack(randomAttackName)
end

function Scepter.attack(_: Scepter, attackName: string)
	local track = ViewmodelController.animationObject:GetTrack(`ViewModel{attackName}`)
	if not track then
		warn(`[{script.Name}] No track with the name: ViewModel{attackName}`)
		return
	end

	ViewmodelController.animationObject:Play(`ViewModel{attackName}`, false)

	local root = CharacterState:getRoot() :: BasePart
	local cf = root.CFrame + (camera.CFrame.LookVector * 5)

	local hits = HitboxController.CheckForHumanoids(cf, Vector3.one * 5)
	if not next(hits) then
		return
	end

	network:SendServer("processScepterHits", hits)
end

function Scepter.jaegarInit(_: Scepter)
	ViewmodelController = require(ReplicatedStorage.client.controllers["viewmodel-controller"])
	HitboxController = require(ReplicatedStorage.client.controllers["hitbox-controller"])
end

return Scepter
