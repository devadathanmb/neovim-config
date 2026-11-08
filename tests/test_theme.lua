-- GitHub theme port: palette, overrides, Tree-sitter captures, borders, reload.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local theme = require("theme.github")
local temp

local function color(name, field, hex)
  h.eq({ name, field, h.hl(name)[field] }, { name, field, tonumber(hex:sub(2), 16) })
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
  local x, y = luminance(foreground), luminance(background)
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end
local function captures(lang, lines, positions)
  local buf = vim.api.nvim_create_buf(false, true)
  MiniTest.finally(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.treesitter.start(buf, lang)
  vim.treesitter.get_parser(buf, lang):parse()
  return vim.tbl_map(function(pos)
    return vim.tbl_map(function(c)
      return c.capture
    end, vim.treesitter.get_captures_at_pos(buf, pos[1], pos[2]))
  end, positions)
end

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      temp = h.tempdir()
    end,
    pre_case = h.no_errors.pre_case,
    post_case = h.no_errors.post_case,
    post_once = function()
      vim.fn.delete(temp, "rf")
    end,
  },
})

T["palette"] = MiniTest.new_set()

T["palette"]["local theme replaces the plugin"] = function()
  h.eq(vim.g.colors_name, "github_personal")
  assert(not require("lazy.core.config").plugins["github-nvim-theme"], "old theme plugin still enabled")
  h.eq(vim.o.winborder, "rounded")
  assert(h.hl("SidekickChat").bg == nil and h.hl("SidekickChat").fg == nil, "agent panel must use terminal defaults")
end

T["palette"]["editor, git and syntax colors"] = function()
  for _, spec in ipairs({
    { "Normal", "bg", "#000000" },
    { "Normal", "fg", "#d7d8da" },
    { "Whitespace", "fg", "#343333" },
    { "StatusLine", "fg", "#e1e4e8" },
    { "TabLineSel", "bg", "#21262d" },
    { "TabLine", "bg", "#000000" },
    { "NavicContext", "fg", "#61dafb" },
    { "GitSignsAdd", "fg", "#4ae04a" },
    { "GitSignsChange", "fg", "#e2c08d" },
    { "GitSignsDelete", "fg", "#ff6b6b" },
    { "GitSignsCurrentLineBlame", "fg", "#656d71" },
    { "SnacksPickerGitStatusAdded", "fg", "#4ae04a" },
    { "SnacksPickerGitStatusModified", "fg", "#e2c08d" },
    { "SnacksPickerGitStatusDeleted", "fg", "#ff6b6b" },
    { "Comment", "fg", "#8b949e" },
    { "@keyword", "fg", "#ff7b72" },
    { "@string", "fg", "#a5d6ff" },
    { "@function", "fg", "#d2a8ff" },
    { "@number", "fg", "#79c0ff" },
    { "@type", "fg", "#ffa657" },
    { "@variable", "fg", "#e6edf3" },
    { "@string.special.key.yaml", "fg", "#7ee787" },
    { "@string.special.key.json", "fg", "#7ee787" },
    { "@lsp.type.function", "fg", "#d2a8ff" },
    { "@lsp.type.variable", "fg", "#e6edf3" },
    { "CursorLine", "bg", "#0b0c0d" },
  }) do
    color(spec[1], spec[2], spec[3])
  end
  assert(h.hl("Comment").italic)
  h.eq(vim.g.terminal_color_1, "#ff7b72")
  h.eq(vim.g.terminal_color_15, "#ffffff")
end

T["palette"]["python italics stay python-only"] = function()
  for _, group in ipairs({
    "@keyword.import.python",
    "@keyword.function.python",
    "@keyword.return.python",
    "@keyword.conditional.python",
    "@keyword.repeat.python",
    "@keyword.flow.python",
    "@keyword.coroutine.python",
    "@type.python",
    "@type.builtin.python",
    "@lsp.type.type.python",
    "@lsp.mod.typeHint",
  }) do
    assert(h.hl(group).italic, "missing VS Code italic override: " .. group)
  end
  assert(not h.hl("@keyword").italic, "Python italics leaked into all languages")
