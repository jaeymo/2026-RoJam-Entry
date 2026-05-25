--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.packages.packet)

local ANY = Packet.Any
local COLOR3 = Packet.Color3
local STRING = Packet.String
local BOOLEAN = Packet.Boolean8
local INSTANCE = Packet.Instance
local ENUM_ITEM = Packet.EnumItem
local CFRAME = Packet.CFrameF32U16
local BRICK_COLOR = Packet.BrickColor
local COLOR_SEQUENCE = Packet.ColorSequence

local U4 = Packet.NumberU4 -- 15
local U8 = Packet.NumberU8 -- 255
local U16 = Packet.NumberU16 -- 65,535
local U24 = Packet.NumberU24 -- 16,777,215
local U32 = Packet.NumberU32 -- 4,294,967,295

local F16 = Packet.NumberF16 -- 3 decimal digits
local F24 = Packet.NumberF24 -- 7 decimal digits
local F32 = Packet.NumberF32 -- 7 decimal digits
local F64 = Packet.NumberF64 -- 15 decimal digits

local VECTOR3_F24 = Packet.Vector3F24
local VECTOR3_F32 = Packet.Vector3F32

local PACKETS = {
	playerSlept = Packet.new("playerSlept"),

	spawnEnemyHitbox = Packet.new("spawnEnemyHitbox", CFRAME, VECTOR3_F24),

	startDialogueConversation = Packet.new("startDialogueConversation", INSTANCE),
	endDialogueConversation = Packet.new("endDialogueConversation", INSTANCE),
}

return table.freeze(PACKETS) :: typeof(PACKETS)
