local colors = {
	pink = "#c586c0",
	red = "#c72e0f",
	orange = "#cc6633",
	green = "#16825d",
	blue = "#007acc",
	violet = "#646695",
	purple = "#68217a",
	white = "#ffffff",
	gray = "#1e1e1e", -- 15% lighter than black
	black = "#1e1e1e",
}

colors.black = "NONE"
colors.gray = "NONE"

return {
	normal = {
		a = { fg = colors.white, bg = colors.blue },
		b = { fg = colors.white, bg = colors.gray },
		c = { fg = colors.white, bg = colors.black },
	},
	insert = {
		a = { fg = colors.white, bg = colors.orange },
	},
	visual = {
		a = { fg = colors.white, bg = colors.purple },
	},
	replace = {
		a = { fg = colors.white, bg = colors.pink },
	},
	command = {
		a = { fg = colors.white, bg = colors.green },
	},
	terminal = {
		a = { fg = colors.white, bg = colors.violet },
	},
	pending = {
		a = { fg = colors.white, bg = colors.red },
	},
	inactive = {
		a = { fg = colors.white, bg = colors.black },
	},
}
