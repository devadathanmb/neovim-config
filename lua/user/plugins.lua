local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

local plugins = {
	"nvim-lua/popup.nvim",
	"nvim-lua/plenary.nvim",
	"windwp/nvim-autopairs",
	"numToStr/Comment.nvim",
	"kyazdani42/nvim-web-devicons",
	"nvim-tree/nvim-tree.lua",
	"akinsho/bufferline.nvim",
	"moll/vim-bbye",
	"akinsho/toggleterm.nvim",
	"Mofiqul/vscode.nvim",
	{
		"devadathanmb/arctic.nvim",
		branch = "v2",
		dependencies = { "rktjmp/lush.nvim" },
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "kyazdani42/nvim-web-devicons", lazy = true },
	},
	"hrsh7th/nvim-cmp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"saadparwaiz1/cmp_luasnip",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-nvim-lua",
	"L3MON4D3/LuaSnip",
	"rafamadriz/friendly-snippets",
	"neovim/nvim-lspconfig",
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"jose-elias-alvarez/null-ls.nvim",
	"mfussenegger/nvim-jdtls",
	"nvim-telescope/telescope.nvim",
	"nvim-telescope/telescope-media-files.nvim",
	"nvim-telescope/telescope-file-browser.nvim",
	"NvChad/nvim-colorizer.lua",
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},
	"nvim-treesitter/playground",
	"p00f/nvim-ts-rainbow",
	"JoosepAlviste/nvim-ts-context-commentstring",
	"karb94/neoscroll.nvim",
	"lukas-reineke/indent-blankline.nvim",
	{
		"SmiteshP/nvim-navic",
		dependencies = "neovim/nvim-lspconfig",
	},
	"utilyre/barbecue.nvim",
	"folke/which-key.nvim",
	"lewis6991/gitsigns.nvim",
	"goolord/alpha-nvim",
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
	},
	{
		"iamcco/markdown-preview.nvim",
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	"itchyny/calendar.vim",
	{
		"kylechui/nvim-surround",
		version = "*", --  for stability; omit to use `main` branch for the latest features
	},
	"windwp/nvim-ts-autotag",
	"ThePrimeagen/harpoon",
	"lervag/vimtex",
	"RRethy/vim-illuminate",
	{
		"jinh0/eyeliner.nvim",
	},
}

vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
require("lazy").setup(plugins, {})
