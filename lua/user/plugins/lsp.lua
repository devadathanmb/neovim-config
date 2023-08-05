local M = {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "jose-elias-alvarez/null-ls.nvim",
    },
    lazy = false,
    config = function()
      require("user.lsp.init")
    end,
  },
  --[[ { ]]
  --[[   "jose-elias-alvarez/null-ls.nvim", ]]
  --[[   event = { "BufReadPre", "BufRead", "BufNew" }, ]]
  --[[   lazy = true, ]]
  --[[   config = function() ]]
  --[[     require("user.lsp.null-ls") ]]
  --[[   end, ]]
  --[[ }, ]]
  {"mfussenegger/nvim-jdtls"}
}

return M
