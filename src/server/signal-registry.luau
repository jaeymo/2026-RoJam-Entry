--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.packages.signal)

export type Signal<T...> = Signal.Signal<T...>

local SIGNAL_REGISTRY = {
	conversationStarted = Signal.new() :: Signal<Model>, -- entityModel
	conversationEnded = Signal.new() :: Signal<Model>,

	mutationFinished = Signal.new() :: Signal<string, Model>, -- mutationName, entityModel
	roomSpawned = Signal.new() :: Signal<Model>,
	roomInitialized = Signal.new() :: Signal<Model>,
	roomEntered = Signal.new() :: Signal<Model>,
	roomExitReached = Signal.new() :: Signal<>,
	hitEntity = Signal.new() :: Signal<Model, number, string>,
	playerSlept = Signal.new() :: Signal<>,
}

return table.freeze(SIGNAL_REGISTRY) :: typeof(SIGNAL_REGISTRY)
