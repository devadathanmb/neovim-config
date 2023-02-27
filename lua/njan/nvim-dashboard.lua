local dashboard = require("dashboard")

dashboard.setup({
	theme = "doom",
	config = {
		header = {
			"",
			"      ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
			"      ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
			"      ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
			"      ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
			"      ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
			"      ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
			"                                                            ",
			"                                                            ",
		},

		center = {
			{ icon = "  ", desc = "Find files", key = "f", action = "Telescope find_files" },
			{ icon = "  ", desc = "New file", key = "n", action = "enew" },
			{ icon = "  ", desc = "Recent files", key = "r", action = "Telescope oldfiles" },
			{ icon = "  ", desc = "File browser", key = "b", action = "Telescope file_browser" },
			{ icon = "  ", desc = "Open nvim config", key = "c", action = "e ~/.config/nvim/" },
			{ icon = "  ", desc = "Open dotfiles", key = "d", action = "e ~/dotfiles/" },
			{ icon = "  ", desc = "Quit", key = "q", action = "q" },
		},
		footer = { "⚡ Neovim ⚡" },
	},
})