end

T["palette"]["alpha blending"] = function()
  h.eq(theme.blend("#ffffff80", "#000000"), "#808080")
  h.eq(theme.blend("#00000000", "#123456"), "#123456")
end

T["tree-sitter"] = MiniTest.new_set()

T["tree-sitter"]["typescript highlight queries apply"] = function()
  for i, found in
    ipairs(captures("typescript", { "// comment", 'export const value = "hello"' }, { { 0, 0 }, { 1, 0 }, { 1, 21 } }))
  do
    assert(#found > 0, "TypeScript highlight queries missing at position " .. i)
  end
end

T["tree-sitter"]["python flow-scope query applies"] = function()
  local lines = { "assert True", "del value", "with resource:", "    pass" }
  for i, found in ipairs(captures("python", lines, { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 4 } })) do
    assert(vim.tbl_contains(found, "keyword.flow"), "Python flow-scope query not applied at position " .. i)
  end
end

T["ui"] = MiniTest.new_set()

T["ui"]["statusline is neutral"] = function()
  h.eq(theme.statusline().normal.c.fg:lower(), "#e1e4e8")
  for mode, sections in pairs(theme.statusline()) do
    for section, spec in pairs(sections) do
      h.eq({ mode, section, spec.bg }, { mode, section, "#0d1117" })
    end
  end
  color("lualine_a_normal", "bg", "#0d1117")
  color("lualine_a_normal", "fg", "#e1e4e8")
end

T["ui"]["labels are upright, readable and background-free"] = function()
  for _, group in ipairs({
    "SnacksPickerDirectory",
    "SnacksPickerFile",
    "SnacksPickerDir",
    "SnacksPickerPathHidden",
    "SnacksPickerPathIgnored",
    "SnacksPickerTotals",
    "SnacksPickerComment",
    "SnacksPickerDesc",
    "WhichKeyDesc",
    "BlinkCmpLabel",
    "BlinkCmpLabelDetail",
    "BlinkCmpLabelDescription",
    "BlinkCmpSource",
  }) do
    local spec = h.hl(group)
    assert(not spec.italic, "syntax italics leaked into UI text: " .. group)
    assert(not spec.bg, "opaque background masks row selection: " .. group)
    assert(spec.fg and contrast(spec.fg, h.hl("NormalFloat").bg) >= 4.5, "unreadable UI text: " .. group)
    assert(contrast(spec.fg, h.hl("SnacksPickerListCursorLine").bg) >= 4.5, "unreadable selected UI text: " .. group)
  end
end

T["ui"]["picker panels share one background"] = function()
  for _, group in ipairs({
    "SnacksPicker",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerPrompt",
    "SnacksPickerInputSearch",
    "SnacksPickerToggleHidden",
    "SnacksTitle",
    "SnacksWinSeparator",
  }) do
    color(group, "bg", "#010409")
  end
  color("SnacksPickerListCursorLine", "bg", "#21262d")
  assert(not h.hl("SnacksPickerListCursorLine").fg, "selection must preserve file/Git foregrounds")
end

T["ui"]["borders are visible"] = function()
  for _, name in ipairs({
    "FloatBorder",
    "SnacksPickerBorder",
    "SnacksPickerPreviewBorder",
    "BlinkCmpMenuBorder",
    "BlinkCmpDocBorder",
    "BlinkCmpSignatureHelpBorder",
    "TelescopeBorder",
    "WhichKeyBorder",
  }) do
    color(name, "fg", "#6e7681")
    assert(h.hl(name).fg ~= h.hl("NormalFloat").bg, "invisible border: " .. name)
  end
end

T["floats"] = MiniTest.new_set()

