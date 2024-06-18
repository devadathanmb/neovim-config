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
    terminal_color = false,

    -- Enable transparent background
    transparent = false,

    -- Enable italic comment
    italic_comments = true,

    -- Underline `@markup.link.*` variants
    underline_links = true,

    group_overrides = {
      -- this supports the same val table as vim.api.nvim_set_hl
      -- use colors from this colorscheme by requiring vscode.colors!
      NormalFloat = { bg = c.vscNone },
    },
  })
  require("vscode").load()

  vim.cmd.colorscheme("vscode")

  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#58a6ff" })
end

return M
