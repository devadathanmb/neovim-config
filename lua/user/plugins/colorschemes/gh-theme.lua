local M = {
  "projekt0n/github-nvim-theme",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
}

function M.config()
  require("github-theme").setup({
    options = {
      transparent = false,
      hide_nc_statusline = false, -- Override the underline style for non-active statuslines
      terminal_colors = false,
      styles = {
        comments = "italic",
        keywords = "bold",
        types = "italic,bold",
      },
    },
    paletts = {
      github_dark_default = {},
    },
  })

  vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=#04070D]])
  vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=#58A6FF guibg=#04070D]])
  -- Set the background color of nvimtree
  vim.cmd("colorscheme github_dark_default")

  vim.cmd([[
  hi NvimTreeNormal guibg=#04070D
]])
end

return M
