local M = {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
  enabled = false,
}

function M.config()
  local conform = require("conform")
  conform.setup({
    formatters_by_ft = {
      go = { "gofmt" },
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      markdown = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
    },
    format_on_save = {
      lsp_fallback = true,
      timeout_ms = 500,
    },
  })

  vim.keymap.set({ "n", "v" }, "<leader>fr", function()
    conform.format()
    vim.notify("Conform.nvim formatting..")
  end, { desc = "Format current buffer" })

  vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
      -- FormatDisable! will disable formatting just for this buffer
      vim.b.disable_autoformat = true
    else
      vim.g.disable_autoformat = true
    end
  end, {
    desc = "Disable autoformat-on-save",
    bang = true,
  })
  vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
  end, {
    desc = "Re-enable autoformat-on-save",
  })
end

return M
