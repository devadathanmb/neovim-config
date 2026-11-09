local opt = vim.opt

opt.clipboard = "unnamedplus"
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.statuscolumn = " %C%s %=%l   "
opt.termguicolors = true
opt.winborder = "rounded"
opt.background = "dark"
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.smartindent = true
opt.virtualedit = "block"
opt.jumpoptions = "view"
opt.smoothscroll = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "split"
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.mouse = "a"
opt.undofile = true
opt.confirm = true
opt.autoread = true
opt.updatetime = 300
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 10
opt.list = true
-- Matches VS Code `editor.renderWhitespace: "boundary"`: leading, trailing and
-- repeated spaces are drawn; single spaces between words are not.
opt.listchars = { tab = "→ ", lead = "·", trail = "·", multispace = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "\u{f078}", foldclose = "\u{f054}", foldsep = " " }
-- Tree-sitter folds; the expression returns 0 for buffers without a parser.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldtext = ""
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"
opt.laststatus = 3
opt.showmode = false
opt.shortmess:append("IcC")
-- Ftplugins reset formatoptions per buffer, so `o`/`O` comment continuation is
-- removed in config.autocmds; Enter in a comment still continues it.

-- Load plugin configuration as Lua files, not through local project scripts.
opt.exrc = false

-- auto-session: restore buffers, layout, cwd and per-window options (no globals).
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
