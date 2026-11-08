return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = { add = { text = "┃" }, change = { text = "┃" }, delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" }, untracked = { text = "┆" } },
      signs_staged = { add = { text = "│" }, change = { text = "│" }, delete = { text = "_" }, topdelete = { text = "‾" }, changedelete = { text = "~" } },
      signs_staged_enable = true,
      attach_to_untracked = false,
      current_line_blame = true,
      current_line_blame_opts = { delay = 750, virt_text_pos = "eol", use_focus = true },
      preview_config = { border = "rounded" },
      on_attach = function(buf) require("config.git").attach(buf) end,
    },
  },
  {
    -- Maintained fork of sindrets/diffview.nvim (unmaintained since 2024); same API.
    "dlyongemallo/diffview-plus.nvim",
    version = "*",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>gt", "<cmd>DiffviewOpen<cr>", desc = "Review Git changes" },
      { "<leader>gD", "<cmd>DiffviewOpen --cached<cr>", desc = "Review staged Git changes" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Git review" },
      { "<leader>gh", function()
        local path = vim.api.nvim_buf_get_name(0)
        if path == "" or vim.bo.buftype ~= "" then
          vim.notify("File history needs a named file buffer", vim.log.levels.WARN)
          return
        end
        vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(path))
      end, desc = "Git file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git repository history" },
    },
    opts = function() return require("config.git").diffview() end,
  },
}
