-- Nvim tree open file tree
local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	if not directory then
		return
	end

	-- change to the directory
	vim.cmd.cd(data.file)

	-- open the tree
	require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

-- Load bufferline when there's only more than one buffer
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter" }, {
	pattern = "*",
	group = vim.api.nvim_create_augroup("BufferLineLazyLoading", {}),
	callback = function()
		local count = #vim.fn.getbufinfo({ buflisted = 1 })
		if count >= 2 then
			require("bufferline").setup({})
		end
	end,
})


