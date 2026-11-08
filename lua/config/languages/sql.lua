local M = {
  tools = { "sqlfluff" },
  formatters_by_ft = { sql = { "sqlfluff" } },
  formatters = {
    sqlfluff = { args = { "format", "--stdin-filename", "$FILENAME", "-" }, require_cwd = false },
  },
}

function M.setup_lint()
  local lint = require("lint")
  lint.linters_by_ft = { sql = { "sqlfluff" } }
  lint.linters.sqlfluff.args = { "lint", "--format=json", "--stdin-filename", function()
    return vim.api.nvim_buf_get_name(0)
  end, "-" }
  local group = vim.api.nvim_create_augroup("personal_lint", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
    group = group,
    callback = function(event)
      if vim.bo[event.buf].filetype == "sql" and vim.bo[event.buf].buftype == "" then lint.try_lint() end
    end,
  })
  -- Loaded by the first SQL FileType, after that buffer's BufReadPost.
  if vim.bo.filetype == "sql" and vim.bo.buftype == "" then lint.try_lint() end
end

return M
