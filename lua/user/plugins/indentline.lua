local M = {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPost", "BufNewFile" },
  tag = "v2.20.8",
}

function M.config()
  local indent_blankline = require("indent_blankline")
  vim.opt.list = false

  indent_blankline.setup({
    show_current_context = true,
    use_treesitter = true,
    show_trailing_blankline_indent = false,
    show_first_indent_level = true,
    char = "▏",
    context_char = "▏",
    buftype_exclude = { "terminal", "nofile" },
    filetype_exclude = {
      "help",
      "startify",
      "dashboard",
      "lazy",
      "neogitstatus",
      "NvimTree",
      "Trouble",
      "text",
    },
  })
end

return M
