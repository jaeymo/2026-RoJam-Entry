--!strict
local Lucky = {}

export type Lucky = typeof(Lucky)

export type WeightedItem = {
	Name: string,
	Weight: number,
}

function Lucky.roll(_: Lucky, chance: number): boolean
	return math.random() <= chance
end

function Lucky.chooseWeighted<T>(_: Lucky, items: { T & WeightedItem }): T?
	local totalWeight = 0

	for _, item in items do
		totalWeight += item.Weight
	end

	if totalWeight <= 0 then
		warn("[Lucky] Total weight was <= 0")
		return nil
	end

	local roll = math.random() * totalWeight
	local current = 0

	for _, item in items do
		current += item.Weight

		if roll <= current then
			return item
		end
	end

	return nil
end

return table.freeze(Lucky)
