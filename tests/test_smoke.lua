-- Startup, mappings, indentation, reload/conflict safety, pickers, buffer close.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local temp

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      temp = h.tempdir()
      vim.fn.writefile({ "conflicting text" }, temp .. "/sample.txt")
    end,
    pre_case = h.no_errors.pre_case,
    post_case = function()
      vim.cmd("silent! %bwipeout!")
      h.no_errors.post_case()
    end,
    post_once = function() vim.fn.delete(temp, "rf") end,
  },
})

T["startup"] = MiniTest.new_set()

T["startup"]["loads theme, options and plugin managers"] = function()
  h.eq(vim.g.colors_name, "github_personal")
  h.eq(vim.api.nvim_get_hl(0, { name = "Normal" }).bg, 0)
  assert(vim.o.number and vim.o.relativenumber and vim.o.autoread)
  h.eq(vim.fn.exists(":Lazy"), 2)
  h.eq(vim.fn.exists(":Mason"), 2)
end

T["startup"]["defines core mappings"] = function()
  for _, key in ipairs({ "<Space>lf", "<Space>f", "<Space>sl", "<Space>Bd", "<C-x>", "<C-e>", "H", "L", "ys" }) do
    assert(vim.fn.maparg(key, "n") ~= "", "missing mapping: " .. key)
  end
end

T["startup"]["sets indentation per filetype"] = function()
  for ft, width in pairs({ python = 4, typescript = 2, yaml = 2, jsonc = 2, ini = 4 }) do
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(false, true))
    vim.bo.filetype = ft
    h.eq({ ft, vim.bo.shiftwidth }, { ft, width })
  end
end

T["external changes"] = MiniTest.new_set()

T["external changes"]["reload unmodified buffers"] = function()
  local path = temp .. "/reload.txt"
  vim.fn.writefile({ "before" }, path)
  vim.cmd.edit(path)
  vim.fn.writefile({ "after external edit" }, path)
  vim.uv.fs_utime(path, os.time() + 2, os.time() + 2)
  vim.cmd.checktime()
  h.eq(vim.api.nvim_get_current_line(), "after external edit")
end

T["external changes"]["never overwrite unsaved edits"] = function()
  local path = temp .. "/conflict.txt"
  vim.fn.writefile({ "before" }, path)
  vim.cmd.edit(path)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved local edit" })
  vim.fn.writefile({ "conflicting external edit" }, path)
  vim.uv.fs_utime(path, os.time() + 4, os.time() + 4)
  local conflict
  -- Observe native conflict handling without requiring an interactive dialog.
  local id = vim.api.nvim_create_autocmd("FileChangedShell", {
    callback = function()
      conflict = vim.v.fcs_reason
      vim.v.fcs_choice = ""
    end,
  })
  MiniTest.finally(function() vim.api.nvim_del_autocmd(id) end)
  vim.cmd.checktime()
  h.eq(conflict, "conflict")
  assert(vim.bo.modified, "buffer lost its modified flag")
  h.eq(vim.api.nvim_get_current_line(), "unsaved local edit")
end

T["pickers"] = MiniTest.new_set({
  hooks = { post_case = function() vim.wait(100) end },
})

local function await_items(picker)
  MiniTest.finally(function() picker:close() end)
  h.wait(function() return picker:count() > 0 and picker.shown end, "picker returned no results", 5000)
  assert(not picker.closed, "picker unexpectedly closed")
  picker:focus()
  h.wait(function() return not picker:is_active() end, "picker finder did not finish", 5000)
end

T["pickers"]["files"] = function()
  await_items(Snacks.picker.files({ cwd = temp }))
  h.eq(vim.fn.maparg("<C-j>", "i", false, true).buffer, 1)
end

T["pickers"]["grep"] = function()
  await_items(Snacks.picker.grep({ cwd = temp, search = "conflicting" }))
end

T["pickers"]["explorer"] = function()
  await_items(Snacks.explorer({ cwd = temp }))
  h.eq(vim.fn.maparg("<C-x>", "n", false, true).buffer, 1)
  h.eq(vim.fn.maparg("<C-l>", "n", false, true).expr, 1)
end

T["buffer close keeps split layout"] = function()
  vim.cmd.edit(temp .. "/sample.txt")
  vim.cmd.vsplit()
  MiniTest.finally(function() vim.cmd.only() end)
  local windows = #vim.api.nvim_list_wins()
  Snacks.bufdelete()
  h.eq(#vim.api.nvim_list_wins(), windows)
end

T["resize mode repeats until another key"] = function()
  vim.cmd.vsplit()
  vim.cmd.split()
  MiniTest.finally(function() vim.cmd.only() end)
  local width, height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
  h.keys(" wrlllkq")
  h.eq(vim.api.nvim_win_get_width(0), width + 6)
  h.eq(vim.api.nvim_win_get_height(0), height + 2)
  -- The finishing key is consumed, not executed: `q` must not start a recording.
  h.eq(vim.fn.reg_recording(), "")
  h.keys(" wrHJ\27")
  h.eq(vim.api.nvim_win_get_width(0), width - 4)
  h.eq(vim.api.nvim_win_get_height(0), height - 8)
end

return T
