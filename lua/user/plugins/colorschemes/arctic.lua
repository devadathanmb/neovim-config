local M = {
  "rockyzhang24/arctic.nvim",
  dependencies = { "rktjmp/lush.nvim" },
  name = "arctic",
  branch = "v2",
  lazy = false,
  priority = 1000,
  enabled = true,
}

function M.config()
  vim.g.arctic_config = {
    transparent = false,
  }
  vim.cmd([[autocmd! ColorScheme * highlight NormalFloat guibg=NONE]])
  vim.cmd([[autocmd! ColorScheme * highlight FloatBorder guifg=#58A6FF guibg=NONE]])
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#58a6ff" })

  vim.cmd([[
  hi NvimTreeNormal guibg=#04070D
]])

  -- vim.cmd([[colorscheme arctic]])
end

return M
