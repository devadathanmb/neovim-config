# AGENTS.md

Personal Neovim config (plain lazy.nvim, Neovim 0.12+). Read [SPEC.md](SPEC.md) for the
goal, design decisions, status and known issues before changing anything; update it
when you finish work.

## Rules

- Install tools through Mason only (`~/.local/share/nvim/mason`). Never use
  Homebrew or other system-wide installs; the owner rejected that explicitly.
- Formatting stays manual (`Space lf`). Never add format-on-save.
- Plugin revisions are pinned in `lazy-lock.json`. Change them only deliberately
  (`:Lazy update <plugin>`), never as a side effect.
- Prefer maintained, best-in-class plugins; replace abandoned ones. Write a small local
  module only when no plugin fits (see bookmarks).
- Do not define a `FileChangedShell` autocmd: it replaces Neovim's reload/conflict
  handling, which protects unsaved edits from agent changes on disk.
- Keep the theme a data-driven port (`theme/*.json` → `lua/theme/github.lua`). UI
  highlight groups must not set opaque backgrounds that floats inherit incorrectly.
- Run the headless suites (see Tests) after changes. Visual or terminal-key
  behaviour also needs a check in a real terminal (an isolated tmux session works).
- Keep `README.md` minimal (requirements, install, credits). Put agent-facing detail
  here and decisions/status in `SPEC.md`; keybindings go in `KEYMAPS.md`.
- Do not commit, push or change the default editor unless asked.

## Layout

| Path | Responsibility |
| --- | --- |
| `init.lua` | Load order: options → autocmds → colorscheme → lazy → keymaps → bookmarks |
| `lua/config/options.lua` | Editor options (whitespace dots, Tree-sitter folds, clipboard) |
| `lua/config/autocmds.lua` | Indentation per filetype, yank highlight, external-change reload |
| `lua/config/keymaps.lua` | Global mappings (files, buffers, windows, UI toggles) |
| `lua/config/lsp.lua` | Server settings, diagnostics, LSP mappings |
| `lua/config/treesitter.lua` | Baseline parsers, on-demand install, custom GritQL parser, indentexpr |
| `lua/config/git.lua` | Gitsigns mappings, guarded resets, blame popup → PR lookup, Diffview config |
| `lua/config/bookmarks.lua` | Per-project bookmarks with text re-anchoring |
| `lua/config/copilot.lua` | Copilot server config, keys, statusline status |
| `lua/config/context.lua` | `Space y` agent context references |
| `lua/config/icons.lua` | Devicons colors matching the VS Code Material icon theme |
| `lua/plugins/*.lua` | lazy.nvim specs: editor, buffers, git, languages, navigation |
| `lua/theme/github.lua`, `theme/` | GitHub Dark Default port; upstream JSON + personal overrides |
| `snippets/` | Personal VS Code-format snippets (registered in `package.json`) |
| `tests/` | Headless regression suites |
| `KEYMAPS.md` | Full keybinding reference |

## Tests

```sh
for t in smoke theme workflow notifications git navigation languages; do
  nvim --headless "+luafile ~/.config/nvim/tests/$t.lua" || echo "FAIL: $t"
done
nvim --headless -u NONE '+luafile ~/.config/nvim/tests/ts_shutdown.lua'  # expected to fail, see Known issues
```

| Suite | Covers |
| --- | --- |
| smoke | Startup, mappings, indentation, reload/conflict safety, pickers, buffer close |
| theme | Palette, overrides, Tree-sitter captures, float/picker borders, reload |
| workflow | Context references, icon colors, buffer tabs, safe close |
| notifications | Toast placement, focus, expiry, colors |
| git | Hunks, staging, reset safety, blame popup focus/PR keys, review, history |
| navigation | Bookmarks (persistence, re-anchoring, cross-file), Flash, Trouble |
| languages | Servers, diagnostics, completion, hover/rename, formatters, schemas |

Optional: `NVIM_TEST_ESLINT_NODE_MODULES=/path/to/node_modules` (ESLint end to end),
`NVIM_TEST_REMOTE_SCHEMAS=1` (remote Kubernetes schemas, needs network). Tests use
temporary files and repositories only. Use `+luafile`, not `nvim -l`.
