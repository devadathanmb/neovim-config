return {
  servers = { "tsc", "eslint", "yamlls", "jsonls" },
  tools = { "prettier" },
  formatters_by_ft = {
    javascript = { "biome", "prettier", stop_after_first = true },
    javascriptreact = { "biome", "prettier", stop_after_first = true },
    typescript = { "biome", "prettier", stop_after_first = true },
    typescriptreact = { "biome", "prettier", stop_after_first = true },
    json = { "biome", "prettier", stop_after_first = true },
    jsonc = { "biome", "prettier", stop_after_first = true },
    yaml = { "prettier" },
    markdown = { "prettier" },
    css = { "prettier" },
  },
  formatters = { biome = { require_cwd = true } },
  setup_lsp = function()
    vim.lsp.config("jsonls", {
      settings = { json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } } },
    })
    local schemas = require("schemastore").yaml.schemas()
    schemas.kubernetes =
      { "*.k8s.yaml", "*.k8s.yml", "k8s/**/*.yaml", "k8s/**/*.yml", "kubernetes/**/*.yaml", "kubernetes/**/*.yml" }
    vim.lsp.config("yamlls", {
      settings = {
        yaml = { schemaStore = { enable = false, url = "" }, schemas = schemas, validate = true, keyOrdering = false },
      },
    })
  end,
}
