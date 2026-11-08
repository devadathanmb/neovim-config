return {
  {
    -- Sneak + EasyMotion in one: `s` + a char or two shows jump labels across the window.
    "folke/flash.nvim",
    version = "^2",
    event = "VeryLazy",
    opts = {
      label = { uppercase = false },
      modes = {
        -- f/t/F/T stay line-local like native Vim, with highlighted targets and ; , repeat.
        char = { enabled = true, multi_line = false, highlight = { backdrop = false } },
        -- Regular / search stays native; Ctrl-s inside / toggles Flash labels.
        search = { enabled = false },
      },
      prompt = { enabled = false },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      -- Visual S is left to nvim-surround.
      { "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash select syntax node" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote operation" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash syntax search" },
      { "<C-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash labels in search" },
    },
  },
  {
    -- VS Code-style Problems panel (diagnostics, quickfix, location list, symbols).
    "folke/trouble.nvim",
    -- Track main: the Neovim 0.12 Tree-sitter fix (issue #658) is unreleased after v3.7.1.
    branch = "main",
    version = false,
    cmd = "Trouble",
    opts = {
      focus = true,
      auto_preview = false,
      warn_no_results = false,
      open_no_results = true,
      win = { size = 12 },
      modes = {
        symbols = { win = { position = "right", size = 40 } },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Problems (workspace)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Problems (current file)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols outline" },
      { "<leader>xr", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions panel" },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            pcall(vim.cmd.cnext)
          end
        end,
        desc = "Next problem/quickfix item",
      },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            pcall(vim.cmd.cprev)
          end
        end,
        desc = "Previous problem/quickfix item",
      },
    },
  },
}
