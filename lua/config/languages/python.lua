local M = {
  servers = { "basedpyright", "ruff" },
  tools = { "black" },
  formatters_by_ft = { python = { "black" } },
}

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

function M.setup_lsp()
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
  vim.lsp.config("ruff", {
    on_attach = function(client) client.server_capabilities.hoverProvider = false end,
  })
end

return M
