local M = {
  "devadathanmb/arctic.nvim",
  dependencies = { "rktjmp/lush.nvim" },
  name = "arctic",
  branch = "v2",
  lazy = false,
  priority = 1000,
  enabled = true,
}

function M.config()
  vim.g.arctic_config = {
    transparent = true,
  }
  vim.cmd([[colorscheme arctic]])
end

return M
