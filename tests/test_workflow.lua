-- Agent context references, statusline, icon colors, buffer tabs, safe close,
-- Snacks image detection under tmux.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local original = { setreg = vim.fn.setreg, confirm = vim.fn.confirm, notify = vim.notify }
local temp, cwd, copied, notices, source, scratch

local function buffer(path)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, temp .. "/" .. path)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one", "two", "three", "four", "five" })
  vim.bo[buf].modified = false
  return buf
end
local function render()
  return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 240, highlights = true })
end

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      cwd = vim.fn.getcwd()
      temp = h.tempdir()
      vim.fn.mkdir(temp .. "/a", "p")
      vim.fn.mkdir(temp .. "/b", "p")
      vim.fn.chdir(temp)
      copied, notices = {}, {}
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.fn.setreg = function(register, value)
        copied[register] = value
      end
      -- Capture notifications for assertions instead of displaying them.
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.notify = function(message, level)
        notices[#notices + 1] = { message, level }
      end
      source = buffer("source sample.txt")
      scratch = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_name(scratch, "workflow-tool-buffer")
    end,
    pre_case = h.no_errors.pre_case,
    post_case = h.no_errors.post_case,
    post_once = function()
      vim.fn.setreg, vim.fn.confirm, vim.notify = original.setreg, original.confirm, original.notify
      vim.fn.chdir(cwd)
      vim.fn.delete(temp, "rf")
    end,
  },
})

T["breadcrumbs are disabled by default"] = function()
  vim.api.nvim_set_current_buf(source)
  h.eq({ require("config.breadcrumbs").enabled, vim.wo.winbar }, { false, "" })
  h.keys(" ub")
  assert(vim.wo.winbar:find("dropbar", 1, true))
  h.keys(" ub")
  h.eq(vim.wo.winbar, "")
end

T["breadcrumbs"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      vim.api.nvim_set_current_buf(source)
      local crumbs = require("config.breadcrumbs")
      crumbs.enabled = true
      crumbs.refresh()
    end,
    post_case = function()
      local crumbs = require("config.breadcrumbs")
      crumbs.enabled = false
      crumbs.set_zen(false)
      h.no_errors.post_case()
    end,
  },
})

T["breadcrumbs"]["file paths render and Space ub toggles all splits"] = function()
  local win = vim.api.nvim_get_current_win()
  local function text()
    return vim.api.nvim_eval_statusline(vim.wo.winbar, { winid = win, use_winbar = true, maxwidth = 240 }).str
  end
  h.wait(function()
    return text():find("source sample.txt", 1, true) ~= nil
  end, "file breadcrumb missing")
  vim.cmd.vsplit()
  local split = vim.api.nvim_get_current_win()
  MiniTest.finally(function()
    if vim.api.nvim_win_is_valid(split) then
      vim.api.nvim_win_close(split, true)
    end
  end)
  h.keys(" ub")
  h.eq({ vim.wo[win].winbar, vim.wo[split].winbar }, { "", "" })
  h.keys(" ub")
  assert(vim.wo[win].winbar:find("dropbar", 1, true))
  assert(vim.wo[split].winbar:find("dropbar", 1, true))
end

T["breadcrumbs"]["tool buffers and floats stay clear; other winbars survive"] = function()
  vim.api.nvim_set_current_buf(scratch)
  h.eq(vim.wo.winbar, "")
  vim.api.nvim_set_current_buf(source)
  local float = vim.api.nvim_open_win(source, false, {
    relative = "editor",
    row = 2,
    col = 2,
    width = 30,
    height = 3,
    style = "minimal",
  })
  MiniTest.finally(function()
    vim.api.nvim_win_close(float, true)
    vim.wo.winbar = ""
    require("config.breadcrumbs").refresh()
  end)
  require("config.breadcrumbs").refresh()
  h.eq(vim.wo[float].winbar, "")
  vim.wo.winbar = "another winbar"
  h.keys(" ub")
  h.eq(vim.wo.winbar, "another winbar")
  h.keys(" ub")
  h.eq(vim.wo.winbar, "another winbar")
