local M = {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
}

function M.config()
  local function toggle_blame_wrapper()
    local status = require("gitsigns").toggle_current_line_blame()
    if status == true then
      vim.notify("Git line blame activated")
    else
      vim.notify("Git line blame deactivated")
    end
  end

  local gitsigns = require("gitsigns")
  local icons = require("user.utils.icons")
  local wk = require("which-key")
  wk.register({
    ["<leader>gg"] = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "Lazygit" },
    ["<leader>gj"] = { "<cmd>lua require 'gitsigns'.next_hunk({navigation_message = false})<cr>", "Next Hunk" },
    ["<leader>gk"] = { "<cmd>lua require 'gitsigns'.prev_hunk({navigation_message = false})<cr>", "Prev Hunk" },
    ["<leader>gp"] = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
    ["<leader>gr"] = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
    ["<leader>gl"] = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", "Blame" },
    ["<leader>gR"] = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
    ["<leader>gs"] = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" },
    ["<leader>gu"] = {
      "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
      "Undo Stage Hunk",
    },
    ["<leader>gd"] = {
      "<cmd>Gitsigns diffthis HEAD<cr>",
      "Git Diff",
    },
    ["<leader>go"] = {
      "<cmd>Telescope git_status<cr>",
      "Git status",
    },
    ["<leader>gb"] = {
      "<cmd>Telescope git_branches<cr>",
      "Git branches",
    },
    ["<leader>gc"] = {
      "<cmd>Telescope git_commits<cr>",
      "Git commits",
    },
    ["<leader>gt"] = {
      toggle_blame_wrapper,
      "Toggle line blame",
    },
  })

  gitsigns.setup({
    signs = {
      add = {
        hl = "GitSignsAdd",
        text = icons.ui.BoldLineMiddle,
        numhl = "GitSignsAddNr",
        linehl = "GitSignsAddLn",
      },
      change = {
        hl = "GitSignsChange",
        text = icons.ui.BoldLineDashedMiddle,
        numhl = "GitSignsChangeNr",
        linehl = "GitSignsChangeLn",
      },
      delete = {
        hl = "GitSignsDelete",
        text = icons.ui.TriangleShortArrowRight,
        numhl = "GitSignsDeleteNr",
        linehl = "GitSignsDeleteLn",
      },
      topdelete = {
        hl = "GitSignsDelete",
        text = icons.ui.TriangleShortArrowRight,
        numhl = "GitSignsDeleteNr",
        linehl = "GitSignsDeleteLn",
      },
      changedelete = {
        hl = "GitSignsChange",
        text = icons.ui.BoldLineMiddle,
        numhl = "GitSignsChangeNr",
        linehl = "GitSignsChangeLn",
      },
    },
    signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
    numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
    linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
    word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
    watch_gitdir = {
      interval = 1000,
      follow_files = true,
    },
    attach_to_untracked = true,
    current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
      delay = 1000,
      ignore_whitespace = false,
    },
    current_line_blame_formatter_opts = {
      relative_time = false,
    },
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil, -- Use default
    max_file_length = 40000,
    preview_config = {
      -- Options passed to nvim_open_win
      border = "single",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
    yadm = {
      enable = false,
    },
  })
end

return M
