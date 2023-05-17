local status_ok, indent_blankline = pcall(require, "indent_blankline")
if not status_ok then
	vim.notify("Indent blankline not installed")
	return
end

vim.opt.list = true

indent_blankline.setup({
	show_current_context = true,
	use_treesitter = true,
	show_trailing_blankline_indent = false,
	show_first_indent_level = true,
	char = "▏",
	context_char = "▏",
	buftype_exclude = { "terminal", "nofile" },
	filetype_exclude = {
		"help",
		"startify",
		"dashboard",
		"lazy",
		"neogitstatus",
		"NvimTree",
		"Trouble",
		"text",
	},
})
