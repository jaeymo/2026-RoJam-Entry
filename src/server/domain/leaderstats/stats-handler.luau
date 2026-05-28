--// Services //--
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules //--
local Config = require(ReplicatedStorage.shared.configs.configuration)
local Jaegar = require(ReplicatedStorage.packages.jaegar):Server()
local Viewer = require(ReplicatedStorage.packages.viewer)
local Network = Jaegar:GetNetwork()

--// Datastore //--
local Leaderboard = DataStoreService:GetDataStore("GlobalLeaderboards")

--// Variables //--
local DefaultStats = {
	Tolls = 0,
	Currency = 0,

	Cured_Success = 0,
	Cured_Fail = 0,
}

--// Main Code //--
local StatsHandler = {}

local function SetupStats(Player)
	for Stat, Value in DefaultStats do
		Player:SetAttribute(Stat, Value)
	end

	local Character = Player.Character
	if not Character then
		return
	end

	Viewer.WatchAttribute(Character, "Health", function(NewValue)
		if NewValue <= 0 then
			local Tolls = Player:GetAttribute("Tolls") or 0

			local CureSuccess = Player:GetAttribute("Cured_Success") or 0
			local CureFail = Player:GetAttribute("Cured_Fail") or 0

			local UserId = tostring(Player.UserId)

			pcall(function()
				Leaderboard:UpdateAsync(UserId, function(OldData)
					OldData = OldData
						or {
							Name = Player.Name,
							UserId = Player.UserId,

							Total_Tolls = 0,
							Total_Cures_Success = 0,
							Total_Cures_Fail = 0,
							Total_Currency = 0,
						}

					OldData.Name = Player.Name

					OldData.Total_Tolls += Tolls
					OldData.Total_Cures_Success += CureSuccess
					OldData.Total_Cures_Fail += CureFail

					return OldData
				end)
			end)
		end
	end)
end

local function UpdateLeaderboard(
	Player: Player,
	Tolls: number,
	CureSuccess: number,
	CureFail: number,
	CurrencyEarned: number
)
	local UserId = tostring(Player.UserId)

	local Success, Error = pcall(function()
		Leaderboard:UpdateAsync(UserId, function(OldData)
			OldData = OldData
				or {
					Name = Player.Name,
					UserId = Player.UserId,

					Total_Tolls = 0,
					Total_Cures_Success = 0,
					Total_Cures_Fail = 0,
					Total_Currency = 0,
				}

			OldData.Name = Player.Name

			OldData.Total_Tolls += Tolls
			OldData.Total_Cures_Success += CureSuccess
			OldData.Total_Cures_Fail += CureFail
			OldData.Total_Currency += CurrencyEarned

			return OldData
		end)
	end)

	if not Success then
		warn("[Stats Handler] Failed to update leaderboard:", Error)
	end
end

function StatsHandler.ModifyStat(Player: Player, Stat: string, Amount: number)
	if not Player or not Player:GetAttribute(Stat) then
		return
	end

	Amount = math.floor(Amount)

	local Current = Player:GetAttribute(Stat) or 0
	local NewValue = math.max(0, Current + Amount)

	Player:SetAttribute(Stat, NewValue)
end

function StatsHandler.ClaimStats(Player: Player)
	if not Player then
		return
	end

	local Tolls = Player:GetAttribute("Tolls") or 0

	local CureSuccess = Player:GetAttribute("Cured_Success") or 0
	local CureFail = Player:GetAttribute("Cured_Fail") or 0

	local CurrencyEarned = math.floor((Tolls * 0.5) + (CureSuccess * 1) - (CureFail * 0.25))

	CurrencyEarned = math.max(0, CurrencyEarned)

	StatsHandler.ModifyStat(Player, "Currency", CurrencyEarned)

	UpdateLeaderboard(Player, Tolls, CureSuccess, CureFail, CurrencyEarned)

	Player:SetAttribute("Tolls", 0)
	Player:SetAttribute("Cured_Success", 0)
	Player:SetAttribute("Cured_Fail", 0)

	return CurrencyEarned
end

Players.PlayerAdded:Connect(SetupStats)

Network:OnInvoke("trade", function(Player: Player, Item: string)
	if typeof(Item) ~= "string" then
		return false
	end

	local FoundItem = Config.Shop[Item]
	if not FoundItem then
		return false
	end

	local Price = FoundItem.Price
	local Currency = Player:GetAttribute("Currency") or 0

	if Currency < Price then
		return false
	end

	Player:SetAttribute("Currency", Currency - Price)

	local CurrentAmount = Player:GetAttribute(Item) or 0
	Player:SetAttribute(Item, CurrentAmount + 1)

	return true
end)

Network:OnInvoke("getLeaderboard", function(_: Player)
	local Pages = Leaderboard:ListKeysAsync()

	local Data = {}

	while true do
		local CurrentPage = Pages:GetCurrentPage()

		for _, KeyInfo in CurrentPage do
			local Success, StoredData = pcall(function()
				return Leaderboard:GetAsync(KeyInfo.KeyName)
			end)

			if Success and StoredData then
				table.insert(Data, StoredData)
			end
		end

		if Pages.IsFinished then
			break
		end

		Pages:AdvanceToNextPageAsync()
	end

	return Data
end)

return StatsHandler
