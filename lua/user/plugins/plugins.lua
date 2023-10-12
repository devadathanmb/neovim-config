local plugins = {
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
	{ "RRethy/vim-illuminate" },
}

return plugins
