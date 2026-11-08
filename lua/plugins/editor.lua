return {
  {
    "nvim-tree/nvim-web-devicons",
    config = function() require("config.icons").setup() end,
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
          return vim.tbl_contains({ "snacks_picker_input", "snacks_picker_list", "snacks_layout_box", "snacks_input", "DiffviewFiles", "DiffviewFileHistory", "trouble" }, vim.bo[buf].filetype)
            or vim.api.nvim_buf_get_name(buf):match("^diffview://") ~= nil
        end,
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { { "branch", icon = "\u{f418}" } },
        lualine_c = { { "filename", path = 1, fmt = function(text)
          local name = vim.api.nvim_buf_get_name(0)
          if not name:match("^diffview://") then return text end
          if vim.bo.filetype == "DiffviewFiles" then return "Git changes" end
          if vim.bo.filetype == "DiffviewFileHistory" then return "Git history" end
          return "[Git] " .. vim.fn.fnamemodify(name, ":t")
        end }, "diagnostics" },
        lualine_x = {
          {
            function() return require("config.copilot").statusline() end,
            color = function() return require("config.copilot").statusline_color() end,
            on_click = function() require("config.copilot").statusline_click() end,
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
    opts = {
      delay = 300,
      win = { border = "rounded" },
      spec = {
        { "<leader>a", group = "Agents" },
        { "<leader>B", group = "Buffers" },
        { "<leader>b", group = "Bookmarks" },
        { "<leader>x", group = "Problems / lists" },
        { "<leader>g", group = "Git" },
        { "<leader>F", group = "Files" },
        { "<leader>s", group = "Search" },
        { "<leader>w", group = "Windows" },
        { "<leader>u", group = "UI" },
        { "<leader>p", group = "Configuration" },
      },
    },
  },
  { "kylechui/nvim-surround", version = "^4.0.0" },
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = false, terminal = false },
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      explorer = { enabled = true },
      indent = {
        enabled = true,
        indent = { char = "│" },
        scope = { char = "│", underline = false },
        animate = { enabled = false },
        filter = function(buf)
          return vim.bo[buf].buftype == "" and vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false
        end,
      },
      -- Highlights other references to the symbol under the cursor (VS Code occurrences).
      words = { enabled = true, debounce = 150 },
      notifier = { enabled = true, timeout = 2500, style = "compact", top_down = true },
      styles = { notification = { border = "rounded", focusable = false, wo = { winblend = 0 } } },
      picker = {
        enabled = true,
        layout = {
          config = function(layout)
            local function borders(box)
              if box.border == true or box.win == "preview" then box.border = "rounded" end
              for _, child in ipairs(box) do borders(child) end
            end
            borders(layout.layout)
          end,
        },
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          buffers = {
            win = { input = { keys = { ["<c-x>"] = { "close", mode = { "n", "i" } } } } },
          },
          explorer = {
            hidden = true,
            win = {
              list = {
                keys = {
                  ["o"] = "confirm",
                  ["<c-x>"] = "close",
                  ["<c-h>"] = { "<c-w>h", expr = true },
                  ["<c-j>"] = { "<c-w>j", expr = true },
                  ["<c-k>"] = { "<c-w>k", expr = true },
                  ["<c-l>"] = { "<c-w>l", expr = true },
                },
              },
            },
          },
        },
        win = {
          input = {
            keys = {
              ["<c-j>"] = { "list_down", mode = { "i", "n" } },
              ["<c-k>"] = { "list_up", mode = { "i", "n" } },
              ["<Tab>"] = { "list_down", mode = { "i", "n" } },
              ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
              ["<c-x>"] = { "close", mode = { "i", "n" } },
              ["<Esc>"] = { "close", mode = { "i", "n" } },
            },
          },
          list = { keys = { ["<c-x>"] = "close" } },
        },
      },
      input = { enabled = true },
      image = { enabled = true },
    },
    config = function(_, opts)
      require("snacks").setup(opts)
      require("config.image").setup()
    end,
  },
}
