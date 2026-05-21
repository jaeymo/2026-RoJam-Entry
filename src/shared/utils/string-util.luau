--!strict
local StringUtil = {}

export type StringUtil = typeof(StringUtil)

function StringUtil.kebabToCamel(_: StringUtil, str: string): string
	local result = str:gsub("%-(%a)", function(Character)
		return Character:upper()
	end)

	return result
end

function StringUtil.kebabToPascal(_: StringUtil, str: string): string
	str = str:gsub("%-(%a)", function(Character)
		return Character:upper()
	end)

	return str:sub(1, 1):upper() .. str:sub(2)
end

return StringUtil
