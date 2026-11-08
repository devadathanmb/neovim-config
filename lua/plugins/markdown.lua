-- In-buffer Markdown rendering (headings, tables, code blocks, checkboxes, callouts).
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    version = "^8",
    lazy = false, -- `keys` would otherwise defer loading until Space um
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown rendering" },
    },
    opts = {
      -- Checkbox/callout completions through the in-process LSP (blink picks it up).
      completions = { lsp = { enabled = true } },
      -- No latex parser or converter is installed; keep math as plain text.
      latex = { enabled = false },
    },
  },
}
