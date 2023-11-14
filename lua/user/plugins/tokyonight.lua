local M = {
	"folke/tokyonight.nvim",
	lazy = false,
	enabled = false,
	priority = 1000,
	opts = {},
}

function M.config()
	require("tokyonight").setup({
		style = "night",
		transparent = true,
	})
	vim.cmd([[colorscheme tokyonight]])
end

return M
