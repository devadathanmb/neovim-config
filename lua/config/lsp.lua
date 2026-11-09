local M = {}

function M.setup()
  -- Neovim's default gr* LSP maps make the buffer-local gr (references) wait for
  -- timeoutlen. Equivalent actions live under gd/gr/gi/gt and Space l.
  for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, lhs == "gra" and { "n", "x" } or "n", lhs)
  end
  vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
  require("config.languages").setup_lsp()
  require("config.copilot").setup()

  vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    virtual_text = { spacing = 2, source = "if_many" },
    float = { border = "rounded", source = true },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "\u{f057}",
        [vim.diagnostic.severity.WARN] = "\u{f071}",
        [vim.diagnostic.severity.INFO] = "\u{f05a}",
        [vim.diagnostic.severity.HINT] = "\u{f0eb}",
      },
    },
    update_in_insert = false,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("personal_lsp", { clear = true }),
    callback = function(event)
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
      end
      map("gd", function()
        Snacks.picker.lsp_definitions()
      end, "Definition")
      map("gr", function()
        Snacks.picker.lsp_references()
      end, "References")
      map("gi", function()
        Snacks.picker.lsp_implementations()
      end, "Implementation")
      map("gt", function()
        Snacks.picker.lsp_type_definitions()
      end, "Type definition")
      map("gpd", function()
        Snacks.picker.lsp_definitions({ auto_confirm = false })
      end, "Peek definitions")
      map("gpi", function()
        Snacks.picker.lsp_implementations({ auto_confirm = false })
      end, "Peek implementations")
      map("gpt", function()
        Snacks.picker.lsp_type_definitions({ auto_confirm = false })
      end, "Peek type definitions")
      map("gh", function()
        Snacks.picker.lsp_definitions({ auto_confirm = false })
      end, "Preview definitions")
      map("K", vim.lsp.buf.hover, "Hover")
      map("gq", vim.lsp.buf.code_action, "Quick fix / code actions")
    end,
  })

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
  end
  map("n", "<leader>ls", function()
    Snacks.picker.lsp_symbols()
  end, "Document symbols")
  map("n", "<leader>ss", function()
    Snacks.picker.lsp_symbols()
  end, "Document symbols")
  map("n", "<leader>lh", vim.lsp.buf.hover, "Hover")
  map("n", "<leader>ld", function()
    Snacks.picker.diagnostics_buffer()
  end, "Document diagnostics")
  map("n", "<leader>lD", function()
    Snacks.picker.diagnostics()
  end, "Workspace diagnostics")
  map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "<leader>lj", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, "Next diagnostic")
  map("n", "<leader>lk", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, "Previous diagnostic")
  map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
  map("n", "<leader>rs", vim.lsp.buf.rename, "Rename symbol")
  map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "Code actions")
  map("n", "<leader>li", function()
    vim.lsp.buf.code_action({
      context = { only = { "source.organizeImports" }, diagnostics = {} },
      apply = true,
    })
  end, "Organize imports")
  map("n", "<leader>lm", function()
    vim.ui.input({ prompt = "Filetype: ", default = vim.bo.filetype }, function(ft)
      if ft and ft ~= "" then
        vim.bo.filetype = ft
      end
    end)
  end, "Change filetype")
  map("n", "<leader>pM", "<cmd>Mason<cr>", "Manage language tools")
  map("n", "<leader>uh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
  end, "Toggle inlay hints")
  map("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, "Next diagnostic")
  map("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, "Previous diagnostic")
  map("n", "]e", function()
    vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR })
  end, "Next error")
  map("n", "[e", function()
    vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR })
  end, "Previous error")
  require("which-key").add({
    { "<leader>l", group = "Language", icon = require("config.icons").which_key("code"), mode = { "n", "x" } },
    { "<leader>r", group = "Refactor", icon = require("config.icons").which_key("refactor"), mode = { "n", "x" } },
  })
end

return M
