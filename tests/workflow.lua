local temp = vim.fn.tempname()
local cwd = vim.fn.getcwd()
local setreg, confirm, notify = vim.fn.setreg, vim.fn.confirm, vim.notify
local copied, notices = {}, {}
local function keys(value)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(value, true, false, true), "xt", false)
end
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local function render()
  return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 240, highlights = true })
end

local function run()
  vim.fn.mkdir(temp .. "/a", "p")
  vim.fn.mkdir(temp .. "/b", "p")
  vim.fn.chdir(temp)
  vim.fn.setreg = function(register, value) copied[register] = value end
  vim.notify = function(message, level) notices[#notices + 1] = { message, level } end
  local function buffer(path)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, temp .. "/" .. path)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one", "two", "three", "four", "five" })
    vim.bo[buf].modified = false
    return buf
  end
  local source = buffer("source sample.txt")
  vim.api.nvim_set_current_buf(source)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  keys(" y")
  assert(copied["+"] == "@source sample.txt#L2", "normal context binding failed")
  keys("V2j y")
  assert(copied["+"] == "@source sample.txt#L2-4", "visual line range failed")
  assert(vim.fn.mode() == "n", "copy left Visual mode active")
  keys("V2k y")
  assert(copied["+"] == "@source sample.txt#L2-4", "reverse visual range failed")
  keys("v y")
  assert(copied["+"] == "@source sample.txt#L2", "single-line selection failed")
  keys("<C-v>2j y")
  assert(copied["+"] == "@source sample.txt#L2-4", "block selection line range failed")
  keys(" y")
  assert(copied["+"] == "@source sample.txt#L4", "normal copy reused an old selection")
  vim.fn.chdir(temp .. "/a")
  assert(require("config.context").reference(source, 2, 2) == "@" .. vim.api.nvim_buf_get_name(source) .. "#L2", "outside-cwd fallback failed")
  vim.fn.chdir(temp)
  local unnamed = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(unnamed)
  keys(" y")
  assert(copied["+"] == "@source sample.txt#L4", "unnamed buffer clobbered clipboard")
  assert(notices[#notices][2] == vim.log.levels.WARN, "missing unnamed-buffer warning")
  local scratch = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(scratch, "workflow-tool-buffer")
  assert(not require("config.context").reference(scratch, 1, 1), "tool buffer accepted as a context file")
  vim.api.nvim_buf_delete(unnamed, { force = true })

  local icons = require("nvim-web-devicons")
  local colors = { ts = "#0288d1", tsx = "#0288d1", js = "#ffca28", json = "#f9a825", yaml = "#ff5252", md = "#42a5f5" }
  local function check_icons()
    for extension, expected in pairs(colors) do
      local icon, color = icons.get_icon_color("sample." .. extension, extension)
      assert(icon and color == expected, "incorrect file icon color: " .. extension .. " " .. tostring(color))
      local _, group = Snacks.util.icon("sample." .. extension, "file")
      assert(hl(group).fg == tonumber(expected:sub(2), 16), "Snacks icon differs: " .. extension)
      assert(not hl(group).bg, "file icon has an opaque background")
    end
    local _, ts = icons.get_icon_by_filetype("typescript")
    local _, tsx = icons.get_icon_by_filetype("typescriptreact")
    assert(hl(ts).fg == 0x0288d1 and hl(tsx).fg == 0x0288d1, "statusline filetype icons differ")
  end
  check_icons()
  assert(not require("lazy.core.config").plugins["mini.icons"], "mock icon provider is still enabled")

  local a, b = buffer("a/index.ts"), buffer("b/index.ts")
  vim.api.nvim_set_current_buf(b)
  local line = render()
  assert(vim.o.showtabline == 2 and line.str:find("index.ts", 1, true), "buffer tab bar is missing")
  assert(not line.str:find("workflow-tool-buffer", 1, true), "tool buffer leaked into tabs")
  local elements = require("bufferline").get_elements().elements
  local found, previous = {}, 0
  for _, element in ipairs(elements) do
    assert(element.id > previous, "tab order differs from H/L buffer order")
    previous, found[element.id] = element.id, true
  end
  assert(found[a] and found[b] and not found[scratch], "wrong buffer tabs")
  assert(hl("BufferLineBufferSelected").bg == 0x21262d)
  assert(hl("BufferLineBackground").bg == 0x000000)
  assert(not hl("BufferLineDuplicateSelected").italic, "duplicate paths are italic")
  assert(hl("BufferLineDevIconTypeScriptSelected").fg == 0x0288d1, "tab icon lost its TypeScript color")
  assert(hl("BufferLineDevIconTypeScriptSelected").bg == 0x21262d, "tab icon background differs from selected tab")

  local options = require("bufferline.config").options
  vim.cmd.vsplit()
  local windows = #vim.api.nvim_list_wins()
  vim.api.nvim_buf_set_lines(b, 0, 1, false, { "unsaved change" })
  vim.fn.confirm = function() return 3 end
  options.close_command(b)
  assert(vim.bo[b].buflisted and vim.bo[b].modified, "cancel discarded unsaved changes")
  vim.fn.confirm = function() return 2 end
  options.middle_mouse_command(b)
  assert(not vim.bo[b].buflisted, "explicit discard did not close the buffer")
  assert(#vim.api.nvim_list_wins() == windows, "tab close disrupted split layout")
  vim.cmd.only()
  vim.api.nvim_set_current_buf(a)
  vim.cmd.colorscheme("default")
  vim.cmd.colorscheme("github_personal")
  check_icons()
  render()
  assert(hl("BufferLineBufferSelected").bg == 0x21262d, "theme reload lost tab styling")
  assert(vim.v.errmsg == "", "Neovim error: " .. vim.v.errmsg)
  print("PASS: normal/visual context clipboard bindings, file icon colors, buffer tabs, safe close, theme reload")
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  vim.fn.setreg, vim.fn.confirm, vim.notify = setreg, confirm, notify
  vim.fn.chdir(cwd)
  vim.fn.delete(temp, "rf")
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)