end

T["breadcrumbs"]["Lua symbol hierarchy follows the cursor"] = function()
  local path = temp .. "/crumbs.lua"
  vim.fn.writefile({ "local function outer()", "  local function inner()", "    return 1", "  end", "end" }, path)
  vim.cmd.edit(path)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
  h.wait(function()
    local text = vim.api.nvim_eval_statusline(vim.wo.winbar, { use_winbar = true, maxwidth = 240 }).str
    return text:find("outer", 1, true) and text:find("inner", 1, true)
  end, "Lua symbol hierarchy missing", 10000)
end

T["breadcrumbs"]["Markdown headings follow the cursor"] = function()
  local path = temp .. "/crumbs.md"
  vim.fn.writefile({ "# Outer", "", "## Inner", "", "body" }, path)
  vim.cmd.edit(path)
  vim.api.nvim_win_set_cursor(0, { 5, 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
  h.wait(function()
    local text = vim.api.nvim_eval_statusline(vim.wo.winbar, { use_winbar = true, maxwidth = 240 }).str
    return text:find("Outer", 1, true) and text:find("Inner", 1, true)
  end, "heading hierarchy missing")
end

T["context"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      vim.api.nvim_set_current_buf(source)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
    end,
  },
})

T["context"]["normal mode copies the current line"] = function()
  h.keys(" y")
  h.eq(copied["+"], "@source sample.txt#L2")
end

T["context"]["visual selections copy line ranges"] = function()
  for _, case in ipairs({
    { "V2j y", "@source sample.txt#L2-4" },
    { "v y", "@source sample.txt#L2" },
    { "<C-v>2j y", "@source sample.txt#L2-4" },
  }) do
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    h.keys(case[1])
    h.eq({ case[1], copied["+"] }, case)
    h.eq(vim.fn.mode(), "n")
  end
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  h.keys("V2k y")
  h.eq(copied["+"], "@source sample.txt#L2-4")
end

T["context"]["normal mode does not reuse an old selection"] = function()
  h.keys("V2j y")
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  h.keys(" y")
  h.eq(copied["+"], "@source sample.txt#L4")
end

T["context"]["falls back to absolute paths outside cwd"] = function()
  vim.fn.chdir(temp .. "/a")
  MiniTest.finally(function()
    vim.fn.chdir(temp)
  end)
  h.eq(require("config.context").reference(source, 2, 2), "@" .. vim.api.nvim_buf_get_name(source) .. "#L2")
end

