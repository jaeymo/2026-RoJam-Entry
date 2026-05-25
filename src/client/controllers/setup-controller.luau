--!strict
local StarterGui = game:GetService("StarterGui")

local SetupController = {}

export type SetupController = typeof(SetupController)

local function disableResetButton()
	task.spawn(function()
		while task.wait(0.1) do
			local success = pcall(function()
				StarterGui:SetCore("ResetButtonCallback", false)
			end)

			if success then
				break
			end
		end
	end)
end

function SetupController.jaegarInit(_: SetupController)
	disableResetButton()
end

return SetupController
