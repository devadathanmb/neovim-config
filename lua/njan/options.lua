-- Allows neovim to access systemclipboard
vim.opt.clipboard = "unnamedplus"

-- No more annoying swap files
vim.opt.swapfile = false

-- Search options
vim.opt.ignorecase = true -- Ignore case while searching
vim.opt.smartcase = true -- Smart case searching

-- Don't display the cmd, why waste space 
vim.opt.cmdheight = 0

-- Indentation and line wrap
vim.opt.smartindent = true -- Make indentation smarter
vim.opt.wrap = false -- No line wrapping
vim.opt.expandtab = true -- Expand tab to spaces
vim.opt.tabstop = 2 -- 4 spaces for a tab
vim.opt.shiftwidth = 2 -- 4 spaces for each indentation

-- Line numbering : Hybrid numbering
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 4 -- Sets number col width to 2

-- Cursor line
vim.opt.cursorline = true -- Highlight the current line

-- Split options
vim.opt.splitbelow = true -- Force horizontal splits below
vim.opt.splitright = true -- Force vertical splits to right

-- Terminal gui colors to support more colors
vim.opt.termguicolors = true

-- Consider string-string as whole word
vim.opt.iskeyword:append("-")

-- Disbale showing messages below
vim.opt.showmode = false

-- Please don't hide hidden files
vim.g.nvim_tree_hide_dotfiles = 0

-- Disable autocommenting
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

-- Markdown conceal level
vim.cmd("augroup Markdown")
vim.cmd("autocmd!")
vim.cmd("autocmd FileType markdown setlocal conceallevel=2")
vim.cmd("augroup END")

-- Get rid of that goddman ~
vim.opt.fillchars = { eob = " " }

-- No more semantic highlighting
--[[ for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do ]]
--[[   vim.api.nvim_set_hl(0, group, {}) ]]
--[[ end ]]
