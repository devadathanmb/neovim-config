-- Per-directory sessions: restore buffers and layout when Neovim starts without
-- file arguments. Headless runs (tests, scripts) never save or restore.
local headless = vim.tbl_contains(vim.v.argv, "--headless")

return {
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      enabled = not headless,
      auto_save = not headless,
      auto_restore = not headless,
      suppressed_dirs = { "~/", "~/Downloads", "~/Desktop", "/", "/tmp" },
      -- Tool windows are rebuilt on demand; restoring them leaves broken buffers.
      close_filetypes_on_save = {
        "checkhealth", "snacks_layout_box", "snacks_picker_list", "snacks_picker_input",
        "sidekick_terminal", "DiffviewFiles", "DiffviewFileHistory", "trouble", "grug-far",
      },
      bypass_save_filetypes = { "snacks_dashboard" },
      session_lens = { picker = "snacks" },
    },
    keys = {
      { "<leader>Ss", "<cmd>AutoSession search<cr>", desc = "Find session" },
      { "<leader>Sr", "<cmd>AutoSession restore<cr>", desc = "Restore session for cwd" },
      { "<leader>Sw", "<cmd>AutoSession save<cr>", desc = "Save session" },
      { "<leader>Sd", "<cmd>AutoSession delete<cr>", desc = "Delete session for cwd" },
      { "<leader>St", "<cmd>AutoSession toggle<cr>", desc = "Toggle session autosave" },
    },
  },
}
