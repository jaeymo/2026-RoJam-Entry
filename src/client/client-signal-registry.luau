--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.packages.signal)

export type Signal<T...> = Signal.Signal<T...>

local CLIENT_SIGNAL_REGISTRY = {
	jumped = Signal.new() :: Signal<>,
	landed = Signal.new() :: Signal<number>, -- the amount of time in the air
}

return table.freeze(CLIENT_SIGNAL_REGISTRY) :: typeof(CLIENT_SIGNAL_REGISTRY)
