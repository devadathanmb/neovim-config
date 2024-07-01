local M = {
  "LunarVim/bigfile.nvim",
  event = { "FileReadPre", "BufReadPre", "User FileOpened" },
}

function M.config()
  require("bigfile").setup({
    filesize = 0.6, -- size of the file in MiB, the plugin round file sizes to the closest MiB
    pattern = { "*" }, -- autocmd pattern or function see <### Overriding the detection of big files>
    features = { -- features to disable
      "indent_blankline",
      "illuminate",
      "lsp",
      "treesitter",
      "syntax",
      "matchparen",
      "vimopts",
      "filetype",
    },
  })
end

return M
