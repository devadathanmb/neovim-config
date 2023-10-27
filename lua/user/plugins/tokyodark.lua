local M = {
	"tiagovla/tokyodark.nvim",
  enabled = false,
}

function M.config()
	local status_ok, tokyodark = pcall(require, "tokyodark")
	if not status_ok then
		return
	end
	local opts = {
		transparent_background = true, -- set background to transparent
		gamma = 1.00, -- adjust the brightness of the theme
		styles = {
			comments = { italic = true }, -- style for comments
			keywords = { italic = true }, -- style for keywords
			identifiers = { italic = true }, -- style for identifiers
			functions = {}, -- style for functions
			variables = {}, -- style for variables
		},
		custom_highlights = {} or function(highlights, palette)
			return {}
		end, -- extend highlights
		custom_palette = {} or function(palette)
			return {}
		end, -- extend palette
		terminal_colors = true, -- enable terminal colors
	}
	tokyodark.setup(opts)
	vim.cmd([[colorscheme tokyodark]])
end

return M
