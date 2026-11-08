-- In-buffer Markdown rendering (headings, tables, code blocks, checkboxes, callouts).
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    version = "^8",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Checkbox/callout completions through the in-process LSP (blink picks it up).
      completions = { lsp = { enabled = true } },
      -- No latex parser or converter is installed; keep math as plain text.
      latex = { enabled = false },
    },
  },
}
