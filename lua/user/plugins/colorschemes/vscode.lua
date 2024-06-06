local M = { "Mofiqul/vscode.nvim" }

function M.config()
  -- Lua:
  -- For dark theme (neovim's default)
  vim.o.background = "dark"
  -- For light theme

  local c = require("vscode.colors").get_colors()
  require("vscode").setup({
    -- Alternatively set style in setup
    -- style = 'light'

    -- Enable transparent background
    transparent = false,

    -- Enable italic comment
    italic_comments = true,

    -- Underline `@markup.link.*` variants
    underline_links = true,
  })
  require("vscode").load()

  -- load the theme without affecting devicon colors.

  vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=NONE]])
  vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=#58A6FF guibg=NONE]])
  vim.cmd([[autocmd! ColorScheme * highlight TelescopeBorder guifg=#58A6FF guibg=NONE]])

  vim.cmd.colorscheme("vscode")

  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#58a6ff" })
end

return M
