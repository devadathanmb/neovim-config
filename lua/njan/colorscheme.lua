-- This is the colorscheme name
local colorscheme = "catppuccin"

require(colorscheme).setup({
	transparent_background = false,
})

-- Protected call to load colorscheme
local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
	vim.notify("colorscheme " .. colorscheme .. " not found!")
	return
end
