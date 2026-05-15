--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)
local Janitor = require(ReplicatedStorage.packages.janitor)

local PlayerComponent = {}
PlayerComponent.__index = PlayerComponent

export type PlayerComponent = typeof(setmetatable(
	{} :: {
		instance: Player,
		characterJanitor: Janitor.Janitor,
		janitor: Classy.Janitor,
	},
	PlayerComponent
))

function PlayerComponent.new(player: Instance, janitor: Classy.Janitor): PlayerComponent
	local characterJanitor = Janitor.new()
	janitor:Add(characterJanitor)

	return setmetatable({
		instance = player :: Player,
		janitor = janitor,
		characterJanitor = characterJanitor,
	}, PlayerComponent)
end

function PlayerComponent.init(self: PlayerComponent)
	self:watchCharacter()
end

function PlayerComponent.watchCharacter(self: PlayerComponent)
	local container = workspace:WaitForChild("runtime"):WaitForChild("players")

	local function handleCharacter(character: Model)
		character:AddTag("Character")

		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = "PlayerCharacter"
			end
		end

		self.characterJanitor:Add(character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = "PlayerCharacter"
			end
		end))

		character.Parent = container
	end

	if self.instance.Character then
		handleCharacter(self.instance.Character)
	end

	self.instance.CharacterAdded:Connect(function(character: Model)
		handleCharacter(character)
	end)

	self.instance.CharacterRemoving:Connect(function(_: Model)
		self.characterJanitor:Cleanup()
	end)
end

PlayerComponent.classy = Classy.create("Player", PlayerComponent, {
	ClassNames = { "Player" },
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("Player", PlayerComponent.classy)

return PlayerComponent
