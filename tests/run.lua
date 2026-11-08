-- Runs one mini.test suite inside the fully configured Neovim.
--   TEST_SUITE=smoke nvim --headless "+luafile tests/run.lua"
-- Optional TEST_FILTER keeps only cases whose description contains the text.
local suite = vim.env.TEST_SUITE
if not suite or suite == "" then
  io.stderr:write("Set TEST_SUITE (e.g. smoke)\n")
  vim.cmd.cquit(2)
end
local file = vim.fn.stdpath("config") .. "/tests/test_" .. suite .. ".lua"
if vim.fn.filereadable(file) == 0 then
  io.stderr:write("Unknown suite: " .. suite .. "\n")
  vim.cmd.cquit(2)
end

-- Start after startup finishes (VimEnter, lazy-loaded plugins, UI setup).
vim.schedule(function()
  local MiniTest = require("mini.test")
  MiniTest.setup()
  local filter = vim.env.TEST_FILTER
  MiniTest.run_file(file, {
    collect = {
      filter_cases = function(case)
        return not filter or filter == "" or table.concat(case.desc, " "):find(filter, 1, true) ~= nil
      end,
    },
    execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2, quit_on_finish = true }) },
  })
end)
