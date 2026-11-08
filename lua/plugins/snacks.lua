-- Explorer, pickers, input, notifier, indent guides, words, image previews.
return {
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
