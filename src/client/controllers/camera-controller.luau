--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraShaker = require(ReplicatedStorage.packages["camera-shaker"])

local camera = workspace.CurrentCamera

local CameraController = {
	shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value + 1, function(shakeCFrame: CFrame)
		camera.CFrame *= shakeCFrame
	end),
}

CameraController.shaker:Start()

export type CameraController = typeof(CameraController)

return CameraController
