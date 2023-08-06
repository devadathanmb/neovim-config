local plugins = {
	{ "Mofiqul/vscode.nvim", opts = {} },
	{ "ThePrimeagen/harpoon" },
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
	},
	{ "lervag/vimtex" },
	{ "RRethy/vim-illuminate" },
}

return plugins
