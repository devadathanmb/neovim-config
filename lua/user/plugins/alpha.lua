-- originally authored by @AdamWhittingham
local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = {
		{
			"nvim-tree/nvim-web-devicons",
			config = function()
				require("nvim-web-devicons").setup({
					override = {
						zsh = {
							icon = "",
							color = "#428850",
							cterm_color = "65",
							name = "Zsh",
						},
					},
					color_icons = true,
					default = true,
				})
			end,
		},
	},
}

function M.config()
	local alpha = require("alpha")

	local dashboard = require("alpha.themes.dashboard")

	-- Set header
	dashboard.section.header.val = {
		"                                                     ",
		"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
		"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
		"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
		"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
		"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
		"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
		"                                                     ",
	}

	-- Set menu
	dashboard.section.buttons.val = {
		dashboard.button("e", "  > New file", ":ene <BAR> startinsert <CR>"),
		dashboard.button("f", "󰩉  > Find file", ":cd $HOME | Telescope find_files<CR>"),
		dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
		dashboard.button(
			"c",
			"  > Open NVIM config",
			":lua vim.api.nvim_set_current_dir('~/.config/nvim') vim.cmd('edit ~/.config/nvim/init.lua') <CR>"
		),
		dashboard.button("u", "  > Update plugins", "<cmd>Lazy update<CR>"),
		dashboard.button("q", "󰗼  > Quit NVIM", ":qa<CR>"),
	}

	-- Set footer
	local fortune = require("alpha.fortune")
	dashboard.section.footer.val = fortune()

	-- Send config to alpha
	alpha.setup(dashboard.opts)

	-- Disable folding on alpha buffer
	vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])
end

return M
