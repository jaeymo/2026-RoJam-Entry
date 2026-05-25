--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NpcEmployer = {}

local JobConfig = require(ReplicatedStorage.shared.configs["job-config"])
local Lucky = require("./lucky")

export type NpcEmployer = typeof(NpcEmployer)

function NpcEmployer.getAJob(_: NpcEmployer)
	local jobResult = Lucky:chooseWeighted(JobConfig) :: JobConfig.JobConfigEntry
	local jobWeapon = Lucky:chooseWeighted(jobResult.Weapons :: any)

	return {
		Name = jobResult.Name,
		Weapon = jobWeapon.Name,
		HealthMultiplier = jobResult.Vitals.HealthMultiplier,
		DamageMultiplier = jobResult.Vitals.DamageMultiplier,
	}
end

return NpcEmployer
