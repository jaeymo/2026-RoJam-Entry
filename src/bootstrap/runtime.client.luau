local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PACKETS = require(ReplicatedStorage.shared.packets)

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local Network = Jaegar:GetNetwork()

Network:Inject(PACKETS)
Jaegar:Start({ ReplicatedStorage.client, ReplicatedStorage.shared })
