local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
	vim.notify("Bufferline not loaded")
	return
end

-- Load when there's only more than one buffer
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter" }, {
	pattern = "*",
	group = vim.api.nvim_create_augroup("BufferLineLazyLoading", {}),
	callback = function()
		local count = #vim.fn.getbufinfo({ buflisted = 1 })
		if count >= 2 then
			bufferline.setup({})
		end
	end,
})
