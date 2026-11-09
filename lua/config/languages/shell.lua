return {
  servers = { "bashls" },
  tools = { "shellcheck", "shfmt" },
  formatters_by_ft = { sh = { "shfmt" }, bash = { "shfmt" } },
}
