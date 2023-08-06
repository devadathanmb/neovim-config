local plugins = {
	{ "Mofiqul/vscode.nvim", opts = {} },
	{
		"ThePrimeagen/harpoon",
		event = "VeryLazy",
	},
	{
		"iamcco/markdown-preview.nvim",
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	{ "windwp/nvim-ts-autotag" },
	{

		"itchyny/calendar.vim",
		event = "VeryLazy",
	},
	{
		"lervag/vimtex",
		ft = { "tex" },
	},
	{ "RRethy/vim-illuminate" },
}

return plugins
