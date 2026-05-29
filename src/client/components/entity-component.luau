--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classy = require(ReplicatedStorage.packages.classy)
local ToolTipConfig = require(ReplicatedStorage.shared.configs["tool-tip-config"])
local ToolTipController = require(ReplicatedStorage.client.controllers["tool-tip-controller"])

local EntityComponent = {}
EntityComponent.__index = EntityComponent

export type EntityComponent = typeof(setmetatable(
	{} :: {
		instance: Instance,
		janitor: Classy.Janitor,
	},
	EntityComponent
))

function EntityComponent.new(instance: Instance, janitor: Classy.Janitor): EntityComponent
	return setmetatable({
		instance = instance,
		janitor = janitor,
	}, EntityComponent)
end

function EntityComponent.Init(self: EntityComponent)
	self.janitor:Add(self.instance:GetAttributeChangedSignal("DeathTollCollected"):Connect(function()
		ToolTipController:handleToolTip(self.instance, "deathTollCollected")
	end))
end

EntityComponent.classy = Classy.create("Entity", EntityComponent, {})

return EntityComponent
