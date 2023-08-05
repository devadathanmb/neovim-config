local status_ok, barbecue = pcall(require, "barbecue")
if not status_ok then
	vim.notify("Barbecue not installed or error loading barbecue")
	return
end

barbecue.setup({
	exclude_filetypes = { "netrw", "toggleterm" },
	show_dirname = false,
	show_basename = true,
	show_modified = true,

	---Whether context text should follow its icon's color.
	---
	---@type boolean
	context_follow_icon_color = false,

	symbols = {
		---Modification indicator.
		---
		---@type string
		modified = " ",

		---Truncation indicator.
		---
		---@type string
		ellipsis = "…",

		---Entry separator.
		---
		---@type string
		separator = "",
	},
	theme = {
		modified = { fg = "#808080" },
	},
})
