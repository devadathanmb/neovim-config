-- copilot: see lua/config/copilot.lua (inline suggestions + statusline status).
local servers = { "basedpyright", "ruff", "tsc", "eslint", "yamlls", "jsonls", "copilot" }

return {
  {
    "mason-org/mason.nvim",
    opts = { ui = { border = "rounded" } },
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    -- VS Code-format snippet collection; personal snippets live in ./snippets.
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      -- Prebuilt Rust matcher (downloaded for the pinned release); Lua is the fallback.
      fuzzy = { implementation = "prefer_rust_with_warning" },
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        -- Tab: snippet placeholder → menu item → accept Copilot ghost text → indent.
        -- Inside a snippet use Ctrl-j/k for the menu. Ctrl-l always accepts Copilot.
        ["<Tab>"] = {
          function(cmp) if cmp.snippet_active({ direction = 1 }) then return cmp.snippet_forward() end end,
          "select_next",
          function() return require("config.copilot").accept() end,
          "fallback",
        },
        ["<S-Tab>"] = {
          function(cmp) if cmp.snippet_active({ direction = -1 }) then return cmp.snippet_backward() end end,
          "select_prev", "fallback",
        },
        ["<CR>"] = { "accept", "fallback" },
      },
      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
        menu = { border = "rounded" },
        documentation = { auto_show = true, window = { border = "rounded" } },
        ghost_text = { enabled = false },
        accept = { auto_brackets = { enabled = false } },
      },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true, window = { border = "rounded" } },
      cmdline = { enabled = false },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp", "b0o/SchemaStore.nvim" },
    config = function() require("config.lsp").setup() end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = { ensure_installed = servers, automatic_enable = servers },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "black", "prettier", "sqlfluff", "tree-sitter-cli" },
      auto_update = false,
      run_on_start = true,
      integrations = { ["mason-lspconfig"] = false },
    },
  },
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    keys = {
      { "<leader>lf", function() require("conform").format({ async = true }) end, desc = "Format document" },
      { "<leader>lv", function() require("conform").format({ async = true }) end, mode = "x", desc = "Format selection (when supported)" },
    },
    opts = {
      notify_on_error = true,
      default_format_opts = { timeout_ms = 10000, lsp_format = "never" },
      formatters_by_ft = {
        python = { "black" },
        javascript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
        json = { "biome", "prettier", stop_after_first = true },
        jsonc = { "biome", "prettier", stop_after_first = true },
        yaml = { "prettier" },
        markdown = { "prettier" },
        css = { "prettier" },
        sql = { "sqlfluff" },
      },
      formatters = {
        biome = { require_cwd = true },
        sqlfluff = {
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
          require_cwd = false,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    ft = "sql",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = { sql = { "sqlfluff" } }
      lint.linters.sqlfluff.args = { "lint", "--format=json", "--stdin-filename", function()
        return vim.api.nvim_buf_get_name(0)
      end, "-" }
      local group = vim.api.nvim_create_augroup("personal_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function(event)
          if vim.bo[event.buf].filetype == "sql" and vim.bo[event.buf].buftype == "" then
            lint.try_lint()
          end
        end,
      })
      -- Loaded by the first SQL FileType, after that buffer's BufReadPost.
      if vim.bo.filetype == "sql" and vim.bo.buftype == "" then lint.try_lint() end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = { "mason-org/mason.nvim" },
    config = function() require("config.treesitter").setup() end,
  },
}
