local M = {
  "utilyre/barbecue.nvim",
  event = { "InsertEnter", "BufReadPre", "BufAdd", "BufNew" },
  enabled = true,
  dependencies = {
    {
      "SmiteshP/nvim-navic",
    },
  },
}

function M.config()
  local barbecue = require("barbecue")
  barbecue.setup({
    exclude_filetypes = { "netrw", "toggleterm" },
    show_dirname = false,
    show_basename = true,
    show_modified = true,

    ---Whether context text should follow its icon's color.
    ---
    ---@type boolean
    context_follow_icon_color = false,

    symbols = {
      ---Modification indicator.
      ---
      ---@type string
      modified = " ",

      ---Truncation indicator.
      ---
      ---@type string
      ellipsis = "…",

      ---Entry separator.
      ---
      ---@type string
      separator = "",
    },
    theme = {
      modified = { fg = "#808080" },
    },
  })
end

return M
