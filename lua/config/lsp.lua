local M = {}

function M.python_path(root)
  if root then
    local python = vim.fs.joinpath(root, ".venv", "bin", "python")
    if vim.fn.executable(python) == 1 then return python end
    if vim.fn.executable("mise") == 1 then
      local result = vim.system({ "mise", "which", "python" }, { cwd = root, text = true }):wait(2000)
      local path = vim.trim(result.stdout or "")
      if result.code == 0 and vim.fn.executable(path) == 1 then return path end
    end
  end
  local active = vim.env.VIRTUAL_ENV and vim.fs.joinpath(vim.env.VIRTUAL_ENV, "bin", "python")
  if active and vim.fn.executable(active) == 1 then return active end
  return vim.fn.exepath("python3")
end

function M.setup()
  -- Neovim's default gr* LSP maps make the buffer-local gr (references) wait for
  -- timeoutlen. Equivalent actions live under gd/gr/gi/gt and Space l.
  for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, lhs == "gra" and { "n", "x" } or "n", lhs)
  end
  vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
  -- basedpyright: a pyright fork with Pylance-only features (semantic tokens,
  -- richer completions/hover). Reads [tool.basedpyright] or [tool.pyright].
  vim.lsp.config("basedpyright", {
    before_init = function(_, config)
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = M.python_path(config.root_dir)
    end,
    settings = {
      basedpyright = {
        disableOrganizeImports = true,
        analysis = {
          typeCheckingMode = "basic",
          autoImportCompletions = true,
          diagnosticSeverityOverrides = {
            reportReturnType = "warning",
            reportGeneralTypeIssues = "warning",
            reportOptionalMemberAccess = "none",
            reportOptionalSubscript = "none",
          },
        },
      },
    },
  })
  require("config.copilot").setup()
  vim.lsp.config("jsonls", {
    settings = {
      json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
    },
  })
  local schemas = require("schemastore").yaml.schemas()
  -- Kubernetes schemas are opt-in by filename/directory, never every YAML file.
  schemas.kubernetes = { "*.k8s.yaml", "*.k8s.yml", "k8s/**/*.yaml", "k8s/**/*.yml", "kubernetes/**/*.yaml", "kubernetes/**/*.yml" }
  vim.lsp.config("yamlls", {
    settings = {
      yaml = {
        schemaStore = { enable = false, url = "" },
        schemas = schemas,
        validate = true,
        keyOrdering = false,
      },
    },
  })

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
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.name == "ruff" then
        client.server_capabilities.hoverProvider = false
      end
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
      end
      map("gd", function() Snacks.picker.lsp_definitions() end, "Definition")
      map("gr", function() Snacks.picker.lsp_references() end, "References")
      map("gi", function() Snacks.picker.lsp_implementations() end, "Implementation")
      map("gt", function() Snacks.picker.lsp_type_definitions() end, "Type definition")
      map("gpd", function() Snacks.picker.lsp_definitions({ auto_confirm = false }) end, "Peek definitions")
      map("gpi", function() Snacks.picker.lsp_implementations({ auto_confirm = false }) end, "Peek implementations")
      map("gpt", function() Snacks.picker.lsp_type_definitions({ auto_confirm = false }) end, "Peek type definitions")
      map("gh", function() Snacks.picker.lsp_definitions({ auto_confirm = false }) end, "Preview definitions")
      map("K", vim.lsp.buf.hover, "Hover")
      map("gq", vim.lsp.buf.code_action, "Quick fix / code actions")
    end,
  })

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
  end
  map("n", "<leader>ls", function() Snacks.picker.lsp_symbols() end, "Document symbols")
  map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, "Document symbols")
  map("n", "<leader>lh", vim.lsp.buf.hover, "Hover")
  map("n", "<leader>ld", function() Snacks.picker.diagnostics_buffer() end, "Document diagnostics")
  map("n", "<leader>lD", function() Snacks.picker.diagnostics() end, "Workspace diagnostics")
  map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "<leader>lj", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
  map("n", "<leader>lk", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
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
      if ft and ft ~= "" then vim.bo.filetype = ft end
    end)
  end, "Change filetype")
  map("n", "<leader>pM", "<cmd>Mason<cr>", "Manage language tools")
  map("n", "<leader>uh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
  end, "Toggle inlay hints")
  map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
  map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
  map("n", "]e", function() vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR }) end, "Next error")
  map("n", "[e", function() vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR }) end, "Previous error")
  require("which-key").add({
    { "<leader>l", group = "Language" },
    { "<leader>r", group = "Refactor" },
  })
end

return M
