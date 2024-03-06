local M = {
  "folke/which-key.nvim",
  enabled = true,
  event = "VeryLazy",
}

function M.config()
  local which_key = require("which-key")

  which_key.setup({
    plugins = {
      marks = true, -- shows a list of your marks on ' and `
      registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      spelling = {
        enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
        suggestions = 20, -- how many suggestions should be shown in the list?
      },
      -- the presets plugin, adds help for a bunch of default keybindings in Neovim
      -- No actual key bindings are created
      presets = {
        operators = true, -- adds help for operators like d, y, ... and registers them for motion / text object completion
        motions = true, -- adds help for motions
        text_objects = true, -- help for text objects triggered after entering an operator
        windows = true, -- default bindings on <c-w>
        nav = true, -- misc bindings to work with windows
        z = true, -- bindings for folds, spelling and others prefixed with z
        g = true, -- bindings for prefixed with g
      },
    },
    -- add operators that will trigger motion and text object completion
    -- to enable all native operators, set the preset / operators plugin above
    operators = { gc = "Comments" },
    key_labels = {
      -- override the label used to display some keys. It doesn't effect WK in any other way.
      -- For example:
      -- ["<space>"] = "SPC",
      -- ["<cr>"] = "RET",
      -- ["<tab>"] = "TAB",
    },
    icons = {
      breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
      separator = "➜", -- symbol used between a key and it's label
      group = "+", -- symbol prepended to a group
    },
    popup_mappings = {
      scroll_down = "<c-d>", -- binding to scroll down inside the popup
      scroll_up = "<c-u>", -- binding to scroll up inside the popup
    },
    window = {
      border = "single", -- none, single, double, shadow
      position = "bottom", -- bottom, top
      margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
      padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
      winblend = 0,
    },
    layout = {
      height = { min = 4, max = 25 }, -- min and max height of the columns
      width = { min = 20, max = 50 }, -- min and max width of the columns
      spacing = 3, -- spacing between columns
      align = "left", -- align columns left, center or right
    },
    ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
    show_help = true, -- show help message on the command line when the popup is visible
    show_keys = true, -- show the currently pressed key and its label as a message in the command line
    triggers = "auto", -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specify a list manually
    triggers_blacklist = {
      -- list of mode / prefixes that should never be hooked by WhichKey
      -- this is mostly relevant for key maps that start with a native binding
      -- most people should not need to change this
      i = { "j", "k" },
      v = { "j", "k" },
    },
    -- disable the WhichKey popup for certain buf types and file types.
    -- Disabled by deafult for Telescope
    disable = {
      buftypes = {},
      filetypes = { "TelescopePrompt" },
    },
  })

  -- Your mappings and documentation of existing mappings goes here
  -- Already declared bindings in keymaps.lua
  local declared_mappings = {
    ["<leader>ff"] = { "Fuzzy finder" },
    ["<leader>fr"] = { "Format code" },
    ["<leader>fb"] = { "File browser" },
    ["<leader>e"] = { "Open Nvim Tree" },
    ["gl"] = { "Show diagnostics" },
    ["gd"] = { "Go to definition" },
    ["gD"] = { "Go to declaration" },
    ["gr"] = { "Go to reference" },
  }

  -- New mappings
  local which_key_mappings = {
    ["<leader>"] = {
      -- LSP bindings
      l = {
        name = "LSP",
        a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
        F = { "<cmd>LspToggleAutoFormat<cr>", "Toggle Autoformat" },
        i = { "<cmd>LspInfo<cr>", "Info" },
        I = { "<cmd>Mason<cr>", "Installer Info" },
        j = {
          "<cmd>lua vim.diagnostic.goto_next()<CR>",
          "Next Diagnostic",
        },

        k = {
          "<cmd>lua vim.diagnostic.goto_prev()<cr>",
          "Prev Diagnostic",
        },
        q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>", "Quickfix" },
        r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
      },
      -- Toggle term bindings
      t = {
        name = "Terminal",
        n = { "<cmd>edit term://zsh<cr>", "Buffer terminal" },
        H = { "<cmd>lua _HTOP_TOGGLE()<cr>", "Htop" },
        p = { "<cmd>lua _PYTHON_TOGGLE()<cr>", "Python" },
        f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
        h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
        v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
        t = { "<cmd>ToggleTerm<cr>", "toggle" },
      },
      -- Telescope git stuff
      g = {
        name = "Git",
        g = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "Lazygit" },
        j = { "<cmd>lua require 'gitsigns'.next_hunk()<cr>", "Next Hunk" },
        k = { "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", "Prev Hunk" },
        l = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", "Blame" },
        p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
        r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
        R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
        s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" },
        u = {
          "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
          "Undo Stage Hunk",
        },

        o = { "<cmd>Telescope git_status<cr>", "See status" },
        b = { "<cmd>Telescope git_branches<cr>", "See branches" },
        c = { "<cmd>Telescope git_commits<cr>", "See commits" },
        d = {
          "<cmd>Gitsigns diffthis HEAD<cr>",
          "Diff",
        },
      },

      -- Searching
      s = {
        name = "Search",
        z = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Zen mode" },
        l = { "<cmd>Telescope live_grep<cr>", "Live grep" },
        h = { "<cmd>Telescope help_tags<cr>", "Help tags" },
        d = { "<cmd>Telescope lsp_document_diagnostics<cr>", "Document diagnostics" },
        k = { "<cmd>Telescope keymaps<cr>", "Keymaps" },
        leader = { "<cmd>Telescope buffers<cr>", "Filetypes" },
        f = { "<cmd>Telescope find_files<cr>", "Find files" },
        b = { "<cmd>Telescope buffers<cr>", "Find buffers" },
      },

      -- Markdown
      m = {
        name = "Markdown",
        p = { "<cmd>MarkdownPreviewToggle<cr>", "Toggle markdown preview" },
        s = { "<cmd>MarkdownPreviewStop<cr>", "Stop markdown preview" },
      },
    },
  }

  -- Pass the mappings to which key
  which_key.register(declared_mappings)
  which_key.register(which_key_mappings)
end

return M
