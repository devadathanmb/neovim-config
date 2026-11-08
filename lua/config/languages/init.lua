local modules = {
  require("config.languages.python"),
  require("config.languages.web"),
  require("config.languages.lua"),
  require("config.languages.docker"),
  require("config.languages.sql"),
}

-- Shared infrastructure not tied to a language.
local M = { servers = { "copilot" }, tools = { "tree-sitter-cli" }, formatters_by_ft = {}, formatters = {} }
for _, module in ipairs(modules) do
  vim.list_extend(M.servers, module.servers or {})
  vim.list_extend(M.tools, module.tools or {})
  for _, field in ipairs({ "formatters_by_ft", "formatters" }) do
    for key, value in pairs(module[field] or {}) do
      assert(M[field][key] == nil, "duplicate language " .. field .. ": " .. key)
      M[field][key] = value
    end
  end
end

function M.setup_lsp()
  for _, module in ipairs(modules) do
    if module.setup_lsp then module.setup_lsp() end
  end
end

return M
