--// Services //--
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

--// Datastore //--
local Leaderboard = DataStoreService:GetDataStore("GlobalLeaderboards")

--// Variables //--
local DefaultStats = {
	["Tolls"] = 0,
	["Cured"] = 0,
	["Currency"] = 0,
}

--// Main Code //--
local StatsHandler = {}

local function SetupStats(Player)
	for Stat, Value in DefaultStats do
		Player:SetAttribute(Stat, Value)
	end
end

local function UpdateLeaderboard(Player: Player, Tolls: number, Cures: number, CurrencyEarned: number)
	local UserId = tostring(Player.UserId)

	local Success, Error = pcall(function()
		Leaderboard:UpdateAsync(UserId, function(OldData)
			OldData = OldData
				or {
					Name = Player.Name,
					TotalTolls = 0,
					TotalCures = 0,
					TotalCurrency = 0,
				}

			OldData.Name = Player.Name
			OldData.TotalTolls += Tolls
			OldData.TotalCures += Cures
			OldData.TotalCurrency += CurrencyEarned

			return OldData
		end)
	end)

	if not Success then
		warn("[Stats Handler] Failed to update leaderboard:", Error)
	end
end

function StatsHandler:ModifyStat(Player: Player, Stat: string, Amount: number)
	if not Player or not Player:GetAttribute(Stat) then
		return
	end

	Amount = math.floor(Amount)

	local Current = Player:GetAttribute(Stat) or 0
	local NewValue = math.max(0, Current + Amount)

	Player:SetAttribute(Stat, NewValue)
end

function StatsHandler:ClaimStats(Player: Player)
	if not Player then
		return
	end

	local Tolls = Player:GetAttribute("Tolls") or 0
	local Cures = Player:GetAttribute("Cured") or 0

	local CurrencyEarned = math.floor((Tolls * 0.5) + (Cures * 0.5))

	self:ModifyStat(Player, "Currency", CurrencyEarned)

	if not RunService:IsStudio() then
		UpdateLeaderboard(Player, Tolls, Cures, CurrencyEarned)
	end

	Player:SetAttribute("Tolls", 0)
	Player:SetAttribute("Cured", 0)

	return CurrencyEarned
end

if RunService:IsStudio() then
	ProximityPromptService.PromptTriggered:Connect(function(ProximityPrompt: ProximityPrompt, Player: Player)
		if ProximityPrompt.ActionText == "Cured" or ProximityPrompt.ActionText == "Tolls" then
			StatsHandler:ModifyStat(Player, ProximityPrompt.ActionText, 1)
		else
			StatsHandler:ClaimStats(Player)
		end
	end)
end

Players.PlayerAdded:Connect(SetupStats)

return StatsHandler
