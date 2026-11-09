# SPEC

Goal, decisions and status for this Neovim config. Working rules, layout and tests
are in [AGENTS.md](AGENTS.md). Keep this file current: record decisions here and tick
items off when done.

## Goal

A personal Neovim config (plain lazy.nvim, no distribution) that replaces VS Code for
daily work while keeping VS Code muscle memory where sensible. AI coding agents can
run outside Neovim in Ghostty/tmux or in a quick Sidekick terminal panel.

Languages: Python, TypeScript/JavaScript, PostgreSQL SQL, YAML/Kubernetes, JSON/JSONC,
INI, Lua, Markdown, Dockerfile, Bash/POSIX shell.

**Out of scope:** debugger, format-on-save,
Blink completion ghost text (Copilot ghost text is the only inline suggestion).

## Decisions

Editor and UI
- snacks.nvim provides explorer, pickers, input, notifier toasts, indent guides,
  word highlights, bigfile/quickfile. Not Telescope.
- Snacks image previews (Kitty graphics via tmux passthrough). Under tmux,
  `lua/config/image.lua` seeds terminal detection from `#{client_termname}`: snacks
  only does this itself when `extended-keys` is `on`, and with our `always` its
  XTVERSION query times out (images "unsupported") and its reply leaks as input,
  stalling the picker. Seeding skips snacks' own setup, so the module also
  installs its tmux passthrough wrapper (without it images render blank).
  Recheck after a deliberate snacks update.
