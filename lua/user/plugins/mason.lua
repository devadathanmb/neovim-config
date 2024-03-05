local M = {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
}

local servers = {
  "pyright",
  "jsonls",
  "bashls",
  "jdtls",
  "clangd",
  "dockerls",
  "tsserver",
  "gopls",
  "html",
  "cssls",
  "emmet_ls",
  "lua_ls",
  "marksman",
  "tailwindcss",
}

local formatters = {
  "prettier",
  "stylua",
  "isort",
  "black",
  "beautysh",
}

function M.config()
  local mason = require("mason")
  local mason_lspconfig = require("mason-lspconfig")
  local mason_tool_installer = require("mason-tool-installer")

  mason.setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  })

  mason_lspconfig.setup({
    ensure_installed = servers,
    automatic_installation = true,
  })

  mason_tool_installer.setup({
    ensure_installed = formatters,
  })
end

return M
