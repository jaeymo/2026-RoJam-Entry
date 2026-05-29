--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolTipConfig = require(ReplicatedStorage.shared.configs["tool-tip-config"])

local ToolTipController = {}

export type ToolTipController = typeof(ToolTipController)

function ToolTipController.handleToolTip(self: ToolTipController, parent: Instance, configName: string)
	if ToolTipConfig[configName] then
		local color = (ToolTipConfig[configName].color :: Color3) or Color3.fromRGB(255, 255, 255)
		self:_setupTooltip(parent, ToolTipConfig[configName].text, color)
	else
		warn(`[{script.Name}] aw hell nah: {configName}`)
	end
end

function ToolTipController._setupTooltip(_self: ToolTipController, parent: Instance, text: string, color: Color3?)
	for _, v in parent:GetDescendants() do
		if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
			if v:HasTag("IgnoreToolTip") then
				continue
			end

			v:SetAttribute("ToolTip", text)
			v:SetAttribute("ToolTipColor", color)
		end
	end
end

return ToolTipController
