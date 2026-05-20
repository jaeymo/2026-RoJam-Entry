--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local configs = ReplicatedStorage.shared.configs

local entityConfigs = {
	Aggressive = require(configs["aggressive-ai-config"]),
	Wandering = require(configs["wandering-ai-config"]),
	Passive = require(configs["wandering-ai-config"]),
} :: { [string]: any }

local HealthService = require(ServerScriptService.services["health-service"])
local Viewer = require(ReplicatedStorage.packages.viewer)

local InitializeEntity = {}

export type InitializeEntity = typeof(InitializeEntity)

function InitializeEntity.jaegarInit(_: InitializeEntity)
	Viewer.WatchTag("Entity", false, function(instance: Instance)
		local tags = instance:GetTags()

		for name, config in entityConfigs do
			if not table.find(tags, `{name}AI`) then
				continue
			end

			local health, maxHealth = config.Vitals.Health, config.Vitals.MaxHealth
			HealthService:initEntity(instance :: Model, maxHealth)
			HealthService:setHealth(instance :: Model, health)
			break
		end
	end)
end

return InitializeEntity
