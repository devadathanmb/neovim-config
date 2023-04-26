local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- Markdown preview toggle binding
keymap("n", "<C-m>", ":MarkdownPreviewToggle<cr>", opts)
