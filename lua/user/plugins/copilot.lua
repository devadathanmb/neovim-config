local M = {
	"zbirenbaum/copilot.lua",
	event = "InsertEnter",
}

function M.config()
	local copilot = require("copilot")
	copilot.setup({
		filetypes = {
			markdown = false, -- overrides default
			java = false,
			c = false,
			javascript = true,
			python = true,
			sh = function()
				if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env.*") then
					-- disable for .env files
					return false
				end
				return true
			end,
			["*"] = false, -- disable for all other filetypes and ignore default `filetypes`
		},
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 75,
			keymap = {
				accept = "<M-S-L>",
				accept_word = false,
				accept_line = false,
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-]>",
			},
		},
	})
end

return M
