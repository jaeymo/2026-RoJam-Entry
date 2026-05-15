local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PACKETS = require(ReplicatedStorage.shared.packets)

local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local Network = Jaegar:GetNetwork()

print(`[SomeGameName] This game was built on the Jaegar framework [1.6.1]`)

Network:Inject(PACKETS)

print(`[SomeGameName] Network loaded...`)

Jaegar:Start({ ServerScriptService, ReplicatedStorage.shared })
