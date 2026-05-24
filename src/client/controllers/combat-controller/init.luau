--!strict

--[[
	this module might get cooked ngl, not sure if it needs to exist
	-- jaeymo!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalRegistry = require(ReplicatedStorage.client["client-signal-registry"])

local CombatController = {
	currentlyHeldItemName = nil :: string?,
}

export type CombatController = typeof(CombatController)

-- scepter, clothes, flintAndSteel (COMBAT)
-- garlic, emerald, incense (TREATMENT)
-- scalpel for bloodletting

-- function CombatController.m1(self: CombatController)
-- 	if not self.currentlyHeldItemName then
-- 		return
-- 	end

-- 	print(self.currentlyHeldItemName)
-- end

function CombatController.jaegarInit(self: CombatController)
	SignalRegistry.itemEquipped:Connect(function(name: string)
		self.currentlyHeldItemName = name
	end)

	-- SignalRegistry.itemPrimary:Connect(function(name: string)
	-- 	print(name)
	-- end)

	SignalRegistry.itemUnequipped:Connect(function()
		self.currentlyHeldItemName = nil
	end)
end

return CombatController
