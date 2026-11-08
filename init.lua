vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.autocmds")
vim.cmd.colorscheme("github_personal")
require("config.lazy")
require("config.keymaps")
require("config.bookmarks").setup()
