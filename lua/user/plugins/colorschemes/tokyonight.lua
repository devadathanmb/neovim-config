local M = {
  "folke/tokyonight.nvim",
  lazy = false,
  enabled = true,
  priority = 1000,
  opts = {},
}

function M.config()
  require("tokyonight").setup({
    style = "night",
    transparent = false,
  })
  --vim.cmd([[colorscheme tokyonight]])
end

return M
