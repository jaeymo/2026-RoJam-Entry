--// Services //--
-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local RunService = game:GetService("RunService")
-- local TweenService = game:GetService("TweenService")
-- local UserInputService = game:GetService("UserInputService")

-- --// Modules //--
-- local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
-- local Network = Jaegar:GetNetwork()

-- --// Variables //--
-- local Player = Players.LocalPlayer
-- local PlayerGui = Player.PlayerGui

-- local Camera = workspace.CurrentCamera

-- local UiAssets = PlayerGui:WaitForChild("ui-assets")

-- local Main = UiAssets:WaitForChild("Main")
-- local Menu = UiAssets:WaitForChild("Menu")

-- local Black = Menu:WaitForChild("Black")

-- local PlayGui = Menu:WaitForChild("Play")
-- local PlayButton = PlayGui:WaitForChild("Main"):WaitForChild("TextButton")
-- local Active = PlayButton:WaitForChild("Active")

-- local LeaderboardGui = Menu:WaitForChild("Leaderboard")
-- local List = LeaderboardGui:WaitForChild("ScrollingFrame")
-- local Template = List:WaitForChild("Template")

-- local CameraPart = workspace:WaitForChild("Start"):WaitForChild("Scriptables"):WaitForChild("CameraPart")

-- --// Main Code //--
-- local PlayController = {}

-- local CameraOffsetX = 0
-- local CameraOffsetY = 0

-- local function SetupCamera()
-- 	Camera.CameraType = Enum.CameraType.Scriptable

-- 	RunService:BindToRenderStep("MenuCamera", Enum.RenderPriority.Camera.Value, function()
-- 		Main.Enabled = false

-- 		UserInputService.MouseIconEnabled = true

-- 		local ViewportSize = Camera.ViewportSize

-- 		local MouseX = (UserInputService:GetMouseLocation().X / ViewportSize.X) - 0.5
-- 		local MouseY = (UserInputService:GetMouseLocation().Y / ViewportSize.Y) - 0.5

-- 		CameraOffsetX = MouseX * 4
-- 		CameraOffsetY = MouseY * 2

-- 		local BaseCFrame = CameraPart.CFrame

-- 		local Offset = CFrame.Angles(math.rad(-CameraOffsetY), math.rad(-CameraOffsetX), 0)

-- 		Camera.CFrame = BaseCFrame * Offset
-- 	end)
-- end

-- local function StopMenuCamera()
-- 	RunService:UnbindFromRenderStep("MenuCamera")

-- 	local Character = Player.Character
-- 	if Character then
-- 		local Humanoid = Character:WaitForChild("Humanoid")

-- 		if Humanoid then
-- 			Camera.CameraSubject = Humanoid
-- 		end
-- 	end

-- 	Camera.CameraType = Enum.CameraType.Custom
-- end

-- local function SetupPlayButton()
-- 	Active.Visible = false

-- 	PlayButton.MouseEnter:Connect(function()
-- 		Active.Visible = true
-- 	end)

-- 	PlayButton.MouseLeave:Connect(function()
-- 		Active.Visible = false
-- 	end)

-- 	PlayButton.MouseButton1Click:Connect(function()
-- 		local Tween = TweenService:Create(
-- 			Black,
-- 			TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
-- 			{ BackgroundTransparency = 0 }
-- 		)
-- 		Tween:Play()
-- 		Tween.Completed:Wait()

-- 		task.wait(0.5)

-- 		StopMenuCamera()

-- 		Main.Enabled = true
-- 		UserInputService.MouseIconEnabled = false

-- 		--// start the game

-- 		TweenService
-- 			:Create(
-- 				Black,
-- 				TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
-- 				{ BackgroundTransparency = 1 }
-- 			)
-- 			:Play()

-- 		task.wait(5)

-- 		Menu.Enabled = false
-- 	end)
-- end

-- local function SetupLeaderboard()
-- 	local LeaderboardData = Network:SendServer("getLeaderboard")
-- 	warn(LeaderboardData)

-- 	if typeof(LeaderboardData) ~= "table" then
-- 		return
-- 	end

-- 	local ValidPlayers = {}

-- 	for _, Data in LeaderboardData do
-- 		local Currency = Data.Total_Currency or 0
-- 		local Success = Data.Total_Cures_Success or 0
-- 		local Fail = Data.Total_Cures_Fail or 0

-- 		if (Currency + Success + Fail) > 0 then
-- 			table.insert(ValidPlayers, Data)
-- 		end
-- 	end

-- 	table.sort(ValidPlayers, function(A, B)
-- 		local AScore = (A.Total_Currency or 0) + (A.Total_Cures_Success or 0)
-- 		local BScore = (B.Total_Currency or 0) + (B.Total_Cures_Success or 0)

-- 		return AScore > BScore
-- 	end)

-- 	for Rank, Data in ValidPlayers do
-- 		if not LeaderboardGui.Enabled then
-- 			LeaderboardGui.Enabled = true
-- 		end

-- 		local NewTemplate = Template:Clone()
-- 		NewTemplate.Name = Data.Name
-- 		NewTemplate.Visible = true
-- 		NewTemplate.Parent = List

-- 		local Name = NewTemplate:WaitForChild("Username")
-- 		local Placement = NewTemplate:WaitForChild("Placement")
-- 		local Currency = NewTemplate:WaitForChild("Currency")
-- 		local Cures = NewTemplate:WaitForChild("Cures")
-- 		local Headshot = NewTemplate:WaitForChild("Headshot")

-- 		Name.Text = Data.Name
-- 		Placement.Text = `#{Rank}`

-- 		Currency.Text = `Total Currency: {tostring(Data.Total_Currency)}`

-- 		Cures.Text = `Cure Fail: {Data.Total_Cures_Fail} | Cure Success: {Data.Total_Cures_Success}`

-- 		local UserId = tonumber(Data.UserId)
-- 		if UserId then
-- 			local Success, Content = pcall(function()
-- 				return Players:GetUserThumbnailAsync(
-- 					UserId,
-- 					Enum.ThumbnailType.HeadShot,
-- 					Enum.ThumbnailSize.Size150x150
-- 				)
-- 			end)

-- 			if Success then
-- 				Headshot.Image = Content
-- 			end
-- 		end
-- 	end
-- end

-- SetupCamera()
-- SetupPlayButton()
-- SetupLeaderboard()

return {}
