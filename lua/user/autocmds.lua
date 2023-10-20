vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = require("user.utils.neo-tree-helper").open_neo_tree })

-- Load bufferline when there's only more than one buffer
-- vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter" }, {
-- 	pattern = "*",
-- 	group = vim.api.nvim_create_augroup("BufferLineLazyLoading", {}),
-- 	callback = function()
-- 		local count = #vim.fn.getbufinfo({ buflisted = 1 })
-- 		if count >= 2 then
-- 			require("bufferline").setup({})
-- 		end
-- 	end,
-- })
