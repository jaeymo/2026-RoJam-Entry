local Roman = {}

local numberMap = {
	{ 1000, "M" },
	{ 900, "CM" },
	{ 500, "D" },
	{ 400, "CD" },
	{ 100, "C" },
	{ 90, "XC" },
	{ 50, "L" },
	{ 40, "XL" },
	{ 10, "X" },
	{ 9, "IX" },
	{ 5, "V" },
	{ 4, "IV" },
	{ 1, "I" },
}

function Roman.ToRoman(num)
	local result = ""

	for _, pair in ipairs(numberMap) do
		local value = pair[1]
		local symbol = pair[2]

		while num >= value do
			num -= value
			result ..= symbol
		end
	end

	return result
end

return Roman
