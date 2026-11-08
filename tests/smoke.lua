local function run()
  assert(vim.g.colors_name == "github_personal", "theme not loaded")
  assert(vim.api.nvim_get_hl(0, { name = "Normal" }).bg == 0, "background is not black")
  assert(vim.o.number and vim.o.relativenumber and vim.o.autoread)
  assert(vim.fn.exists(":Lazy") == 2)
  assert(vim.fn.exists(":Mason") == 2, "Mason is not available")
  assert(vim.fn.maparg("<Space>lf", "n") ~= "", "format binding missing")
  for _, key in ipairs({ "<Space>f", "<Space>sl", "<Space>Bd", "<C-x>", "<C-e>", "H", "L" }) do
    assert(vim.fn.maparg(key, "n") ~= "", "missing mapping: " .. key)
  end
  assert(vim.fn.maparg("ys", "n") ~= "", "surround mapping missing")

  for ft, width in pairs({ python = 4, typescript = 2, yaml = 2, jsonc = 2, ini = 4 }) do
    vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(false, true))
    vim.bo.filetype = ft
    assert(vim.bo.shiftwidth == width, "incorrect indentation: " .. ft)
  end

  vim.cmd.enew()
  local temp = vim.fn.tempname()
  vim.fn.mkdir(temp, "p")
  local path = temp .. "/sample.txt"
  vim.fn.writefile({ "before" }, path)
  vim.cmd.edit(path)
  vim.fn.writefile({ "after external edit" }, path)
  vim.uv.fs_utime(path, os.time() + 2, os.time() + 2)
  vim.cmd.checktime()
  assert(vim.api.nvim_get_current_line() == "after external edit", "external change not reloaded")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved local edit" })
  vim.fn.writefile({ "conflicting external edit" }, path)
  vim.uv.fs_utime(path, os.time() + 4, os.time() + 4)
  local conflict
  -- Observe native conflict handling without requiring an interactive dialog in CI.
  local id = vim.api.nvim_create_autocmd("FileChangedShell", {
    callback = function()
      conflict = vim.v.fcs_reason
      vim.v.fcs_choice = ""
    end,
  })
  vim.cmd.checktime()
  vim.api.nvim_del_autocmd(id)
  assert(conflict == "conflict", "expected a conflict notification")
  assert(vim.bo.modified and vim.api.nvim_get_current_line() == "unsaved local edit", "unsaved edit overwritten")
  vim.bo.modified = false
  vim.cmd.enew()

  local function await_items(picker)
    assert(vim.wait(5000, function() return picker:count() > 0 and picker.shown end, 20), "picker returned no results")
    assert(not picker.closed, "picker unexpectedly closed")
    picker:focus()
    assert(vim.wait(5000, function() return not picker:is_active() end, 20), "picker finder did not finish")
  end
  local picker = Snacks.picker.files({ cwd = temp })
  await_items(picker)
  assert(vim.fn.maparg("<C-j>", "i", false, true).buffer == 1, "picker input mapping missing")
  picker:close()
  vim.wait(100)

  picker = Snacks.picker.grep({ cwd = temp, search = "conflicting" })
  await_items(picker)
  picker:close()
  vim.wait(100)

  picker = Snacks.explorer({ cwd = temp })
  await_items(picker)
  assert(vim.fn.maparg("<C-x>", "n", false, true).buffer == 1, "explorer close mapping missing")
  assert(vim.fn.maparg("<C-l>", "n", false, true).expr == 1, "explorer window navigation missing")
  picker:close()
  vim.wait(100)

  vim.cmd.edit(path)
  vim.cmd.vsplit()
  local windows = #vim.api.nvim_list_wins()
  Snacks.bufdelete()
  assert(#vim.api.nvim_list_wins() == windows, "buffer close disrupted split layout")
  vim.cmd.only()
  vim.fn.delete(temp, "rf")
  assert(vim.v.errmsg == "", "Neovim error: " .. vim.v.errmsg)
  print("PASS: startup, mappings, indentation, reload/conflict safety, file/grep/explorer pickers, buffer deletion")
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)
