-- Shared helpers for the mini.test suites (load with dofile, see tests/run.lua).
local M = {}

M.eq = MiniTest.expect.equality

function M.hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end

-- Feed keys as if typed, executing mappings, and wait for them to finish.
function M.keys(value)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(value, true, false, true), "xt", false)
end

-- Fail with `label` unless `test` becomes truthy within `timeout` ms.
function M.wait(test, label, timeout)
  assert(vim.wait(timeout or 8000, test, 20), label)
end

function M.tempdir()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, "p")
  return dir
end

-- Call a mapping's Lua callback directly (no key feeding or timeouts involved).
function M.action(lhs, mode)
  local mapping = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(mapping.callback, "missing callback: " .. lhs)
  mapping.callback()
end

function M.floats()
  return vim.tbl_filter(function(win) return vim.api.nvim_win_get_config(win).relative ~= "" end, vim.api.nvim_list_wins())
end

function M.assert_rounded(win, label)
  local border = vim.api.nvim_win_get_config(win).border
  assert(border and #border == 8, label .. " has no border")
  assert(border[1] == "╭" and border[5] == "╯", label .. " is not rounded")
end

-- Hooks that fail any case leaving a Neovim error message behind.
M.no_errors = {
  pre_case = function() vim.v.errmsg = "" end,
  post_case = function()
    local err = vim.v.errmsg
    vim.v.errmsg = ""
    assert(err == "", "Neovim error: " .. err)
  end,
}

return M
