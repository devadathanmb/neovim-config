-- vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = require("user.utils.neo-tree-helper").open_neo_tree })
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = require("user.utils.nvim-tree-helper").open_nvim_tree })

-- Load bufferline when there's only more than one buffer
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter", "TermOpen" }, {
  pattern = "*",
  group = vim.api.nvim_create_augroup("BufferLineLazyLoading", {}),
  callback = function()
    local count = #vim.fn.getbufinfo({ buflisted = 1 })
    if count >= 2 then
      require("bufferline").setup({})
    end
  end,
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