T["floats"]["hover keeps code, conceals language label"] = function()
  local preview_lines = { "```typescript", "const answer: number = 42;", "```", "", "Some documentation." }
  local buf, win = vim.lsp.util.open_floating_preview(preview_lines, "markdown", {})
  MiniTest.finally(function()
    pcall(vim.api.nvim_win_close, win, true)
  end)
  h.assert_rounded(win, "native LSP preview")
  h.eq({ vim.wo[win].conceallevel, vim.wo[win].concealcursor }, { 2, "nvic" })
  vim.api.nvim_set_current_win(win)
  h.eq(vim.wo.concealcursor, "nvic")
  h.eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), preview_lines)
  local parser = vim.treesitter.get_parser(buf)
  parser:parse()
  local injected = false
  parser:for_each_tree(function(_, tree)
    if tree:lang() == "typescript" then
      injected = true
    end
  end)
  assert(injected, "concealed hover lost TypeScript syntax injection")
end

T["floats"]["diagnostic float is rounded"] = function()
  local namespace = vim.api.nvim_create_namespace("theme_test")
  MiniTest.finally(function()
    vim.diagnostic.reset(namespace)
  end)
  vim.diagnostic.set(
    namespace,
    0,
    { { lnum = 0, col = 0, message = "Border test", severity = vim.diagnostic.severity.WARN } }
  )
  local _, win = vim.diagnostic.open_float({ scope = "buffer", focusable = false })
  assert(win, "diagnostic float did not open")
  h.assert_rounded(win, "diagnostic float")
  vim.api.nvim_win_close(win, true)
end

T["floats"]["picker frames and previews are rounded"] =
  MiniTest.new_set({ parametrize = { { "default" }, { "vertical" } } })

T["floats"]["picker frames and previews are rounded"]["layout"] = function(preset)
  vim.fn.writefile({ "def greet():", '    return "hello"' }, temp .. "/sample.py")
  local picker = Snacks.picker.files({ cwd = temp, layout = { preset = preset } })
  MiniTest.finally(function()
    picker:close()
    vim.wait(100)
  end)
  h.wait(function()
    return picker:count() > 0 and picker.shown and not picker:is_active() and picker.preview.win:valid()
  end, "picker not ready: " .. preset, 5000)
  h.assert_rounded(picker.preview.win.win, preset .. " picker preview")
  local bordered_box = false
  for _, box in pairs(picker.layout.box_wins) do
    if box:valid() and box.opts.border and box.opts.border ~= "none" then
      h.assert_rounded(box.win, preset .. " picker frame")
      bordered_box = true
    end
  end
  assert(bordered_box, "picker has no bordered result/input frame: " .. preset)
end

T["explorer shows readable hidden folders and counts"] = function()
  vim.fn.mkdir(temp .. "/docs", "p")
  vim.fn.mkdir(temp .. "/.hidden", "p")
  vim.fn.writefile({ "guide" }, temp .. "/docs/guide.txt")
  vim.fn.writefile({ "fixture" }, temp .. "/.hidden/config.txt")
  local explorer = Snacks.explorer({ cwd = temp, hidden = true })
  MiniTest.finally(function()
    explorer:close()
    vim.wait(100)
  end)
  h.wait(function()
    return explorer.shown and explorer:count() >= 3 and not explorer:is_active()
  end, "explorer UI not ready", 5000)
  local labels = table.concat(vim.api.nvim_buf_get_lines(explorer.list.win.buf, 0, -1, false), "\n")
  assert(labels:find(".hidden", 1, true) and labels:find("docs", 1, true), "explorer fixture folders are missing")
  assert(contrast(h.hl("SnacksPickerPathHidden").fg, h.hl("SnacksPickerList").bg) >= 4.5)
  assert(contrast(h.hl("SnacksPickerTotals").fg, h.hl("SnacksPickerInput").bg) >= 4.5)
end

T["colorscheme reloads after switching themes"] = function()
  vim.cmd.colorscheme("habamax")
  vim.cmd.colorscheme("github_personal")
  color("Normal", "fg", "#d7d8da")
  color("GitSignsAdd", "fg", "#4ae04a")
  assert(h.hl("@keyword.import.python").italic)
  assert(not h.hl("SnacksPickerDirectory").italic)
  assert(not h.hl("SnacksPickerFile").bg)
end

return T
