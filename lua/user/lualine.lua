local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	vim.notify("Error setting up lualine")
	return
end

local hide_in_width = function()
	return vim.fn.winwidth(0) > 80
end

local diagnostics = {
	"diagnostics",
	sources = { "nvim_diagnostic" },
	sections = { "error", "warn" },
	symbols = { error = " ", warn = " " },
	colored = false,
	update_in_insert = false,
	always_visible = true,
}

local diff = {
	"diff",
	colored = false,
	symbols = { added = " ", modified = " ", removed = " " }, -- changes diff symbols
	cond = hide_in_width,
}

local filetype = {
	"filetype",
	icons_enabled = false,
	icon = nil,
}

local copilot = function()
	local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
	if #buf_clients == 0 then
		return "LSP Inactive"
	end

	local buf_ft = vim.bo.filetype
	local buf_client_names = {}
	local copilot_active = false

	-- add client
	for _, client in pairs(buf_clients) do
		if client.name ~= "null-ls" and client.name ~= "copilot" then
			table.insert(buf_client_names, client.name)
		end

		if client.name == "copilot" then
			copilot_active = true
		end
	end

	if copilot_active then
		return " "
	end
	return ""
end

local branch = {
	"branch",
	icons_enabled = true,
	icon = "",
}

local location = {
	"location",
	padding = 0,
}

lualine.setup({
	options = {
		icons_enabled = true,
		theme = "vscode",
		--[[ theme = "tokyonight", ]]
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "alpha", "dashboard" },
		},
		always_divide_middle = true,
		globalstatus = true,
	},
	sections = {
		lualine_a = { branch },
		lualine_b = {},
		lualine_c = {
			{ "filename", file_status = true, path = 0 },
			{ copilot },
		},
		lualine_x = { diff, filetype },
		lualine_y = { "require'lsp-status'.status()" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	extensions = {},
})
