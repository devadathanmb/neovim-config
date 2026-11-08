-- Audit every Lua file with the same workspace settings as the editor.
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
local ok, err = xpcall(function()
  local settings = require("config.languages.lua").config_settings()
  local config = temp .. "/config.json"
  vim.fn.writefile({ vim.json.encode(settings) }, config)
  local executable = vim.fn.stdpath("data") .. "/mason/bin/lua-language-server"
  assert(vim.fn.executable(executable) == 1, "Install lua-language-server through Mason first")
  local result = vim
    .system({
      executable,
      "--check=" .. vim.fn.getcwd(),
      "--configpath=" .. config,
      "--checklevel=Hint",
      "--logpath=" .. temp .. "/log",
    }, { text = true })
    :wait(120000)
  io.stdout:write(result.stdout or "")
  io.stderr:write(result.stderr or "")
  assert(result.code == 0, "LuaLS workspace diagnostics failed (exit " .. result.code .. ")")
end, debug.traceback)
vim.fn.delete(temp, "rf")
if not ok then
  io.stderr:write(err .. "\n")
end
vim.cmd(ok and "qa!" or "cquit 1")