- bufferline.nvim for tabs, lualine for the statusline, which-key for discovery.
  Buffer tab icons have a leading space (in addition to bufferline's trailing gap),
  so long filenames never press the icon against the selected tab's edge.
- dropbar.nvim for clickable winbar breadcrumbs (path → LSP symbols, Tree-sitter
  fallback; Markdown headings). Neovim provides the winbar but not the complete
  breadcrumb UI; barbecue.nvim is archived, and nvim-navic needs separate UI wiring.
  Dropbar is maintained and needs no extra fuzzy-search dependency. Disabled by
  default; when enabled, it appears in named normal file windows, not tool buffers,
  terminals or floats.
  `Space ub` toggles all windows; Zen hides breadcrumbs without changing that
  preference (toggling during Zen applies on exit). Winbar highlights have no opaque
  backgrounds, and menu floats inherit the theme's float colors.
- nvim-web-devicons, not mini.icons: its independent colors match Material icons.
- nvim-surround (classic `ys`/`cs`/`ds`), mini.pairs for auto-pairs.
- flash.nvim covers both Sneak and EasyMotion; no separate EasyMotion plugin.
  Visual `S` stays with nvim-surround; f/t stay line-local.
- Whitespace mirrors VS Code `renderWhitespace: boundary`.
- Native statuscolumn adds gutter padding around signs and line numbers while
  retaining relative numbers and fold indicators; no statuscolumn plugin.

Languages
- Language-specific server, tool and formatter declarations live in
  `lua/config/languages/`; shared plugin wiring and LSP mappings remain central.
- basedpyright (not pyright) for Pylance-like semantic tokens and completions;
  Ruff for lint/import actions; Black formats Python.
- Native TypeScript 7 LSP (`tsc --lsp`); ts_ls was removed because it fell back to TS6.
- ESLint attaches only where a project ESLint config exists.
- Biome formats JS/TS/JSON when the project has a Biome config, else Prettier.
- SQLFluff lints and formats SQL; the user default dialect is PostgreSQL
  (`~/.config/sqlfluff`), project configs override it. No database-backed completion.
- Dockerfiles use Mason-managed dockerls for diagnostics, completion and manual LSP
  formatting; Tree-sitter provides highlighting. No Docker daemon is required.
- Shell uses Mason-managed bash-language-server (the VS Code Bash IDE backend),
  ShellCheck diagnostics and manual shfmt formatting through Conform.
- Lua uses Mason-managed lua-language-server and StyLua for manual formatting; the
  Neovim config workspace gets LuaJIT, Neovim runtime and the installed Snacks/mini.test
  definitions (including their globals) without imposing them on other Lua projects.
  Editor settings and `just check-lua` share one settings builder; the audit checks
  every repository Lua file, including hint-level diagnostics. No global whitelist
  or project-wide diagnostic disables. StyLua respects project configuration.
- YAML/JSON use SchemaStore; Kubernetes schemas apply only to `*.k8s.yaml` and
  `k8s/`/`kubernetes/` directories, never all YAML.
- Blink completion with the Rust fuzzy matcher, friendly-snippets plus `snippets/`.
  Ctrl-Space requests completion; Ctrl-; toggles it (requires extended terminal keys).
  Tab: snippet placeholder → menu item → accept Copilot → indent.
- Tree-sitter parsers install on first use of a filetype; GritQL comes from the
  pinned biomejs/tree-sitter-gritql grammar.
- Copilot via the official copilot-language-server and Neovim's native inline
  completion (no copilot.lua). It never attaches to text, commit messages, help or
  secret-like files (`.env`, keys).

Git
- gitsigns for hunks/blame. Resets confirm with Cancel as default, refuse stale
  context, edit only the buffer and never save.
- diffview-plus.nvim (maintained fork; sindrets/diffview is unmaintained) for review
  and history, with unguarded default shortcuts disabled.
- Blame → PR: `gh api repos/{owner}/{repo}/commits/<sha>/pulls` (open and merged,
  squash merges included), commit page fallback via Snacks.gitbrowse.
- `Space gy` copies a commit-pinned file permalink for the current line or visual
  range through Snacks.gitbrowse, without opening a browser.

Other
- sidekick.nvim provides an optional agent CLI panel; its Copilot NES and file watcher
  are disabled to preserve existing Copilot and external-change handling. Its panel
  inherits editor defaults instead of the float background; ANSI colors remain themed.
  Its statusline shows the agent name instead of its executable path. Agent CLIs are
  installed separately; sessions do not persist across Neovim exits.
- render-markdown.nvim renders Markdown in the buffer (raw text on the cursor line),
  including LSP hovers; chosen over markview.nvim (smaller, frequent breaking majors).
  Loaded at startup as its README recommends: `ft` lazy-loading re-fires FileType.
  LaTeX rendering is off (no parser or converter installed).
- grug-far.nvim for project search and replace (reviewable, editable results; nothing
  is written until replace/sync). nvim-spectre is unmaintained.
- auto-session for per-directory sessions (chosen over persistence.nvim, which had
  no commits for a year). Saves on exit, restores on argument-less start, closes
  tool windows first, never runs headless. `sessionoptions` follows its README.
- trouble.nvim tracks `main`: v3.7.1 breaks on Neovim 0.12 and the fix is unreleased.
- Bookmarks are a local module: tomasky/bookmarks.nvim stores bookmarks globally and
  only navigates within one file. Ours are per cwd, cross-file, and re-anchor by line
  text after external reloads (Neovim keeps extmark rows, not content, on reload).
- Tests use mini.test (maintained, no luarocks; busted/nlua would need a system
  Lua toolchain, plenary's harness is barely maintained). Suites run in-process
  in the real config rather than in child Neovims, so plugins and servers are
  exercised as used; one Neovim per suite keeps suites isolated. Intentional test
  overrides of runtime functions use local LuaLS diagnostic suppressions where needed
  (for example, the workflow suite's `vim.notify` capture), not project-wide disables.
- Swap files stay on for crash recovery. Nvim already skips the prompt for swaps
  owned by a running Nvim and deletes unmodified swaps of dead processes; the
  prompt only appears when a dead session left unsaved changes (smoke-tested).
- Search, explorer and bookmarks are scoped to the working directory; no automatic
  root switching. Ctrl-h/j/k/l move between Neovim windows only.

## Status

Legend: `[x]` done and covered by tests, `[ ]` open. "Human" items need the owner's
real-world use and cannot be closed by tests.

### Phase 0 — Foundation
- [x] lazy.nvim bootstrap and pinned lockfile.
- [x] Options, clipboard, undo, indentation, theme, statusline, which-key.
- [x] External-change reload that never overwrites unsaved buffers.
- [ ] Human: appearance, clipboard with other apps, reload while agents edit files.

### Phase 1 — Navigation and editing
- [x] Explorer, file/grep/buffer pickers, buffer/window mappings, file operations.
- [x] Path and context-reference copying, surround, auto-pairs, visual paste.
- [ ] Human: navigation and file operations in a real project.
- [ ] Decide whether the `Space F` file aliases are worth keeping.

### Phase 2 — Language intelligence
- [x] LSP, completion, snippets, formatting, linting, schemas for all target languages.
- [x] On-demand Tree-sitter parsers, indentation and folding.
- [ ] Human: completion, hover, rename, code actions, Kubernetes schemas in real projects.

### Phase 3 — Reviewing agent changes
- [x] Git signs, hunks, staging, guarded resets, inline blame, Diffview review/history.
- [x] Blame popup with PR lookup (`Space gb`, `Space gp/gP`).
- [x] Diagnostics navigation, pickers and Trouble problems panel.
- [ ] Human: review an agent's change end to end with `Space gt`.

### Phase 4 — Bookmarks, movement, Copilot
- [x] Per-project bookmarks (`Space b`), Flash jumps.
- [x] Copilot wiring, keys and statusline status.
- [ ] Human: sign in to Copilot (`:LspCopilotSignIn`) and confirm suggestions appear.
- [ ] Human: bookmark persistence and movement comfort.
- [ ] Human: try the Sidekick agent panel and decide whether to keep it.

### Phase 5 — Stabilize and promote
- [ ] Fix friction found in daily use; remove unused features.
- [x] Seamless Neovim ↔ tmux pane navigation: not wanted. The owner uses separate tmux windows, not panes beside Neovim, and smart-splits would take Ctrl-l (clear) from shell panes.
- [x] Promoted to the default `nvim` (cloned into `~/.config/nvim` by the dotfiles setup); old minimal config and LazyVim retired.
- [x] Plugins and state moved to the default app name; Mason tools reinstalled.
- [x] Repaired migrated Tree-sitter query symlinks pointing at the retired `nvim-next` data directory; TypeScript syntax captures are regression-tested.
- [x] Snacks image previews work in Ghostty + tmux (detection workaround, see Decisions).
- [ ] Human: preview images in the picker and Markdown inside Ghostty + tmux.
- [x] Split the snacks spec into `lua/plugins/snacks.lua`.
- [x] Added grug-far search/replace and auto-session sessions, both test-covered.
- [ ] Human: try `Space sr` and session restore in real projects.
- [x] Added render-markdown.nvim and a startup-time guard (smoke suite, limit 150 ms).
- [ ] Human: read Markdown and hovers with rendering; tune or drop it.
- [x] Migrated the hand-rolled suites to mini.test: named cases, per-case reports,
  failures no longer stop a suite, `just test-suite <suite> <filter>`.
- [x] Added a justfile for interactive setup and health checks, individual or full headless suites, and the separate upstream shutdown probe.
- [x] Added dropbar breadcrumbs, the UI toggle and Zen suppression; covered by
  workflow, smoke and theme tests, plus an isolated tmux terminal check.
- [ ] Human: try breadcrumb menus and symbol navigation in daily projects.
- [x] Audited all LuaLS diagnostics: added missing plugin/test definitions, fixed
  nullable values and callable-table typing, and marked intentional test overrides
  locally. `just check-lua` guards against recurrence.

## Known issues

- **TypeScript 7 shutdown**: `tsc --lsp` exits 1 (`context canceled`/EOF) on graceful
  shutdown. Upstream bug, reproducible without Neovim; `tests/ts_shutdown.lua` fails
  on purpose until fixed. Recheck after a deliberate TypeScript update. Completion and
  diagnostics are unaffected.
- **diffview-plus close race**: closing file history while it is still opening can
  raise `Invalid window id` from its scroll sync.
- **Python completion ranking**: basedpyright auto-imports can outrank snippets for
  short prefixes.
