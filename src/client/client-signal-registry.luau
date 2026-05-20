--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.packages.signal)

export type Signal<T...> = Signal.Signal<T...>

local CLIENT_SIGNAL_REGISTRY = {
	jumped = Signal.new() :: Signal<Model>,
	landed = Signal.new() :: Signal<Model, number>, -- the amount of time in the air

	plrHit = Signal.new() :: Signal<any>,
}

return table.freeze(CLIENT_SIGNAL_REGISTRY) :: typeof(CLIENT_SIGNAL_REGISTRY)
