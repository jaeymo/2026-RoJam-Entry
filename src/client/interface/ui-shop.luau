--!nocheck

--// Services //--
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Modules //--
local Classy = require(ReplicatedStorage.packages.classy)
local Config = require(ReplicatedStorage.shared.configs.configuration)
local Jaegar = require(ReplicatedStorage.packages.jaegar):Client()
local Viewer = require(ReplicatedStorage.packages.viewer)
local Network = Jaegar:GetNetwork()

--// Variables //--
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("ui-assets"):WaitForChild("Main")

local ShopFrame = Main:WaitForChild("Shop") :: Frame

local ListFrame = ShopFrame:WaitForChild("List") :: Frame

local Template = ListFrame:WaitForChild("Template") :: Frame

local Money = ShopFrame:WaitForChild("Money") :: TextLabel

local CurrentConnections = {}

--// Main Code //--
local UiShop = {}

local function ClearShop()
	for _, Connection in CurrentConnections do
		Connection:Disconnect()
	end

	table.clear(CurrentConnections)

	for _, Object in ListFrame:GetChildren() do
		if Object:IsA("Frame") and Object ~= Template then
			Object:Destroy()
		end
	end
end

local function UpdateShopAfford()
	local Currency = Player:GetAttribute("Currency") or 0

	for Item, Data in Config.Shop do
		local Frame = ListFrame:FindFirstChild(Item)
		if not Frame then
			continue
		end

		local Name = Frame:FindFirstChild("Name") :: TextLabel
		local Icon = Frame:FindFirstChild("Icon") :: ImageLabel

		local CanAfford = Currency >= (Data.Price or 0)

		if CanAfford then
			Icon.ImageColor3 = Color3.fromRGB(0, 255, 0)
			Name.TextColor3 = Color3.fromRGB(0, 255, 0)
		else
			Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			Name.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

local function GenerateShop()
	ClearShop()

	for Item, Data in Config.Shop do
		local NewTemplate = Template:Clone()
		NewTemplate.Name = Item
		NewTemplate.Parent = ListFrame

		local Icon = NewTemplate:WaitForChild("Icon")
		local Name = NewTemplate:WaitForChild("Name")
		local Price = NewTemplate:WaitForChild("Price")
		local Button = NewTemplate:WaitForChild("TextButton")

		Icon.Image = Data.Icon
		Name.Text = Item
		Price.Text = tostring(Data.Price)

		NewTemplate.Visible = true

		UpdateShopAfford()

		local Connection = Button.MouseButton1Click:Connect(function()
			local Success = Network:SendServer("trade", Item)

			if Success then
				print(`bought: {Item}`)
			else
				warn("failed")
			end
		end)

		table.insert(CurrentConnections, Connection)
	end
end

local function SetupPrompt(NPC: Instance)
	local HumanoidRootPart = NPC:WaitForChild("HumanoidRootPart", 10) or NPC.PrimaryPart
	if not HumanoidRootPart then
		return
	end

	local Prompt = Instance.new("ProximityPrompt")
	Prompt.Name = "ShopkeeperPrompt"
	Prompt.ActionText = "Trade"
	Prompt.RequiresLineOfSight = false
	Prompt.ClickablePrompt = false
	Prompt.Parent = HumanoidRootPart
end

ProximityPromptService.PromptTriggered:Connect(function(Prompt: ProximityPrompt, _: Player)
	if Prompt.Name ~= "ShopkeeperPrompt" then
		return
	end

	ShopFrame.Visible = not ShopFrame.Visible

	if ShopFrame.Visible then
		UserInputService.MouseIconEnabled = true
		GenerateShop()
	else
		UserInputService.MouseIconEnabled = false
	end
end)

Viewer.WatchAttribute(Player, "Currency", function(NewValue)
	Money.Text = `Deutsche: {tostring(NewValue)}`

	UpdateShopAfford()
end)

Classy.create("Shopkeeper", function(NPC: Instance)
	task.spawn(function()
		SetupPrompt(NPC)
	end)

	return {
		Init = function() end,
		Destroy = function() end,
	}
end)

return UiShop
