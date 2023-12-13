local M = {
  "kylechui/nvim-surround",
  version = "*", -- Use for stability; omit to use `main` branch for the latest features
  event = "VeryLazy",
}

function M.config()
  local nvim_surround = require("nvim-surround")
  nvim_surround.setup({})
end

return M
