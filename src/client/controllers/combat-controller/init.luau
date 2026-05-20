--!strict
local CombatController = {}

export type CombatController = typeof(CombatController)

function CombatController.jaegarInit(self: CombatController)
	print(self)
end

return CombatController
