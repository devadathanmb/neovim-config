local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Word wrap navigation
keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)

-- Remap cutting using d
--[[ keymap("n", "<leader>d", "d", opts) ]]
-- Put deleting using c and d to blackhole register
--[[ keymap("n", "d", "\"_d", opts) ]]
--[[ keymap("v", "d", "\"_d", opts) ]]
--[[ keymap("n", "c", "\"_c", opts) ]]
--[[ keymap("v", "c", "\"_c", opts) ]]
-- Manage buffers
keymap("n", "<C-x>", ":bdelete<CR>", opts)
keymap("n", "<C-n>", ":enew<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Move buffers left or right using buffer line
keymap("n", "<C-M-i>", ":BufferLineMoveNext<CR>", opts)
keymap("n", "<C-M-u>", ":BufferLineMovePrev<CR>", opts)

-- Pin/Unpin a tab using in BufferLine
--[[ keymap("n", "<leader>p", ":BufferLineTogglePin<CR>", opts) ]]

-- Nvim Tree
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Terminal binds
keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Don't yank stuff that has been replaced
keymap("v", "p", '"_dP', opts)

-- Telescope keybindings
keymap(
  "n",
  "<leader>ff",
  "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false, no_ignore = true }))<cr>",
  opts
)
keymap("n", "<leader>fb", "<cmd>Telescope file_browser<cr>", opts)

-- Formatting keymap
keymap("n", "<leader>fr", "<cmd>lua vim.lsp.buf.format()<cr>", opts)

-- Markdown preview keymap
--[[ keymap("n", "<C-m>", ":MarkdownPreviewToggle<cr>", opts) ]]
-- Colorizer activate
keymap("n", "<C-c>", ":ColorizerAttachToBuffer<cr>", opts)

-- Cycle through completions in command mode using ctrl + j, k
keymap("c", "<C-j>", "<C-n>", opts)
keymap("c", "<C-k>", "<C-p>", opts)

-- Harpoon keymaps
keymap("n", "<leader>a", ":lua require('harpoon.mark').add_file()<cr>", opts)
keymap("n", "<C-e>", ":lua require('harpoon.ui').toggle_quick_menu()<cr>", opts)
keymap("n", "<C-;>", ":lua require('harpoon.ui').nav_file(1)<cr>", opts)
keymap("n", "<C-.>", ":lua require('harpoon.ui').nav_file(2)<cr>", opts)
keymap("n", "<C-,>", ":lua require('harpoon.ui').nav_file(3)<cr>", opts)
keymap("n", "<leader>n", ":lua require('harpoon.mark').nav_next()<cr>", opts)
keymap("n", "<leader>p", ":lua require('harpoon.mark').nav_prev()<cr>", opts)
