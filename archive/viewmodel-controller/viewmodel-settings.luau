--!strict
local VIEWMODEL_SETTINGS = {
	-- general
	scale = 0.3,
	occlusionFadeDuration = 0.2,

	-- roll
	maxRollAngle = 2.5,
	rollSpeed = 13,
	rollDamping = 0.8,

	-- sway
	yawMaxAngle = 3.5,
	yawSensitivity = 0.0008,
	pitchMaxAngle = 3,
	pitchSensitivity = 0.004,
	pitchSpeed = 14,
	pitchDamping = 0.6,
	yawSpeed = 14,
	yawDamping = 0.6,

	-- jump
	invertJumpSettings = true,
	jumpVerticalSpeed = 8,
	jumpVerticalDamping = 0.8,
	jumpVerticalImpulse = 0.25,
	jumpHorizontalSpeed = 1,
	jumpHorizontalDamping = 0.85,
	jumpHorizontalImpulse = 0.0001,
	jumpRandomDirectionMin = 0.1,
	jumpRandomDirectionMax = 0.2,

	-- bobble
	stepIntervalBase = 0.65,
	stepIntervalSpeedReduction = 0.04,
	impactDuration = 0.12,
	reboundEnd = 0.32,
	settleEnd = 0.55,
	reboundHeight = 0.16,
	horizontalAmplitude = 0.016,
	verticalAmplitude = 0.165,
	initialBobProgress = 0.08,
	bobbleSpeedNormalization = 16,
	moveDirectionThreshold = 0.01,
	movementSpeedThreshold = 0.1,
	bobbleVerticalSpeed = 6,
	bobbleVerticalDamping = 0.5,
	bobbleHorizontalSpeed = 4,
	bobbleHorizontalDamping = 0.8,
	bobbleLateralCycleDivisor = 2,
}

return table.freeze(VIEWMODEL_SETTINGS) :: typeof(VIEWMODEL_SETTINGS)
