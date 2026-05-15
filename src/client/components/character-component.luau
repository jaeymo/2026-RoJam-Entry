--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)
local Viewer = require(ReplicatedStorage.packages.viewer)

local CharacterComponent = {}
CharacterComponent.__index = CharacterComponent

export type CharacterComponent = typeof(setmetatable(
	{} :: {
		instance: Instance,
		root: Part,
		humanoid: Humanoid,
		janitor: Classy.Janitor,
	},
	CharacterComponent
))

function CharacterComponent.new(instance: Instance, janitor: Classy.Janitor): CharacterComponent
	return setmetatable({
		instance = instance,
		root = instance:WaitForChild("HumanoidRootPart") :: Part,
		humanoid = instance:WaitForChild("Humanoid") :: Humanoid,
		janitor = janitor,
	}, CharacterComponent) :: CharacterComponent
end

function CharacterComponent.init(self: CharacterComponent)
	self:_disableHumanoidStates()
	self:_destroyRootSounds()
end

function CharacterComponent._destroyRootSounds(self: CharacterComponent)
	self.janitor:Add(Viewer.WatchDescendants(self.root, function(sound: Instance)
		if not sound:IsA("Sound") then
			return
		end

		sound:Destroy()
	end))
end

function CharacterComponent._disableHumanoidStates(self: CharacterComponent)
	local humanoid = self.humanoid
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
end

CharacterComponent.classy = Classy.create("Character", CharacterComponent, {
	NamingConvention = {
		Init = "init",
		Destroy = "destroy",
	},
})

Classy.registerGlobal("Character", CharacterComponent.classy)

return CharacterComponent
