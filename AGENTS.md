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
| `lua/config/lsp.lua` | Shared diagnostics and LSP mappings |
| `lua/config/languages/` | Language-specific servers, tools, formatter and LSP settings |
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
| `justfile` | Setup and test commands (`just` lists recipes) |
| `KEYMAPS.md` | Full keybinding reference |

## Adding language support

Language modules in `lua/config/languages/` declare `servers` (lspconfig names),
`tools` (Mason package names), `formatters_by_ft` and optional Conform `formatters`.
Register new modules in `init.lua`; its `setup_lsp` calls each module's optional
`setup_lsp` after nvim-lspconfig loads. Shared Mason, Conform, LSP and completion
wiring stays in `lua/plugins/languages.lua` and `lua/config/lsp.lua`. SQL's nvim-lint
setup lives in `sql.lua` and is loaded on SQL filetypes. Copilot and Tree-sitter CLI
are shared infrastructure, not per-language modules. Group related languages when
that avoids duplicating formatter or schema configuration. Check Mason and plugin
support, add integration coverage in `tests/languages.lua`, and run `just test`.

## Tests

```sh
just                    # list recipes
just setup              # start Neovim; first launch bootstraps plugins and Mason tools
just health             # open the interactive :checkhealth report
just test               # all supported suites; nonzero if any fail
just test-suite theme   # one suite (see table below)
just test-ts-shutdown   # upstream probe; currently expected to fail, see SPEC.md
```

`just` requires the active Neovim config (`NVIM_APPNAME`/`XDG_CONFIG_HOME` included)
to resolve to this checkout for setup, health and the normal suites. Setup is interactive;
it does not wait for background installs to complete.

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
