--!strict
local InfectedConfig = {
    [0] = {
        StaminaMultiplier = 1,
        DamageMultiplier = 1,
    },
    [1] = {
        StaminaMultiplier = 0.6,
        DamageMultiplier = 1.2,
    },
    [2] = {
        StaminaMultiplier = 0.4,
        DamageMultiplier = 1.5,
    },
}

export type InfectedConfig = typeof(InfectedConfig)

return InfectedConfig