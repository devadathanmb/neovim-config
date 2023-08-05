local M = {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
}

function M.confg()
	require("nvim-autopairs").setup({})

	local cmp = require("cmp")
	local cmp_autopairs = require("nvim-autopairs.completion.cmp")
	cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({ map_char = { tex = "" } }))
end

return M
