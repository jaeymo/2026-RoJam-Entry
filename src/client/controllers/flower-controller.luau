--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolTipController = require(ReplicatedStorage.client.controllers["tool-tip-controller"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local FlowerController = {}

export type FlowerController = typeof(FlowerController)

function FlowerController.jaegarInit(self: FlowerController)
	local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()

	Viewer.WatchAttribute(char, "Infected", function(color: Color3?)
		for _, v in CollectionService:GetTagged("Flower") do
			if not color then
				ToolTipController:handleToolTip(v, "basicFlower")
				continue
			end

			if v:GetAttribute("Color") == color then
				ToolTipController:handleToolTip(v, "goodFlower")
			else
				ToolTipController:handleToolTip(v, "badFlower")
			end
		end
	end)
end

return FlowerController
