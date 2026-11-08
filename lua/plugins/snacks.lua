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
      -- Zen hides inline Git blame and restores the previous setting on close.
      zen = {
        on_open = function()
          local ok, config = pcall(require, "gitsigns.config")
          vim.g.zen_blame = ok and config.config.current_line_blame or false
          if vim.g.zen_blame then
            require("gitsigns").toggle_current_line_blame(false)
          end
        end,
        on_close = function()
          if vim.g.zen_blame then
            require("gitsigns").toggle_current_line_blame(true)
          end
          vim.g.zen_blame = nil
        end,
      },
      styles = {
        notification = { border = "rounded", focusable = false, wo = { winblend = 0 } },
        zen = {
          -- The default transparent backdrop blends black over a black background,
          -- so the editor behind zen stayed visible. Use a solid backdrop instead.
          backdrop = { transparent = false, blend = 99 },
          -- Reading view: no line numbers, whitespace dots, signs or cursor line.
          wo = {
            number = false,
            relativenumber = false,
            list = false,
            signcolumn = "no",
            cursorline = false,
            winhighlight = "NormalFloat:Normal",
          },
        },
      },
      picker = {
        enabled = true,
        layout = {
          config = function(layout)
            local function borders(box)
              if box.border == true or box.win == "preview" then
                box.border = "rounded"
              end
              for _, child in ipairs(box) do
                borders(child)
              end
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
