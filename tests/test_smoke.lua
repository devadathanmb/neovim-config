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
    post_once = function()
      vim.fn.delete(temp, "rf")
    end,
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
  MiniTest.finally(function()
    vim.api.nvim_del_autocmd(id)
  end)
  vim.cmd.checktime()
  h.eq(conflict, "conflict")
  assert(vim.bo.modified, "buffer lost its modified flag")
  h.eq(vim.api.nvim_get_current_line(), "unsaved local edit")
end

T["pickers"] = MiniTest.new_set({
  hooks = {
    post_case = function()
      vim.wait(100)
    end,
  },
})

local function await_items(picker)
  MiniTest.finally(function()
    picker:close()
  end)
  h.wait(function()
    return picker:count() > 0 and picker.shown
  end, "picker returned no results", 5000)
  assert(not picker.closed, "picker unexpectedly closed")
  picker:focus()
  h.wait(function()
    return not picker:is_active()
  end, "picker finder did not finish", 5000)
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
  MiniTest.finally(function()
    vim.cmd.only()
  end)
  local windows = #vim.api.nvim_list_wins()
  Snacks.bufdelete()
  h.eq(#vim.api.nvim_list_wins(), windows)
end

T["resize mode repeats until another key"] = function()
  vim.cmd.vsplit()
  vim.cmd.split()
  MiniTest.finally(function()
    vim.cmd.only()
  end)
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

-- Swap prompts only for real recovery cases. Built in, no config code: Nvim skips
-- the prompt when a running Nvim owns the swap and deletes an unmodified swap
-- left by a dead process. A dead process's unsaved changes must still ask.
T["swap files"] = MiniTest.new_set()

-- Leave a real swap file behind: edit in a separate Nvim, then kill it.
local function stale_swap(name, dirty)
  local dir, file = temp .. "/swap", temp .. "/" .. name
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile({ "saved" }, file)
  local cmd = { "nvim", "--clean", "--headless", "-c", "set directory=" .. dir .. "//", "-c", "edit " .. file }
  if dirty then
    vim.list_extend(cmd, { "-c", "call setline(1, 'unsaved')", "-c", "preserve" })
  end
  local child = vim.system(cmd)
  h.wait(function()
    return #vim.fn.glob(dir .. "/*" .. name .. ".sw?", false, true) > 0
  end, "child did not write a swap", 5000)
  vim.wait(200)
  child:kill(9)
  child:wait()
  local directory = vim.o.directory
  vim.o.directory = dir .. "//"
  MiniTest.finally(function()
    vim.o.directory = directory
  end)
  return file, dir
end

T["swap files"]["stale swap without changes is removed silently"] = function()
  local file, dir = stale_swap("clean.txt", false)
  vim.cmd.edit(file)
  h.eq(vim.fn.getline(1), "saved")
  assert(vim.bo.modifiable and not vim.bo.readonly, "file did not open normally")
  vim.cmd("bwipeout!")
  h.eq(#vim.fn.glob(dir .. "/*clean.txt.sw?", false, true), 0)
end

T["swap files"]["stale swap with unsaved changes still asks"] = function()
  local file = stale_swap("dirty.txt", true)
  local choice
  -- Runs after the built-in handler: record its decision and answer the prompt.
  local id = vim.api.nvim_create_autocmd("SwapExists", {
    callback = function()
      choice = vim.v.swapchoice
      vim.v.swapchoice = "o"
    end,
  })
  MiniTest.finally(function()
    vim.api.nvim_del_autocmd(id)
    vim.cmd("silent! bwipeout!")
  end)
  vim.cmd.edit(file)
  h.eq(choice, "")
end

T["options"] = MiniTest.new_set()

T["options"]["o/O do not continue comments"] = function()
  vim.cmd.enew()
  vim.bo.filetype = "lua"
  assert(not vim.bo.formatoptions:find("o", 1, true), "formatoptions still has o: " .. vim.bo.formatoptions)
  h.eq(vim.o.pumheight, 10)
end

-- Guards lazy-loading: a plugin that starts loading eagerly shows up here.
T["startup stays fast"] = function()
  local log = temp .. "/startuptime.log"
  local best = math.huge
  for _ = 1, 3 do
    vim.fn.delete(log)
    vim
      .system(
        { "nvim", "--headless", "--startuptime", log, "-c", "lua vim.defer_fn(function() vim.cmd('qa!') end, 100)" },
        { cwd = temp }
      )
      :wait(10000)
    for _, entry in ipairs(vim.fn.readfile(log)) do
      local ms = entry:match("^(%d+%.%d+)%s+%d+%.%d+: %-%-%- NVIM STARTED")
      if ms then
        best = math.min(best, tonumber(ms))
      end
    end
  end
  assert(best < math.huge, "no startup time recorded")
  MiniTest.add_note(("startup %.1f ms"):format(best))
  assert(best < 150, ("startup took %.1f ms (limit 150)"):format(best))
end

T["markdown renders in normal mode, raw on the cursor line"] = function()
  local path = temp .. "/notes.md"
  vim.fn.writefile({ "# Title", "", "- [ ] task", "", "| a | b |", "| - | - |", "| 1 | 2 |" }, path)
  vim.cmd.edit(path)
  local ns = vim.api.nvim_get_namespaces()["render-markdown.nvim"]
  local function marks(row)
    return vim.api.nvim_buf_get_extmarks(0, ns or -1, { row, 0 }, { row, -1 }, {})
  end
  h.wait(function()
    return ns ~= nil and #marks(4) > 0
  end, "table was not rendered", 5000)
  h.wait(function()
    return #marks(2) > 0
  end, "checkbox was not rendered", 5000)
  -- Space um flips the plugin's global switch (marks clear on its next redraw).
  local state = require("render-markdown.state")
  h.keys(" um")
  h.eq(state.enabled, false)
  h.keys(" um")
  h.eq(state.enabled, true)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  -- API cursor moves fire no CursorMoved headless; render-markdown redraws on it.
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
  h.wait(function()
    return #marks(0) > 0
  end, "heading was not rendered", 5000)
  h.wait(function()
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, { 2, 0 }, { 2, -1 }, { details = true })) do
      if mark[4].virt_text or mark[4].conceal then
        return false
      end
    end
    return true
  end, "cursor line is not shown raw", 5000)
end

T["Space uz toggles zen mode"] = function()
  vim.cmd.edit(temp .. "/sample.txt")
  MiniTest.finally(function()
    if Snacks.zen.win and Snacks.zen.win:valid() then
      Snacks.zen.win:close()
    end
  end)
  h.keys(" uz")
  h.wait(function()
    return Snacks.zen.win and Snacks.zen.win:valid()
  end, "zen window did not open", 3000)
  local zen = Snacks.zen.win.win
  h.eq(vim.api.nvim_win_get_config(zen).relative, "editor")
  h.eq({ vim.wo[zen].number, vim.wo[zen].relativenumber, vim.wo[zen].list }, { false, false, false })
  -- The backdrop must be opaque, or the editor shows through on a black theme.
  local backdrop = Snacks.zen.win.backdrop
  assert(backdrop and backdrop:valid(), "zen backdrop missing")
  h.eq(vim.wo[backdrop.win].winblend, 0)
  h.keys(" uz")
  h.wait(function()
    return not (Snacks.zen.win and Snacks.zen.win:valid())
  end, "zen window did not close", 3000)
end

return T
