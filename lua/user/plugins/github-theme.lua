local M = {
  "projekt0n/github-nvim-theme",
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
}

function M.config()
  require("github-theme").setup({})

  vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=#04070D]])
  vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=#58A6FF guibg=#04070D]])
  vim.cmd("colorscheme github_dark_default")
end

return M
