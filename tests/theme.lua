local temp = vim.fn.tempname()
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local function color(name, field, hex)
  assert(hl(name)[field] == tonumber(hex:sub(2), 16), name .. "." .. field .. " differs: " .. vim.inspect(hl(name)))
end
local function luminance(rgb)
  local value = 0
  for i, weight in ipairs({ 0.2126, 0.7152, 0.0722 }) do
    local channel = math.floor(rgb / 256 ^ (3 - i)) % 256 / 255
    value = value + weight * (channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4)
  end
  return value
end
local function contrast(foreground, background)
  local a, b = luminance(foreground), luminance(background)
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
end
local function border(win, label)
  local config = vim.api.nvim_win_get_config(win)
  assert(config.border and #config.border == 8, label .. " has no border: " .. vim.inspect(config))
  assert(config.border[1] == "╭" and config.border[5] == "╯", label .. " is not rounded")
end

local function run()
  local theme = require("theme.github")
  assert(vim.g.colors_name == "github_personal")
  assert(not require("lazy.core.config").plugins["github-nvim-theme"], "old theme plugin still enabled")
  assert(vim.o.winborder == "rounded")
  assert(hl("SidekickChat").bg == nil and hl("SidekickChat").fg == nil, "agent panel must use terminal defaults")
  color("Normal", "bg", "#000000")
  color("Normal", "fg", "#d7d8da")
  color("Whitespace", "fg", "#343333")
  color("StatusLine", "fg", "#e1e4e8")
  color("TabLineSel", "bg", "#21262d")
  color("TabLine", "bg", "#000000")
  color("NavicContext", "fg", "#61dafb")
  color("GitSignsAdd", "fg", "#4ae04a")
  color("GitSignsChange", "fg", "#e2c08d")
  color("GitSignsDelete", "fg", "#ff6b6b")
  color("GitSignsCurrentLineBlame", "fg", "#656d71")
  color("SnacksPickerGitStatusAdded", "fg", "#4ae04a")
  color("SnacksPickerGitStatusModified", "fg", "#e2c08d")
  color("SnacksPickerGitStatusDeleted", "fg", "#ff6b6b")
  color("Comment", "fg", "#8b949e")
  assert(hl("Comment").italic)
  color("@keyword", "fg", "#ff7b72")
  color("@string", "fg", "#a5d6ff")
  color("@function", "fg", "#d2a8ff")
  color("@number", "fg", "#79c0ff")
  color("@type", "fg", "#ffa657")
  color("@variable", "fg", "#e6edf3")
  color("@string.special.key.yaml", "fg", "#7ee787")
  color("@string.special.key.json", "fg", "#7ee787")
  for _, group in ipairs({ "@keyword.import.python", "@keyword.function.python", "@keyword.return.python",
    "@keyword.conditional.python", "@keyword.repeat.python", "@keyword.flow.python", "@keyword.coroutine.python",
    "@type.python", "@type.builtin.python", "@lsp.type.type.python", "@lsp.mod.typeHint" }) do
    assert(hl(group).italic, "missing VS Code italic override: " .. group)
  end
  assert(not hl("@keyword").italic, "Python italics leaked into all languages")
  local ts = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(ts, 0, -1, false, { '// comment', 'export const value = "hello"' })
  vim.treesitter.start(ts, "typescript")
  vim.treesitter.get_parser(ts, "typescript"):parse()
  for _, position in ipairs({ { 0, 0 }, { 1, 0 }, { 1, 21 } }) do
    assert(#vim.treesitter.get_captures_at_pos(ts, position[1], position[2]) > 0,
      "TypeScript highlight queries missing at " .. vim.inspect(position))
  end
  vim.api.nvim_buf_delete(ts, { force = true })
  local python = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(python, 0, -1, false, { "assert True", "del value", "with resource:", "    pass" })
  vim.treesitter.start(python, "python")
  vim.treesitter.get_parser(python, "python"):parse()
  for _, position in ipairs({ { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 4 } }) do
    local found = false
    for _, capture in ipairs(vim.treesitter.get_captures_at_pos(python, position[1], position[2])) do
      if capture.capture == "keyword.flow" then found = true end
    end
    assert(found, "Python flow-scope query not applied at " .. vim.inspect(position))
  end
  vim.api.nvim_buf_delete(python, { force = true })
  color("@lsp.type.function", "fg", "#d2a8ff")
  color("@lsp.type.variable", "fg", "#e6edf3")
  assert(theme.blend("#ffffff80", "#000000") == "#808080")
  assert(theme.blend("#00000000", "#123456") == "#123456")
  color("CursorLine", "bg", "#0b0c0d")
  assert(theme.statusline().normal.c.fg:lower() == "#e1e4e8")
  for mode, sections in pairs(theme.statusline()) do
    for section, spec in pairs(sections) do
      assert(spec.bg == "#0d1117", "colored statusline block: " .. mode .. "/" .. section)
    end
  end
  color("lualine_a_normal", "bg", "#0d1117")
  color("lualine_a_normal", "fg", "#e1e4e8")
  for _, group in ipairs({ "SnacksPickerDirectory", "SnacksPickerFile", "SnacksPickerDir", "SnacksPickerPathHidden",
    "SnacksPickerPathIgnored", "SnacksPickerTotals", "SnacksPickerComment", "SnacksPickerDesc", "WhichKeyDesc",
    "BlinkCmpLabel", "BlinkCmpLabelDetail", "BlinkCmpLabelDescription", "BlinkCmpSource" }) do
    local spec = hl(group)
    assert(not spec.italic, "syntax italics leaked into UI text: " .. group)
    assert(not spec.bg, "opaque background masks row selection: " .. group)
    assert(spec.fg and contrast(spec.fg, hl("NormalFloat").bg) >= 4.5, "unreadable UI text: " .. group)
    assert(contrast(spec.fg, hl("SnacksPickerListCursorLine").bg) >= 4.5, "unreadable selected UI text: " .. group)
  end
  color("SnacksPicker", "bg", "#010409")
  color("SnacksPickerInput", "bg", "#010409")
  color("SnacksPickerList", "bg", "#010409")
  color("SnacksPickerPrompt", "bg", "#010409")
  color("SnacksPickerInputSearch", "bg", "#010409")
  color("SnacksPickerToggleHidden", "bg", "#010409")
  color("SnacksTitle", "bg", "#010409")
  color("SnacksWinSeparator", "bg", "#010409")
  color("SnacksPickerListCursorLine", "bg", "#21262d")
  assert(not hl("SnacksPickerListCursorLine").fg, "selection must preserve file/Git foregrounds")
  print("PASS: readable upright UI labels, no row-background patches, consistent panel/prompt colors and neutral statusline")
  for _, name in ipairs({ "FloatBorder", "SnacksPickerBorder", "SnacksPickerPreviewBorder", "BlinkCmpMenuBorder",
    "BlinkCmpDocBorder", "BlinkCmpSignatureHelpBorder", "TelescopeBorder", "WhichKeyBorder" }) do
    color(name, "fg", "#6e7681")
    assert(hl(name).fg ~= hl("NormalFloat").bg, "invisible border: " .. name)
  end
  assert(vim.g.terminal_color_1 == "#ff7b72" and vim.g.terminal_color_15 == "#ffffff")
  print("PASS: VS Code palette, personal overrides, Python italics, semantic tokens, alpha blending and plugin highlights")

  local preview_lines = { "```typescript", "const answer: number = 42;", "```", "", "Some documentation." }
  local preview_buf, win = vim.lsp.util.open_floating_preview(preview_lines, "markdown", {})
  border(win, "native LSP preview")
  assert(vim.wo[win].conceallevel == 2 and vim.wo[win].concealcursor == "nvic", "hover language label is not concealed")
  vim.api.nvim_set_current_win(win)
  assert(vim.wo.concealcursor == "nvic", "focusing the hover reveals its language label")
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false), preview_lines), "hover code fences were stripped")
  local parser = vim.treesitter.get_parser(preview_buf)
  parser:parse()
  local injected = false
  parser:for_each_tree(function(_, tree)
    if tree:lang() == "typescript" then injected = true end
  end)
  assert(injected, "concealed hover lost TypeScript syntax injection")
  vim.api.nvim_win_close(win, true)
  print("PASS: hover language labels stay concealed when focused; code, documentation and language injection are preserved")
  local namespace = vim.api.nvim_create_namespace("theme_test")
  vim.diagnostic.set(namespace, 0, { { lnum = 0, col = 0, message = "Border test", severity = vim.diagnostic.severity.WARN } })
  _, win = vim.diagnostic.open_float({ scope = "buffer", focusable = false })
  assert(win, "diagnostic float did not open")
  border(win, "diagnostic float")
  vim.api.nvim_win_close(win, true)
  vim.diagnostic.reset(namespace)

  vim.fn.mkdir(temp, "p")
  vim.fn.writefile({ "def greet():", '    return "hello"' }, temp .. "/sample.py")
  for _, preset in ipairs({ "default", "vertical" }) do
    local picker = Snacks.picker.files({ cwd = temp, layout = { preset = preset } })
    assert(vim.wait(5000, function()
      return picker:count() > 0 and picker.shown and not picker:is_active() and picker.preview.win:valid()
    end, 20), "picker not ready: " .. preset)
    border(picker.preview.win.win, preset .. " picker preview")
    local bordered_box = false
    for _, box in pairs(picker.layout.box_wins) do
      if box:valid() and box.opts.border and box.opts.border ~= "none" then
        border(box.win, preset .. " picker frame")
        bordered_box = true
      end
    end
    assert(bordered_box, "picker has no bordered result/input frame: " .. preset)
    picker:close()
    vim.wait(100)
  end
  print("PASS: actual LSP/diagnostic floats and wide/narrow picker frames/previews have rounded borders")

  vim.fn.mkdir(temp .. "/docs", "p")
  vim.fn.mkdir(temp .. "/.hidden", "p")
  vim.fn.writefile({ "guide" }, temp .. "/docs/guide.txt")
  vim.fn.writefile({ "fixture" }, temp .. "/.hidden/config.txt")
  local explorer = Snacks.explorer({ cwd = temp, hidden = true })
  assert(vim.wait(5000, function()
    return explorer.shown and explorer:count() >= 3 and not explorer:is_active()
  end, 20), "explorer UI not ready")
  local labels = table.concat(vim.api.nvim_buf_get_lines(explorer.list.win.buf, 0, -1, false), "\n")
  assert(labels:find(".hidden", 1, true) and labels:find("docs", 1, true), "explorer fixture folders are missing")
  assert(not hl("SnacksPickerDirectory").italic and not hl("SnacksPickerFile").bg)
  assert(contrast(hl("SnacksPickerPathHidden").fg, hl("SnacksPickerList").bg) >= 4.5)
  assert(contrast(hl("SnacksPickerTotals").fg, hl("SnacksPickerInput").bg) >= 4.5)
  explorer:close()
  vim.wait(100)
  print("PASS: real explorer initializes with readable hidden folders/counts and upright background-free labels")

  vim.cmd.colorscheme("habamax")
  vim.cmd.colorscheme("github_personal")
  color("Normal", "fg", "#d7d8da")
  color("GitSignsAdd", "fg", "#4ae04a")
  assert(hl("@keyword.import.python").italic)
  assert(not hl("SnacksPickerDirectory").italic)
  assert(not hl("SnacksPickerFile").bg)
  print("PASS: local colorscheme can be reloaded after switching themes")
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  vim.fn.delete(temp, "rf")
  if not ok then io.stderr:write(err .. "\n") end
  vim.cmd(ok and "qa!" or "cquit 1")
end)
