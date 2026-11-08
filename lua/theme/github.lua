local M = {}
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))
local function read(name)
  return vim.json.decode(table.concat(vim.fn.readfile(root .. "/theme/" .. name), "\n"))
end
local source = read("upstream/dark-default.json")
local overrides = read("overrides.json")
local colors = vim.tbl_extend("force", source.colors, overrides.colors)

-- VS Code alpha colors must be composited: terminal highlights only accept RGB.
function M.blend(hex, background)
  if #hex == 4 then
    hex = "#" .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2) .. hex:sub(4, 4):rep(2)
  end
  if #hex == 7 then
    return hex
  end
  assert(#hex == 9, "unsupported theme color: " .. hex)
  local alpha = tonumber(hex:sub(8, 9), 16) / 255
  local channels = {}
  for _, i in ipairs({ 2, 4, 6 }) do
    local fg = tonumber(hex:sub(i, i + 1), 16)
    local bg = tonumber(background:sub(i, i + 1), 16)
    channels[#channels + 1] = math.floor(fg * alpha + bg * (1 - alpha) + 0.5)
  end
  return string.format("#%02x%02x%02x", unpack(channels))
end

function M.color(key, background)
  return M.blend(assert(colors[key], "missing VS Code color: " .. key), background or colors["editor.background"])
end

local function settings(scope, rules)
  local result = {}
  for _, rule in ipairs(rules) do
    local scopes = type(rule.scope) == "table" and rule.scope or { rule.scope }
    if vim.tbl_contains(scopes, scope) then
      result = vim.tbl_extend("force", result, rule.settings)
    end
  end
  return result
end

-- This is an explicit scope-to-capture port, not a TextMate selector engine.
local function token(scope, fallback)
  local result = fallback and token(fallback) or {}
  local spec = vim.tbl_extend("force", settings(scope, source.tokenColors), settings(scope, overrides.tokenColors))
  if spec.foreground then
    result.fg = spec.foreground
  end
  if spec.background then
    result.bg = spec.background
  end
  if spec.fontStyle then
    for _, style in ipairs({ "italic", "bold", "underline", "strikethrough" }) do
      result[style] = spec.fontStyle:find(style, 1, true) ~= nil
    end
  end
  return result
end

function M.statusline()
  local fg, bg = M.color("statusBar.foreground"), M.color("statusBar.background")
  local function mode(accent)
    return {
      a = { fg = accent, bg = bg, gui = "bold" },
      b = { fg = fg, bg = bg },
      c = { fg = fg, bg = bg },
    }
  end
  return {
    normal = mode(fg),
    insert = mode(M.color("gitDecoration.addedResourceForeground")),
    visual = mode(token("entity.name.function").fg),
    replace = mode(M.color("gitDecoration.deletedResourceForeground")),
    command = mode(M.color("gitDecoration.modifiedResourceForeground")),
    inactive = mode(M.color("descriptionForeground")),
  }
end

function M.bufferline()
  local bg = M.color("modernEditorTab.inactiveBackground")
  local active = M.color("modernEditorTab.activeBackground")
  local visible = M.color("modernEditorTab.hoverBackground")
  local muted = token("comment").fg
  local fg = M.color("editor.foreground")
  local function text(color, background, bold)
    return { fg = color, bg = background, bold = bold or false, italic = false }
  end
  local highlights = {
    fill = { bg = bg },
    background = text(muted, bg),
    buffer_visible = text(fg, visible),
    buffer_selected = text(fg, active, true),
    tab = text(muted, bg),
    tab_selected = text(fg, active, true),
    tab_close = text(muted, bg),
    offset_separator = text(M.color("editorGroup.border"), M.color("sideBar.background")),
  }
  for _, state in ipairs({ "", "_visible", "_selected" }) do
    local surface = state == "_selected" and active or (state == "_visible" and visible or bg)
    highlights["close_button" .. state] = text(muted, surface)
    highlights["duplicate" .. state] = text(muted, surface)
    highlights["numbers" .. state] = text(muted, surface)
    highlights["modified" .. state] = text(M.color("gitDecoration.modifiedResourceForeground"), surface)
    highlights["separator" .. state] = text(M.color("editorGroup.border"), surface)
  end
  return highlights
end

function M.load()
  vim.cmd("highlight clear")
  vim.o.background = "dark"
  vim.g.colors_name = "github_personal"
  local c = M.color
  local fg, bg = c("editor.foreground"), c("editor.background")
  local float = c("editorWidget.background")
  local function set(name, value)
    vim.api.nvim_set_hl(0, name, value)
  end
  local function link(name, target)
    set(name, { link = target })
  end
  local function many(names, value)
    for _, name in ipairs(names) do
      set(name, vim.deepcopy(value))
    end
  end

  set("Normal", { fg = fg, bg = bg })
  link("NormalNC", "Normal")
  set("NormalFloat", { fg = fg, bg = float })
  -- Avoid Sidekick's float background; inherit the editor's default colors.
  set("SidekickChat", { fg = "NONE", bg = "NONE", nocombine = true })
  -- More visible than the upstream #30363d widget border on a black terminal.
  set("FloatBorder", { fg = c("editorLineNumber.foreground"), bg = float })
  set("FloatTitle", { fg = c("foreground"), bg = float, bold = true })
  set("FloatFooter", { fg = c("descriptionForeground"), bg = float })
  set("WinSeparator", { fg = c("editorGroup.border"), bg = bg })
  -- Gutter groups stay background-free so they inherit each window's Normal/NormalFloat;
  -- Snacks pads floats with a statuscolumn drawn in LineNr.
  set("LineNr", { fg = c("editorLineNumber.foreground") })
  set("CursorLineNr", { fg = c("editorLineNumber.activeForeground"), bold = true })
  set("CursorLine", { bg = c("editor.lineHighlightBackground") })
  link("CursorColumn", "CursorLine")
  set("SignColumn", { fg = fg })
  set("FoldColumn", { fg = c("editorLineNumber.foreground") })
  set("Folded", { fg = c("descriptionForeground"), bg = c("editor.foldBackground") })
  many({ "Whitespace", "NonText", "EndOfBuffer" }, { fg = c("editorWhitespace.foreground") })
  set("SnacksIndent", { fg = c("editorIndentGuide.background") })
  set("SnacksIndentScope", { fg = c("editorIndentGuide.activeBackground") })
  set("ColorColumn", { bg = c("tree.indentGuidesStroke") })
  set("Cursor", { fg = bg, bg = c("editorCursor.foreground") })
  link("lCursor", "Cursor")
  link("TermCursor", "Cursor")
  set("Visual", { bg = c("list.activeSelectionBackground") })
  link("VisualNOS", "Visual")
  set("Search", { fg = fg, bg = c("editor.findMatchHighlightBackground") })
  set("IncSearch", { fg = c("foreground"), bg = c("editor.findMatchBackground") })
  link("CurSearch", "IncSearch")
  set("MatchParen", { bg = c("editorBracketMatch.background"), bold = true })
  set("Pmenu", { fg = c("quickInput.foreground"), bg = c("quickInput.background") })
  set("PmenuSel", { fg = c("list.activeSelectionForeground"), bg = c("list.activeSelectionBackground", float) })
  set("PmenuSbar", { bg = c("scrollbarSlider.background", float) })
  set("PmenuThumb", { bg = c("scrollbarSlider.activeBackground", float) })
  link("PmenuMatch", "Special")
  set("PmenuMatchSel", { fg = c("list.highlightForeground"), bold = true })
  set("StatusLine", { fg = c("statusBar.foreground"), bg = c("statusBar.background") })
  set("StatusLineNC", { fg = c("descriptionForeground"), bg = c("statusBar.background") })
  set("TabLine", { fg = c("tab.inactiveForeground"), bg = c("modernEditorTab.inactiveBackground") })
  set("TabLineSel", { fg = c("tab.activeForeground"), bg = c("modernEditorTab.activeBackground") })
  link("TabLineFill", "TabLine")
  many({ "WinBar", "NavicText" }, { fg = c("breadcrumb.foreground") })
  set("WinBarNC", { fg = c("descriptionForeground") })
  set("DropBarIconUISeparator", { fg = c("breadcrumb.foreground") })
  many({ "DropBarCurrentContext", "DropBarHover" }, { fg = c("breadcrumb.activeSelectionForeground") })
  set("NavicSeparator", { fg = c("breadcrumb.foreground") })
  set("NavicContext", { fg = c("breadcrumb.activeSelectionForeground") })
  set("Directory", { fg = c("textLink.foreground") })
  set("Title", token("markup.heading"))
  set("ErrorMsg", { fg = c("errorForeground") })
  set("WarningMsg", { fg = c("notificationsWarningIcon.foreground") })
  set("MoreMsg", { fg = c("gitDecoration.addedResourceForeground") })
  set("Question", { fg = c("textLink.foreground") })
  set("Conceal", { fg = c("descriptionForeground") })
  set("SpecialKey", { fg = c("editorWhitespace.foreground") })
  set("QuickFixLine", { bg = c("list.focusBackground", float) })
  set("Substitute", { fg = bg, bg = token("entity.name").fg })

  for name, scope in pairs({
    Comment = "comment",
    Constant = "constant",
    String = "string",
    Character = "constant.character",
    Number = "constant",
    Boolean = "constant",
    Float = "constant",
    Identifier = "variable.other",
    Function = "entity.name.function",
    Statement = "keyword",
    Conditional = "keyword",
    Repeat = "keyword",
    Label = "keyword",
    Operator = "keyword",
    Keyword = "keyword",
    Exception = "keyword",
    PreProc = "keyword",
    Include = "keyword",
    Define = "storage",
    Macro = "entity.name.function",
    PreCondit = "keyword",
    Type = "entity.name",
    StorageClass = "storage",
    Structure = "storage",
    Typedef = "storage.type",
    Special = "support",
    SpecialChar = "constant.character",
    Tag = "entity.name.tag",
    Delimiter = "variable.other",
    SpecialComment = "comment",
    Debug = "support",
    Underlined = "markup.underline",
    Error = "invalid.illegal",
  }) do
    set(name, token(scope))
  end
  set("Todo", { fg = token("entity.name").fg, bold = true })
  set("Added", token("markup.inserted"))
  set("Removed", token("markup.deleted"))
  set("Changed", token("markup.changed"))
  set("DiffAdd", { bg = c("diffEditor.insertedLineBackground") })
  set("DiffDelete", { bg = c("diffEditor.removedLineBackground") })
  set("DiffChange", { bg = c("editor.wordHighlightStrongBackground") })
  set("DiffText", { bg = c("diffEditor.insertedTextBackground") })
  set("diffAdded", token("markup.inserted"))
  set("diffRemoved", token("markup.deleted"))
  set("diffChanged", token("markup.changed"))
  set("diffFile", token("meta.diff.header"))
  set("diffLine", token("meta.diff.range"))

  for severity, key in pairs({
    Error = "notificationsErrorIcon.foreground",
    Warn = "notificationsWarningIcon.foreground",
    Info = "notificationsInfoIcon.foreground",
    Hint = "descriptionForeground",
    Ok = "gitDecoration.addedResourceForeground",
  }) do
    local color = c(key)
    set("Diagnostic" .. severity, { fg = color })
    set("DiagnosticSign" .. severity, { fg = color })
    set("DiagnosticFloating" .. severity, { fg = color, bg = float })
    set("DiagnosticVirtualText" .. severity, { fg = color })
    set("DiagnosticUnderline" .. severity, { sp = color, undercurl = true })
  end
  set("DiagnosticDeprecated", { strikethrough = true })
  set("DiagnosticUnnecessary", { fg = c("descriptionForeground") })
  for _, name in ipairs({ "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
    set(name, { bg = c("editor.wordHighlightBackground") })
  end
  -- VS Code's default dark editorGhostText.foreground (#ffffff56), composited.
  set("ComplHint", { fg = M.blend("#ffffff56", bg) })
  set("ComplHintMore", { fg = c("descriptionForeground") })
  set("LspInlayHint", { fg = c("editorInlayHint.foreground"), bg = c("editorInlayHint.background") })
  link("LspSignatureActiveParameter", "Visual")
  for name, key in pairs({
    SpellBad = "notificationsErrorIcon.foreground",
    SpellCap = "notificationsWarningIcon.foreground",
    SpellLocal = "notificationsInfoIcon.foreground",
    SpellRare = "descriptionForeground",
  }) do
    set(name, { sp = c(key), undercurl = true })
  end

  local captures = {
    ["@variable"] = "variable.other",
    ["@variable.builtin"] = "variable.language",
    ["@variable.parameter"] = "variable.parameter.function",
    ["@variable.member"] = "meta.object.member",
    ["@constant"] = "constant",
    ["@constant.builtin"] = "constant",
    ["@constant.macro"] = "support.constant",
    ["@module"] = "meta.module-reference",
    ["@module.builtin"] = "support",
    ["@label"] = "entity.name",
    ["@string"] = "string",
    ["@string.documentation"] = "string",
    ["@string.regexp"] = "string.regexp",
    ["@string.escape"] = "constant.character",
    ["@string.special"] = "constant.character",
    ["@string.special.url"] = "string.other.link",
    ["@string.special.path"] = "string",
    ["@character"] = "constant.character",
    ["@number"] = "constant",
    ["@number.float"] = "constant",
    ["@boolean"] = "constant",
    ["@type"] = "entity.name",
    ["@type.builtin"] = "support",
    ["@type.definition"] = "entity.name",
    ["@attribute"] = "entity.name",
    ["@property"] = "meta.property-name",
    ["@function"] = "entity.name.function",
    ["@function.builtin"] = "support",
    ["@function.call"] = "entity.name.function",
    ["@function.macro"] = "entity.name.function",
    ["@function.method"] = "entity.name.function",
    ["@function.method.call"] = "entity.name.function",
    ["@constructor"] = "entity.name",
    ["@operator"] = "keyword",
    ["@keyword"] = "keyword",
    ["@keyword.function"] = "storage.type",
    ["@keyword.type"] = "storage.type",
    ["@keyword.import"] = "keyword",
    ["@keyword.return"] = "keyword",
    ["@keyword.operator"] = "keyword",
    ["@keyword.coroutine"] = "keyword",
    ["@keyword.modifier"] = "storage",
    ["@keyword.repeat"] = "keyword",
    ["@keyword.conditional"] = "keyword",
    ["@keyword.exception"] = "keyword",
    ["@keyword.directive"] = "keyword",
    ["@keyword.debug"] = "keyword",
    ["@punctuation.delimiter"] = "variable.other",
    ["@punctuation.bracket"] = "variable.other",
    ["@punctuation.special"] = "punctuation.section.embedded",
    ["@comment"] = "comment",
    ["@markup.heading"] = "markup.heading",
    ["@markup.strong"] = "markup.bold",
    ["@markup.italic"] = "markup.italic",
    ["@markup.strikethrough"] = "markup.strikethrough",
    ["@markup.underline"] = "markup.underline",
    ["@markup.quote"] = "markup.quote",
    ["@markup.math"] = "markup.inline.raw",
    ["@markup.raw"] = "markup.inline.raw",
    ["@markup.link"] = "constant.other.reference.link",
    ["@markup.link.url"] = "string.other.link",
    ["@markup.link.label"] = "constant.other.reference.link",
    ["@markup.list"] = "punctuation.definition.list.begin.markdown",
    ["@diff.plus"] = "markup.inserted",
    ["@diff.minus"] = "markup.deleted",
    ["@diff.delta"] = "markup.changed",
    ["@tag"] = "entity.name.tag",
    ["@tag.attribute"] = "meta.tag.attributes",
    ["@tag.delimiter"] = "variable.other",
    ["@string.special.key.json"] = "support.type.property-name.json",
    ["@string.special.key.jsonc"] = "support.type.property-name.json",
    ["@string.special.key.yaml"] = "entity.name.tag",
    ["@property.yaml"] = "entity.name.tag",
    ["@keyword.import.python"] = "keyword.control.import.python",
    ["@keyword.function.python"] = "storage.type.function.python",
    ["@keyword.return.python"] = "keyword.control.flow.python",
    ["@keyword.exception.python"] = "keyword.control.flow.python",
    ["@keyword.conditional.python"] = "keyword.control.flow.python",
    ["@keyword.repeat.python"] = "keyword.control.flow.python",
    ["@keyword.coroutine.python"] = "keyword.control.flow.python",
    ["@keyword.flow.python"] = "keyword.control.flow.python",
  }
  for name, scope in pairs(captures) do
    local fallback = scope:find("python", 1, true) and "keyword" or nil
    set(name, token(scope, fallback))
  end
  set("@type.python", vim.tbl_extend("force", token("entity.name"), { italic = true }))
  set("@type.builtin.python", vim.tbl_extend("force", token("support"), { italic = true }))

  -- Semantic tokens must not replace the syntax palette with Neovim defaults.
  for kind, target in pairs({
    namespace = "@module",
    type = "@type",
    class = "@type",
    enum = "@type",
    interface = "@type",
    struct = "@type",
    typeParameter = "@type",
    parameter = "@variable.parameter",
    variable = "@variable",
    property = "@variable.member",
    enumMember = "@constant",
    event = "@type",
    ["function"] = "@function",
    method = "@function.method",
    macro = "@function.macro",
    keyword = "@keyword",
    modifier = "@keyword.modifier",
    comment = "@comment",
    string = "@string",
    number = "@number",
    regexp = "@string.regexp",
    operator = "@operator",
    decorator = "@attribute",
    label = "@label",
  }) do
    link("@lsp.type." .. kind, target)
  end
  for selector, spec in pairs(overrides.semanticTokenColors) do
    if selector == "*.typeHint" then
      set("@lsp.mod.typeHint", { italic = spec.fontStyle == "italic" })
    elseif selector == "type:python" then
      set(
        "@lsp.type.type.python",
        vim.tbl_extend("force", token("entity.name"), { italic = spec.fontStyle == "italic" })
      )
    end
  end
  set("@lsp.mod.deprecated", { strikethrough = true })

  for change, key in pairs({ Add = "added", Change = "modified", Delete = "deleted" }) do
    local color = c("editorGutter." .. key .. "Background")
    many({
      "GitSigns" .. change,
      "GitSignsStaged" .. change,
      "GitSigns" .. change .. "Nr",
      "GitGutter" .. change,
      "SignifySign" .. change,
    }, { fg = color })
    set("SnacksDiff" .. change, { fg = color })
  end
  many(
    { "GitSignsCurrentLineBlame", "SnacksPickerGitStatusIgnored", "SnacksPickerIgnored" },
    { fg = c("gitlens.trailingLineForegroundColor") }
  )
  set("SnacksPickerGitStatusAdded", { fg = c("gitDecoration.addedResourceForeground") })
  set("SnacksPickerGitStatusModified", { fg = c("gitDecoration.modifiedResourceForeground") })
  set("SnacksPickerGitStatusDeleted", { fg = c("gitDecoration.deletedResourceForeground") })
  set("SnacksPickerGitStatusUntracked", { fg = c("gitDecoration.untrackedResourceForeground") })
  set("SnacksPickerGitStatusConflicted", { fg = c("gitDecoration.conflictingResourceForeground") })

  -- UI text needs foreground-only roles: syntax italics and opaque backgrounds
  -- break directory labels, selection rows, completion labels, and title chunks.
  set("GithubUiText", { fg = fg })
  set("GithubUiMuted", { fg = token("comment").fg })
  set("GithubUiHidden", { fg = token("comment").fg })
  set("GithubUiAccent", { fg = token("constant").fg })
  set("GithubUiPanel", { fg = fg, bg = c("sideBar.background") })
  set("GithubUiPanelBorder", { fg = c("editorLineNumber.foreground"), bg = c("sideBar.background") })
  set("GithubUiPanelTitle", { fg = c("sideBarTitle.foreground"), bg = c("sideBar.background"), bold = true })
  set("GithubUiPanelToggle", { fg = token("comment").fg, bg = c("sideBar.background") })
  -- Input prompts are statuscolumn text, which does not inherit the list background.
  set("GithubUiPanelPrompt", { fg = token("constant").fg, bg = c("sideBar.background") })
  set("GithubUiPanelSearch", { fg = fg, bg = c("sideBar.background") })
  set("GithubUiSelection", { bg = c("modernEditorTab.activeBackground") })
  set("GithubUiTree", { fg = c("editorLineNumber.foreground") })

  set("BookmarkSign", { fg = c("textLink.foreground") })
  -- Jump labels must pop against any syntax color (black on the keyword red).
  set("FlashLabel", { fg = bg, bg = token("keyword").fg, bold = true })
  set("FlashMatch", { fg = fg, bg = c("editor.findMatchHighlightBackground") })
  set("FlashCurrent", { fg = c("foreground"), bg = c("editor.findMatchBackground") })
  set("FlashBackdrop", { fg = token("comment").fg })
  for name, target in pairs({
    TroubleNormal = "GithubUiPanel",
    TroubleNormalNC = "GithubUiPanel",
    TroubleText = "GithubUiText",
    TroubleCount = "GithubUiAccent",
    TroubleFilename = "GithubUiText",
    TroubleDirectory = "GithubUiMuted",
    TroubleBasename = "GithubUiText",
    TroublePos = "GithubUiMuted",
    TroubleSource = "GithubUiMuted",
    TroubleCode = "GithubUiMuted",
    TroubleIndent = "GithubUiTree",
    TroubleIndentFoldClosed = "GithubUiTree",
    TroubleIndentFoldOpen = "GithubUiTree",
    TroublePreview = "Visual",
    TroubleIconDirectory = "GithubUiAccent",
  }) do
    link(name, target)
  end
  set("GitReviewRemovedLine", { bg = c("diffEditor.removedLineBackground") })
  set("GitReviewRemovedText", { bg = c("diffEditor.removedTextBackground") })
  set("GitReviewAddedLine", { bg = c("diffEditor.insertedLineBackground") })
  set("GitReviewAddedText", { bg = c("diffEditor.insertedTextBackground") })
  set("DiffviewFilePanelSelected", { fg = fg, bold = true })
  for name, target in pairs({
    FilePanelTitle = "GithubUiPanelTitle",
    FilePanelCounter = "GithubUiAccent",
    FilePanelRootPath = "GithubUiText",
    FilePanelFileName = "GithubUiText",
    FilePanelPath = "GithubUiMuted",
    FolderName = "GithubUiText",
    FolderSign = "GithubUiAccent",
    Dim1 = "GithubUiMuted",
    Primary = "GithubUiAccent",
    Secondary = "GithubUiText",
    Hash = "GithubUiAccent",
    Reference = "GithubUiAccent",
    StatusAdded = "GitSignsAdd",
    StatusUntracked = "GitSignsAdd",
    StatusModified = "GitSignsChange",
    StatusRenamed = "GitSignsChange",
    StatusCopied = "GitSignsChange",
    StatusDeleted = "GitSignsDelete",
    StatusIgnored = "GithubUiMuted",
    FilePanelInsertions = "GitSignsAdd",
    FilePanelDeletions = "GitSignsDelete",
    DiffDeleteDim = "GithubUiMuted",
  }) do
    link("Diffview" .. name, target)
  end

  for _, level in ipairs({ "Trace", "Debug", "Info", "Warn", "Error" }) do
    link("SnacksNotifier" .. level, "NormalFloat")
    link("SnacksNotifierBorder" .. level, "FloatBorder")
    link("SnacksNotifierTitle" .. level, "FloatTitle")
    link("SnacksNotifierFooter" .. level, "GithubUiMuted")
    link(
      "SnacksNotifierIcon" .. level,
      (level == "Trace" or level == "Debug") and "GithubUiMuted" or ("DiagnosticSign" .. level)
    )
  end

  for name, target in pairs({
    SnacksNormal = "NormalFloat",
    SnacksNormalNC = "NormalFloat",
    SnacksWinBar = "GithubUiPanelTitle",
    SnacksWinBarNC = "GithubUiPanelToggle",
    SnacksTitle = "GithubUiPanelTitle",
    SnacksFooter = "GithubUiPanelToggle",
    SnacksWinSeparator = "GithubUiPanelBorder",
    SnacksPicker = "GithubUiPanel",
    SnacksPickerBorder = "GithubUiPanelBorder",
    SnacksPickerTitle = "GithubUiPanelTitle",
    SnacksPickerInput = "GithubUiPanel",
    SnacksPickerInputBorder = "GithubUiPanelBorder",
    SnacksPickerInputTitle = "GithubUiPanelTitle",
    SnacksPickerList = "GithubUiPanel",
    SnacksPickerListBorder = "GithubUiPanelBorder",
    SnacksPickerListTitle = "GithubUiPanelTitle",
    SnacksPickerPreview = "Normal",
    SnacksPickerPreviewBorder = "GithubUiPanelBorder",
    SnacksPickerPreviewTitle = "GithubUiPanelTitle",
    SnacksPickerBox = "GithubUiPanel",
    SnacksPickerBoxBorder = "GithubUiPanelBorder",
    SnacksPickerBoxTitle = "GithubUiPanelTitle",
    SnacksInputNormal = "NormalFloat",
    SnacksInputBorder = "FloatBorder",
    SnacksInputTitle = "FloatTitle",
    SnacksPickerMatch = "PmenuMatchSel",
    SnacksPickerSearch = "PmenuMatchSel",
    SnacksPickerDirectory = "GithubUiText",
    SnacksPickerFile = "GithubUiText",
    SnacksPickerDir = "GithubUiMuted",
    SnacksPickerPathHidden = "GithubUiHidden",
    SnacksPickerPathIgnored = "GithubUiMuted",
    SnacksPickerIgnored = "GithubUiMuted",
    SnacksPickerTotals = "GithubUiMuted",
    SnacksPickerDimmed = "GithubUiMuted",
    SnacksPickerUnselected = "GithubUiMuted",
    SnacksPickerPrompt = "GithubUiPanelPrompt",
    SnacksPickerInputSearch = "GithubUiPanelSearch",
    SnacksPickerTree = "GithubUiTree",
    SnacksPickerSelected = "GithubUiAccent",
    SnacksPickerCursorLine = "GithubUiSelection",
    SnacksPickerListCursorLine = "GithubUiSelection",
    SnacksPickerPreviewCursorLine = "GithubUiSelection",
    SnacksPickerToggle = "GithubUiPanelToggle",
    SnacksPickerToggleHidden = "GithubUiPanelToggle",
    SnacksPickerToggleIgnored = "GithubUiPanelToggle",
    SnacksPickerToggleFollow = "GithubUiPanelToggle",
    SnacksPickerComment = "GithubUiMuted",
    SnacksPickerDesc = "GithubUiMuted",
    SnacksPickerDelim = "GithubUiMuted",
    SnacksPickerDiagnosticSource = "GithubUiMuted",
    SnacksPickerDiagnosticCode = "GithubUiMuted",
    SnacksPickerLink = "GithubUiMuted",
    SnacksPickerLabel = "GithubUiText",
    SnacksPickerBufFlags = "GithubUiMuted",
    WhichKey = "GithubUiAccent",
    WhichKeyGroup = "GithubUiText",
    WhichKeyDesc = "GithubUiText",
    WhichKeyBorder = "FloatBorder",
    WhichKeyNormal = "NormalFloat",
    WhichKeySeparator = "GithubUiMuted",
    WhichKeyValue = "GithubUiMuted",
    BlinkCmpMenu = "Pmenu",
    BlinkCmpMenuBorder = "FloatBorder",
    BlinkCmpMenuSelection = "PmenuSel",
    BlinkCmpLabel = "GithubUiText",
    BlinkCmpLabelMatch = "PmenuMatchSel",
    BlinkCmpLabelDeprecated = "DiagnosticDeprecated",
    BlinkCmpLabelDetail = "GithubUiMuted",
    BlinkCmpLabelDescription = "GithubUiMuted",
    BlinkCmpSource = "GithubUiMuted",
    BlinkCmpDoc = "NormalFloat",
    BlinkCmpDocBorder = "FloatBorder",
    BlinkCmpDocSeparator = "FloatBorder",
    BlinkCmpSignatureHelp = "NormalFloat",
    BlinkCmpSignatureHelpBorder = "FloatBorder",
    BlinkCmpSignatureHelpActiveParameter = "LspSignatureActiveParameter",
    TelescopeNormal = "GithubUiPanel",
    TelescopeBorder = "GithubUiPanelBorder",
    TelescopeSelection = "GithubUiSelection",
    TelescopeMatching = "PmenuMatchSel",
    TelescopePromptBorder = "GithubUiPanelBorder",
    TelescopeResultsBorder = "GithubUiPanelBorder",
    TelescopePreviewBorder = "GithubUiPanelBorder",
    TelescopePromptTitle = "GithubUiPanelTitle",
    TelescopePreviewTitle = "GithubUiPanelTitle",
  }) do
    link(name, target)
  end

  for _, kind in ipairs({
    "Array",
    "Boolean",
    "Class",
    "Color",
    "Constant",
    "Constructor",
    "Enum",
    "EnumMember",
    "Event",
    "Field",
    "File",
    "Folder",
    "Function",
    "Interface",
    "Key",
    "Keyword",
    "Method",
    "Module",
    "Namespace",
    "Null",
    "Number",
    "Object",
    "Operator",
    "Package",
    "Property",
    "Reference",
    "Snippet",
    "String",
    "Struct",
    "Text",
    "TypeParameter",
    "Unit",
    "Variable",
  }) do
    local key = "symbolIcon." .. kind:sub(1, 1):lower() .. kind:sub(2) .. "Foreground"
    local value = colors[key]
    -- Upstream 6.3.5 accidentally emits a palette array for Constant; use syntax color.
    local color = type(value) == "string" and c(key) or token("constant").fg
    many({ "BlinkCmpKind" .. kind, "SnacksPickerIcon" .. kind, "NavicIcons" .. kind }, { fg = color })
  end
  local ansi = {
    "Black",
    "Red",
    "Green",
    "Yellow",
    "Blue",
    "Magenta",
    "Cyan",
    "White",
    "BrightBlack",
    "BrightRed",
    "BrightGreen",
    "BrightYellow",
    "BrightBlue",
    "BrightMagenta",
    "BrightCyan",
    "BrightWhite",
  }
  for i, name in ipairs(ansi) do
    vim.g["terminal_color_" .. (i - 1)] = c("terminal.ansi" .. name)
  end
end

return M
