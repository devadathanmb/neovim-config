-- This is the colorscheme name
local colorscheme = "vscode"
--[[]]
--[[ require(colorscheme).setup({ ]]
--[[ 	transparent_background = false, ]]
--[[ 	color_overrides = { ]]
--[[ 		mocha = { ]]
--[[ 			base = "#11111B", ]]
--[[ 			mantle = "#1E1E2E", ]]
--[[ 		}, ]]
--[[ 	}, ]]
--[[ }) ]]

-- Protected call to load colorscheme
local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
	vim.notify("colorscheme " .. colorscheme .. " not found!")
	return
end