T["context"]["rejects unnamed and tool buffers"] = function()
  copied["+"] = "unchanged"
  local unnamed = vim.api.nvim_create_buf(true, false)
  MiniTest.finally(function()
    vim.api.nvim_buf_delete(unnamed, { force = true })
  end)
  vim.api.nvim_set_current_buf(unnamed)
  h.keys(" y")
  h.eq(copied["+"], "unchanged")
  h.eq(notices[#notices][2], vim.log.levels.WARN)
  assert(not require("config.context").reference(scratch, 1, 1), "tool buffer accepted as a context file")
end

T["statusline filename"] = MiniTest.new_set()

local function filename(text)
  return require("lazy.core.config").plugins["lualine.nvim"].opts.sections.lualine_c[1].fmt(text)
end

T["statusline filename"]["keeps ordinary paths"] = function()
  vim.api.nvim_set_current_buf(source)
  h.eq(filename("source sample.txt"), "source sample.txt")
end

T["statusline filename"]["names the sidekick agent"] = function()
  vim.api.nvim_set_current_buf(scratch)
  vim.bo.filetype = "sidekick_terminal"
  MiniTest.finally(function()
    vim.b[scratch].sidekick_cli = nil
    vim.bo[scratch].filetype = ""
  end)
  vim.b.sidekick_cli = { name = "claude" }
  h.eq(filename("/long/path/to/claude [-]"), "claude")
  vim.b.sidekick_cli = { name = "pi" }
  h.eq(filename("/another/path/pi"), "pi")
  vim.b.sidekick_cli = nil
  h.eq(filename("/long/path"), "Agent")
end

local icon_colors =
  { ts = "#0288d1", tsx = "#0288d1", js = "#ffca28", json = "#f9a825", yaml = "#ff5252", md = "#42a5f5" }
local function check_icons()
  local icons = require("nvim-web-devicons")
  for extension, expected in pairs(icon_colors) do
    local icon, color = icons.get_icon_color("sample." .. extension, extension)
    assert(icon, "missing icon: " .. extension)
    h.eq({ extension, color }, { extension, expected })
    local _, group = Snacks.util.icon("sample." .. extension, "file")
    h.eq({ extension, h.hl(group).fg }, { extension, tonumber(expected:sub(2), 16) })
    assert(not h.hl(group).bg, "file icon has an opaque background")
  end
  local _, ts = icons.get_icon_by_filetype("typescript")
  local _, tsx = icons.get_icon_by_filetype("typescriptreact")
  h.eq({ h.hl(ts).fg, h.hl(tsx).fg }, { 0x0288d1, 0x0288d1 })
end

T["file icons match Material colors"] = function()
  check_icons()
  assert(not require("lazy.core.config").plugins["mini.icons"], "mock icon provider is still enabled")
end

T["buffer tabs"] = MiniTest.new_set()
local tab_a, tab_b

T["buffer tabs"]["list file buffers in H/L order"] = function()
  tab_a, tab_b = buffer("a/index.ts"), buffer("b/index.ts")
  vim.api.nvim_set_current_buf(tab_b)
  local line = render()
  assert(vim.o.showtabline == 2 and line.str:find("index.ts", 1, true), "buffer tab bar is missing")
  assert(not line.str:find("workflow-tool-buffer", 1, true), "tool buffer leaked into tabs")
  local found, previous = {}, 0
  for _, element in ipairs(require("bufferline").get_elements().elements) do
    assert(element.id > previous, "tab order differs from H/L buffer order")
    previous, found[element.id] = element.id, true
  end
  assert(found[tab_a] and found[tab_b] and not found[scratch], "wrong buffer tabs")
end

T["buffer tabs"]["styling"] = function()
  h.eq(h.hl("BufferLineBufferSelected").bg, 0x21262d)
  h.eq(h.hl("BufferLineBackground").bg, 0x000000)
  assert(not h.hl("BufferLineDuplicateSelected").italic, "duplicate paths are italic")
  h.eq(h.hl("BufferLineDevIconTypeScriptSelected").fg, 0x0288d1)
  h.eq(h.hl("BufferLineDevIconTypeScriptSelected").bg, 0x21262d)
end

T["buffer tabs"]["close asks before discarding and keeps splits"] = function()
  local options = require("bufferline.config").options
  vim.api.nvim_set_current_buf(tab_b)
  vim.cmd.vsplit()
  MiniTest.finally(function()
    vim.fn.confirm = original.confirm
    vim.cmd.only()
  end)
  local windows = #vim.api.nvim_list_wins()
  vim.api.nvim_buf_set_lines(tab_b, 0, 1, false, { "unsaved change" })
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.confirm = function()
    return 3
  end
  options.close_command(tab_b)
  assert(vim.bo[tab_b].buflisted and vim.bo[tab_b].modified, "cancel discarded unsaved changes")
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.confirm = function()
    return 2
  end
  options.middle_mouse_command(tab_b)
  assert(not vim.bo[tab_b].buflisted, "explicit discard did not close the buffer")
  h.eq(#vim.api.nvim_list_wins(), windows)
end

T["buffer tabs"]["survive a theme reload"] = function()
  vim.api.nvim_set_current_buf(tab_a)
  vim.cmd.colorscheme("default")
  vim.cmd.colorscheme("github_personal")
  check_icons()
  render()
  h.eq(h.hl("BufferLineBufferSelected").bg, 0x21262d)
end

-- config.image seeds snacks' terminal detection inside tmux (see SPEC.md).
T["image detection"] = MiniTest.new_set()

local function with_fake_tmux(termname, fn)
  local terminal = require("snacks.image.terminal")
  local saved = { tmux = vim.env.TMUX, system = vim.system, state = terminal._terminal, transform = terminal.transform }
  local calls = {}
  MiniTest.finally(function()
    vim.env.TMUX, vim.system = saved.tmux, saved.system
    terminal._terminal, terminal.transform = saved.state, saved.transform
  end)
  vim.env.TMUX = "/tmp/fake-tmux,1,0"
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.system = function(cmd)
    calls[#calls + 1] = table.concat(cmd, " ")
    local result = { code = 0, stdout = termname .. "\n" }
    return {
      wait = function()
        return result
      end,
    }
  end
  terminal._terminal, terminal.transform = nil, nil
  fn(terminal, calls)
end

T["image detection"]["uses the tmux client terminal and wraps graphics"] = function()
  with_fake_tmux("xterm-ghostty", function(terminal, calls)
    require("config.image").setup()
    h.eq(terminal._terminal.terminal, "ghostty")
    assert(vim.tbl_contains(calls, "tmux set -p allow-passthrough all"), "passthrough not enabled")
    h.eq(terminal.transform("\27_Gx\27\\"), "\27Ptmux;\27\27_Gx\27\27\\\27\\")
  end)
end

T["image detection"]["keeps an existing detection result"] = function()
  with_fake_tmux("xterm-ghostty", function(terminal)
    terminal._terminal = { terminal = "kitty" }
    require("config.image").setup()
    h.eq(terminal._terminal.terminal, "kitty")
    h.eq(terminal.transform, nil)
  end)
end

T["image detection"]["does nothing outside tmux"] = function()
  with_fake_tmux("xterm-ghostty", function(terminal, calls)
    vim.env.TMUX = nil
    require("config.image").setup()
    h.eq({ terminal._terminal, #calls }, { nil, 0 })
  end)
end

T["sessions"] = MiniTest.new_set()

T["sessions"]["headless runs never autosave or restore"] = function()
  local config = require("auto-session.config")
  h.eq({ config.enabled, config.auto_save, config.auto_restore }, { false, false, false })
  assert(vim.o.sessionoptions:find("localoptions", 1, true), "sessionoptions misses localoptions")
  for _, lhs in ipairs({ "<Space>Ss", "<Space>Sr", "<Space>Sw", "<Space>Sd", "<Space>St" }) do
    assert(vim.fn.maparg(lhs, "n") ~= "", "missing session mapping: " .. lhs)
  end
end

T["sessions"]["save and restore buffers and splits"] = function()
  local AutoSession, config = require("auto-session"), require("auto-session.config")
  local root = config.root_dir
  config.root_dir, AutoSession.validated = temp .. "/sessions/", false
  MiniTest.finally(function()
    config.root_dir, AutoSession.validated = root, false
    vim.cmd.only()
  end)
  local one, two = temp .. "/one.txt", temp .. "/two.txt"
  vim.fn.writefile({ "one" }, one)
  vim.fn.writefile({ "two" }, two)
  vim.cmd.edit(one)
  vim.cmd.vsplit(two)
  assert(AutoSession.save_session("workflow-test"), "session save failed")
  vim.cmd.only()
  vim.cmd("silent! %bwipeout!")
  assert(AutoSession.restore_session("workflow-test"), "session restore failed")
  local names = vim.tbl_map(function(win)
    return vim.fs.basename(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)))
  end, vim.api.nvim_tabpage_list_wins(0))
  table.sort(names)
  h.eq(names, { "one.txt", "two.txt" })
end

return T
