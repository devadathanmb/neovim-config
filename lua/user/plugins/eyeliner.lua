local M = {
	"jinh0/eyeliner.nvim",
}

function M.config()
	require("eyeliner").setup({
		highlight_on_key = true, -- show highlights only after keypress
		dim = false, -- dim all other characters if set to true (recommended!)
	})
end

return M
