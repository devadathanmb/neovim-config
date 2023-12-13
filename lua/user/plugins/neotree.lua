local M = {
  "nvim-neo-tree/neo-tree.nvim",
  cmd = "Neotree",
  -- branch = "v2.x",
  -- event = "FileOpened",
  enabled = true,
  dependencies = { "MunifTanjim/nui.nvim" },
  keys = {
    { "<leader>e", "<cmd>Neotree focus toggle<cr>", desc = "NeoTree" },
    { "<leader>b", "<cmd>Neotree focus buffers toggle<cr>", desc = "NeoTree buffer" },
  },
}

function M.config()
  require("neo-tree").setup({
    popup_border_style = "rounded",
    window = {
      position = "left",
      width = 27,
      mapping_options = {
        noremap = true,
        nowait = true,
      },
      -- mappings = {
      --   ['b'] = function() vim.api.nvim_exec2('Neotree focus buffers left', true) end,
      -- }
    },
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_current",
    },
    source_selector = {
      winbar = true,
      content_layout = "center",
      sources = {
        { source = "filesystem", display_name = " 󰈔 File" },
        { source = "buffers", display_name = "  Bufs" },
      },
    },
  })
end

return M
