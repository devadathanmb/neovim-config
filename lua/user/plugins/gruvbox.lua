local M = {
  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  enabled = true,
}

function M.config()
  -- Default options:
  require("gruvbox").setup({
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = true,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "", -- can be "hard", "soft" or empty string
    palette_overrides = {
      bright_blue = "#3abdb0",
      bright_purple = "#e37f9a",
      bright_aqua = "#80d162",

      dark_blue = "#3abdb0",
      dark_purple = "#e37f9a",
      dark_aqua = "#80d162",
    },
    overrides = {},
    dim_inactive = false,
    transparent_mode = true,
  })
  --[[ vim.cmd("colorscheme gruvbox") ]]
end

return M
