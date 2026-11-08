# GitHub Personal

A local Neovim port of **GitHub Dark Default** from the official
[primer/github-vscode-theme](https://github.com/primer/github-vscode-theme), with
personal overrides from my VS Code `settings.json`. It does not depend on
`projekt0n/github-nvim-theme` or read the installed VS Code extension at runtime.

## Provenance

- Extension: `github.github-vscode-theme`, version **6.3.5**.
- `upstream/dark-default.json`: unmodified `themes/dark-default.json` from that
  installed extension, including its UI colors and complete TextMate token rules.
- SHA-256: `a81623253b9441beef340f9417fa02e668b54ad7238735b5db72de6fd1eae9ba`.
- The extension includes its generator in `src/theme.js` and palette in
  `src/colors.js`; the generated JSON is the exact artifact VS Code loads.
- `upstream/LICENSE.txt`: upstream MIT license, copyright 2020 Primer.

## Files and maintenance

- `../colors/github_personal.lua`: normal `:colorscheme github_personal` entry.
- `../lua/theme/github.lua`: UI, Vim syntax, Tree-sitter, LSP semantic-token,
  terminal, Snacks, Blink, which-key, lualine, bufferline, and Git highlight mappings.
- `overrides.json`: copied workbench colors, TextMate style overrides, and semantic
  style overrides from the GitHub Dark Default sections in VS Code settings.
- `../after/queries/python/highlights.scm`: distinguish flow keywords that the
  upstream parser otherwise groups with generic keywords or operators.
- `../tests/theme.lua`: color/style, query, reload, and actual float/picker borders.

Edit `overrides.json` for personal colors; edit the Lua mappings for differences
between VS Code scopes and Neovim captures. Restart Neovim after editing JSON/Lua
because Lua modules cache the decoded source. `:colorscheme github_personal`
reapplies the loaded theme and works after switching to another colorscheme.
Updating VS Code settings does not silently change an active Neovim session:
update this snapshot deliberately, then run the theme/smoke/language tests.

## Mapping decisions

- Editor background `#000000`, editor foreground `#d7d8da`, whitespace `#343333`.
- Added/modified/deleted Git signs and file decorations use `#4ae04a`, `#e2c08d`,
  and `#ff6b6b`; blame uses `#656d71`. Gitsigns uses the same sign colors for staged
  and unstaged changes, distinguished by thin/thick glyphs.
- Statusline foreground `#e1e4e8`; tab and breadcrumb groups use the corresponding
  personal overrides where a Neovim UI equivalent exists.
- Comments are italic. Python import/from, function-definition and flow keywords
  are italic. Python type captures and the `typeHint` semantic modifier carry the
  type italics; actual semantic-token availability depends on the language server.
- Explicit upstream token foregrounds remain explicit. For example, variables use
  TextMate's `#e6edf3` even though unclassified editor text is `#d7d8da`.
- Eight-digit UI colors are composited onto the relevant opaque background;
  Neovim highlight RGB does not support VS Code's per-color alpha channel.
- Native floating windows and completion documentation use the upstream widget
  background `#161b22`. Explorer and picker panels use the near-black sidebar
  background `#010409`, with black code previews. Border foreground uses `#6e7681`
  rather than the much dimmer upstream widget border `#30363d`.
  Neovim's global `winborder=rounded` covers native hover/signature/preview floats;
  diagnostics, completion/signature windows, and picker preview borders are also
  configured explicitly. Pickers are **Snacks**, not Telescope. Telescope highlight
  aliases are provided, but Telescope is neither installed nor configured.
- Snacks notification toasts use the native float background `#161b22`, rounded
  readable gray borders `#6e7681`, upright titles and severity-colored icons.
  Windows are opaque and non-focusable; no experimental native message UI is enabled.
- Native Markdown LSP previews keep code fences and their language labels concealed
  even when focused. The original fence text is retained for Tree-sitter language
  injection/highlighting; ordinary Markdown editing is not changed.
- UI labels use dedicated foreground-only, upright roles, not syntax groups or
  `NormalFloat`. This preserves whole-row selections and avoids italic directory
  names or opaque background patches. Paths, hidden/ignored names, result counts,
  completion detail text and which-key descriptions use readable muted gray
  `#8b949e`; tests require at least 4.5:1 contrast on both widget and selected-row
  backgrounds. Prompts/status columns and border/title/toggle chunks explicitly
  match their panel background, because those rendering paths do not inherit it.
- Statusline sections share `#0d1117`; mode accents change text color, not section
  backgrounds. Picker/input scratch buffers do not replace the source-file path
  and filetype in the global statusline.
- Diffview's Git sidebar uses the same upright foreground-only text and near-black
  panel roles as the explorer. Two-way review windows apply upstream removed-line/
  removed-text backgrounds on the old side and inserted-line/inserted-text colors
  on the new side, without changing ordinary editor colors. Read-only revision URIs
  and Git panel buffers do not replace the real file path in the global statusline.
- Bufferline uses personal modernEditorTab colors: black inactive tabs, `#0d1117`
  visible tabs and `#21262d` selected tabs, with upright directory prefixes and
  foreground-only modified-file accents. Diagnostics do not recolor tab labels.
- File icons use nvim-web-devicons rather than mini.icons' syntax-linked colors
  (`MiniIconsAzure` linked to the purple `Function` group). The common web-file
  colors in `../lua/config/icons.lua` match Material Icon Theme; other icons retain
  provider defaults. Icon glyphs are single-color Nerd Font characters, not VS Code
  SVGs. Icon colors survive theme reload and inherit the containing tab background.
- Upstream 6.3.5 emits an array instead of a color for `symbolIcon.constantForeground`;
  the Constant completion icon falls back to the upstream constant syntax color.

This is a palette/scope port, not a TextMate engine or a promise of pixel-identical
rendering. Tree-sitter grammars and Pyright semantic tokens differ from VS Code's
TextMate/Pylance scopes. Neovim has no equivalents for modern VS Code tab hover
states, focused breadcrumb interactions, or workbench-only widgets; those override
values are retained in the snapshot rather than inventing unrelated UI behavior.
Font shaping, weight, ligatures, spacing, and italics rendering remain terminal/font
settings, not colorscheme features.
