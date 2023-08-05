local M = {
  "akinsho/bufferline.nvim",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = "User FileOpened",
}

function M.config()
  local bufferline = require("bufferline")
  bufferline.setup({
    options = {
      close_command = "BUfferKill",
    },
  })
end

return M
