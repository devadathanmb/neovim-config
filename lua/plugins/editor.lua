return {
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("config.icons").setup()
    end,
  },
  {
    "Bekaboo/dropbar.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("config.breadcrumbs").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = require("theme.github").statusline(),
        globalstatus = true,
        ignore_focus = function(win)
          local buf = vim.api.nvim_win_get_buf(win)
          return vim.tbl_contains({
            "snacks_picker_input",
            "snacks_picker_list",
            "snacks_layout_box",
            "snacks_input",
            "DiffviewFiles",
            "DiffviewFileHistory",
            "trouble",
          }, vim.bo[buf].filetype) or vim.api.nvim_buf_get_name(buf):match("^diffview://") ~= nil
        end,
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { { "branch", icon = "\u{f418}" } },
        lualine_c = {
          {
            "filename",
            path = 1,
            fmt = function(text)
              local name = vim.api.nvim_buf_get_name(0)
              if vim.bo.filetype == "sidekick_terminal" then
                local tool = vim.b.sidekick_cli
                return type(tool) == "table" and tool.name or "Agent"
              end
              if not name:match("^diffview://") then
                return text
              end
              if vim.bo.filetype == "DiffviewFiles" then
                return "Git changes"
              end
              if vim.bo.filetype == "DiffviewFileHistory" then
                return "Git history"
              end
              return "[Git] " .. vim.fn.fnamemodify(name, ":t")
            end,
          },
          "diagnostics",
        },
        lualine_x = {
          {
            function()
              return require("config.copilot").statusline()
            end,
            color = function()
              return require("config.copilot").statusline_color()
            end,
            on_click = function()
              require("config.copilot").statusline_click()
            end,
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = function()
      local icon = require("config.icons").which_key
      return {
        delay = 300,
        win = { border = "rounded" },
        icons = { rules = false },
        spec = {
          { "<leader>a", group = "Agents", icon = icon("CopilotChat.nvim") },
          { "<leader>B", group = "Buffers", icon = icon("buffer") },
          { "<leader>b", group = "Bookmarks", icon = icon("grapple.nvim") },
          { "<leader>x", group = "Problems / lists", icon = icon("diagnostic") },
          { "<leader>g", group = "Git", icon = { cat = "filetype", name = "git" }, mode = { "n", "x" } },
          { "<leader>F", group = "Files", icon = icon("file") },
          { "<leader>s", group = "Search", icon = icon("search") },
          { "<leader>S", group = "Sessions", icon = icon("session") },
          { "<leader>w", group = "Windows", icon = icon("window") },
          { "<leader>u", group = "UI", icon = icon("ui") },
          { "<leader>p", group = "Configuration", icon = { cat = "file", name = "config" } },
          { "<leader>e", icon = icon("toggle") },
          { "<leader>f", icon = icon("find") },
          { "<leader>h", icon = icon("window") },
          { "<leader>v", icon = icon("window") },
          { "<leader>;", icon = icon("terminal") },
          { "<leader>y", icon = icon("yanky.nvim"), mode = { "n", "x" } },
          { "<leader>.", icon = icon("file") },
        },
      }
    end,
  },
  { "kylechui/nvim-surround", version = "^4.0.0" },
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = false, terminal = false },
    },
  },
}
