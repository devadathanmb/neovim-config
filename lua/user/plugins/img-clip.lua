local M = {
  "HakonHarnes/img-clip.nvim",
  cmd = "PasteImage",
  branch = "main",
  lazy = true,
  opts = {},
  keys = {
    -- suggested keymap
    { "<leader>P", "<cmd>PasteImage<cr>", desc = "Paste clipboard image" },
  },
}

return M
