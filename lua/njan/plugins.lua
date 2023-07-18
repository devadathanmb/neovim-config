local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- Install your plugins here
return packer.startup(function(use)
	-- My plugins here
	use("wbthomason/packer.nvim") -- Have packer manage itself
	use("nvim-lua/popup.nvim") -- An implementation of the Popup API from vim in Neovim
	use("nvim-lua/plenary.nvim") -- Useful lua functions used ny lots of plugins
	use("windwp/nvim-autopairs") -- Autopairs, integrates with both cmp and treesitter
	use("numToStr/Comment.nvim") -- Easily comment stuff
	use("kyazdani42/nvim-web-devicons")
	use({ "nvim-tree/nvim-tree.lua" })
	use("akinsho/bufferline.nvim")
	use("moll/vim-bbye")
	use("akinsho/toggleterm.nvim")

	-- Colorscheme plugin
	use("Mofiqul/vscode.nvim")
	use({
		"devadathanmb/arctic.nvim",
		branch = "v2",
		requires = { "rktjmp/lush.nvim" },
	})

	-- Lua line plugin
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
	})

	-- cmp plugins
	use("hrsh7th/nvim-cmp") -- The completion plugin
	use("hrsh7th/cmp-buffer") -- buffer completions
	use("hrsh7th/cmp-path") -- path completions
	use("hrsh7th/cmp-cmdline") -- cmdline completions
	use("saadparwaiz1/cmp_luasnip") -- snippet completions
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-nvim-lua")

	-- snippets
	use("L3MON4D3/LuaSnip") --snippet engine
	use("rafamadriz/friendly-snippets") -- a bunch of snippets to use

	-- LSP
	use("neovim/nvim-lspconfig") -- enable LSP
	use("williamboman/mason.nvim") -- simple to use language server installer
	use("williamboman/mason-lspconfig.nvim") -- simple to use language server installer
	use("jose-elias-alvarez/null-ls.nvim") -- for formatters and linters

	-- Java
	use("mfussenegger/nvim-jdtls") -- jdtls for java development

	-- Flutter development stuff
	--[[ use({ "akinsho/flutter-tools.nvim", requires = "nvim-lua/plenary.nvim" }) ]]

	-- Telescope
	use("nvim-telescope/telescope.nvim")
	use("nvim-telescope/telescope-media-files.nvim")
	use("nvim-telescope/telescope-file-browser.nvim") -- Telescope file browser plugin

	-- Colorizer
	use("norcalli/nvim-colorizer.lua")

	-- Treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})
	use("nvim-treesitter/playground")
	use("p00f/nvim-ts-rainbow")
	use("JoosepAlviste/nvim-ts-context-commentstring")

	-- Neoscroll : For smooth scrolling
	use("karb94/neoscroll.nvim")

	-- Indeent-blankline : Adds lines for indentation like in vscode
	use("lukas-reineke/indent-blankline.nvim")

	-- nvim-navic : To customize winbar
	use({
		"SmiteshP/nvim-navic",
		requires = "neovim/nvim-lspconfig",
	})
	-- Barbecue.vim provides vscode like winbar using nvim-navic
	use({
		"utilyre/barbecue.nvim",
	})

	-- Impatient : Load stuff faster
	use("lewis6991/impatient.nvim")

	-- Which key : Don't forget your mappings again
	use("folke/which-key.nvim")

	-- Git signs
	use("lewis6991/gitsigns.nvim")

	-- Alpha : Startup dashboar
	use({
		"goolord/alpha-nvim",
	})

	-- Copilot stuff
	--[[ use({ ]]
	--[[ 	"zbirenbaum/copilot-cmp", ]]
	--[[ 	after = { "copilot.lua" }, ]]
	--[[ 	config = function() ]]
	--[[ 		require("copilot_cmp").setup() ]]
	--[[ 	end, ]]
	--[[ }) ]]

	use({
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					debounce = 75,
					keymap = {
						accept = "<M-l>",
						accept_word = false,
						accept_line = false,
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-]>",
					},
				},
			})
		end,
	})

	-- Markdown preview
	use({
		"iamcco/markdown-preview.nvim",
		run = "cd app && npm install",
		setup = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	})

	-- Vim calendar
	use("itchyny/calendar.vim")

	-- Nvim-surround
	use({
		"kylechui/nvim-surround",
		tag = "*", -- Use for stability; omit to use `main` branch for the latest features
	})

	-- Autotag
	use("windwp/nvim-ts-autotag")

	-- Harpoon nvim
	use("ThePrimeagen/harpoon")

	-- Tex stuff
	use("lervag/vimtex")

	-- Illuminate : Highlight word under cursor
	use("RRethy/vim-illuminate")

	-- Eyeliner
	use({
		"jinh0/eyeliner.nvim",
		config = function()
			require("eyeliner").setup({
				highlight_on_key = true,
				dim = true,
			})
		end,
	})

	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
