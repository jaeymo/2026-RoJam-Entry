--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local interface = ReplicatedStorage.client.interface

local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local UiMasking = require(interface["ui-masking"])

local network = Jaegar:GetNetwork()

local SleepController = {}

export type SleepController = typeof(SleepController)

function SleepController.sleep(self: SleepController)
	UiMasking:mask(TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)).Completed:Wait()
	network:SendServer("playerSlept")

	task.wait(2)

	UiMasking:unmask(TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
end

function SleepController.jaegarInit(self: SleepController)
	network:OnClient("playerSlept", function()
		self:sleep()
	end)
end

return SleepController
