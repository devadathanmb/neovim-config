return {
  {
    "akinsho/bufferline.nvim",
    version = "^4",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local function close(buf) Snacks.bufdelete(buf) end
      return {
        options = {
          mode = "buffers",
          numbers = "none",
          sort_by = "id",
          close_command = close,
          middle_mouse_command = close,
          right_mouse_command = false,
          indicator = { style = "none" },
          separator_style = "thin",
          diagnostics = false,
          show_buffer_icons = true,
          color_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = false,
          show_tab_indicators = false,
          always_show_bufferline = true,
          max_name_length = 30,
          tab_size = 22,
          buffer_close_icon = "×",
          modified_icon = "●",
          custom_filter = function(buf) return vim.bo[buf].buftype == "" end,
          offsets = {
            { filetype = "snacks_layout_box", text = "Explorer", text_align = "left", highlight = "GithubUiPanelTitle", separator = true },
            { filetype = "DiffviewFiles", text = "Git changes", text_align = "left", highlight = "GithubUiPanelTitle", separator = true },
          },
        },
        highlights = require("theme.github").bufferline(),
      }
    end,
  },
}
