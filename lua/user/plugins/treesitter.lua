local M = {
  "nvim-treesitter/nvim-treesitter",
  event = "BufReadPost",
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      "nvim-tree/nvim-web-devicons",
    },
  },
}

function M.config()
  local configs = require("nvim-treesitter.configs")
  configs.setup({
    ensure_installed = "all",
    sync_install = false,
    autotag = {
      enable = true,
    },
    ignore_install = { "gomod" }, -- List of parsers to ignore installing
    highlight = {
      enable = true,           -- false will disable the whole extension
      disable = { "" },        -- list of language that will be disabled
      additional_vim_regex_highlighting = true,
    },
    indent = { enable = true, disable = { "yaml" } },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
  })
end

return M
