--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.packages.signal)

export type Signal<T...> = Signal.Signal<T...>

local SIGNAL_REGISTRY = {
	spawnNextRoomTouched = Signal.new() :: Signal<>,
	roomSpawned = Signal.new() :: Signal<Model>,
}

return table.freeze(SIGNAL_REGISTRY) :: typeof(SIGNAL_REGISTRY)
