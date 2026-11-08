local M = {}

function M.reference(buf, first, last)
  local path = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype ~= "" or path == "" then
    return nil, "Context links need a named file buffer"
  end
  path = vim.fs.relpath(vim.fn.getcwd(), path) or path
  first, last = math.min(first, last), math.max(first, last)
  local lines = first == last and tostring(first) or (first .. "-" .. last)
  return "@" .. path .. "#L" .. lines
end

function M.copy(visual)
  local first = visual and vim.fn.line("v") or vim.fn.line(".")
  local reference, err = M.reference(0, first, vim.fn.line("."))
  if not reference then
    vim.notify(err, vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", reference)
  if visual then vim.cmd.normal({ args = { "\27" }, bang = true }) end
  vim.notify("Copied " .. reference)
end

return M
