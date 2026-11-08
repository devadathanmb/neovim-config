# Keybindings

Space is leader. Uppercase matters: `Space B` = buffers, `Space b` = bookmarks.
These are normal-mode bindings unless noted otherwise.
Pause after Space to see which-key.

## Find and navigate

| Keys | Action |
| --- | --- |
| Space f / Space sf | Find files under cwd |
| Space sl | Project grep |
| Space sb | Search open buffers |
| Space sz | Search lines in current buffer |
| Space sL | Resume last search (not VS Code's new search tab) |
| Space ; | Command picker |
| Space e | Toggle explorer |
| Ctrl-e | Focus explorer and reveal current file |
| H / L | Previous / next buffer |
| Ctrl-h/j/k/l | Focus Neovim window left/down/up/right |
| Esc / Ctrl-n | Clear search highlighting |
| ]] / [[ | Next / previous reference to the symbol under the cursor |
| za / zc / zo / zR / zM | Toggle / close / open / open all / close all folds (Tree-sitter) |

In search inputs: Ctrl-j/k or Tab/Shift-Tab navigate results, Enter opens,
Esc or Ctrl-x closes. In normal picker mode, j/k also work. Standard picker
Ctrl-s/Ctrl-v open a horizontal/vertical split. Completion bindings are below.

## Search and replace (grug-far)

| Keys | Action |
| --- | --- |
| Space sr | Search and replace across the project (visual: prefill selection) |
| Space sw | Search and replace the word under the cursor |
| Space sR | Search and replace in the current file |

Opens a vertical split with editable Search/Replace/Files Filter/Flags/Paths
inputs; results update as you type (ripgrep). Inside it (local leader is Space,
`g?` lists everything): Space r replaces all matches, Space s writes lines you
edited in the results back to their files, Space o or Enter opens a match.
Nothing changes on disk until you replace or sync.

## Sessions (auto-session)

| Keys | Action |
| --- | --- |
| Space Ss | Find a saved session (picker) |
| Space Sr | Restore the session for the working directory |
| Space Sw | Save the session now |
| Space Sd | Delete the session for the working directory |
| Space St | Toggle session autosave |

Sessions save on exit and restore when Neovim starts in a directory without file
arguments (`nvim` or `nvim .`). Starting with files (`nvim a.txt`, commit messages)
neither restores nor autosaves, so quick edits never overwrite a project session. Home, Downloads, Desktop, `/` and `/tmp` are never saved. Tool windows
(explorer, pickers, Diffview, Trouble, agent panel, grug-far) are closed first.

## Buffers

| Keys | Action |
| --- | --- |
| Ctrl-x / Space Bd | Close buffer safely; preserve split layout |
| Space Bc | Close other buffers (prompts for unsaved changes) |
| Space Bb | List buffers |
| Space Bn / Space Bp | Next / previous buffer |
| Space BN | New scratch buffer |
| Space By | Copy entire buffer to system clipboard |

The top bar uses bufferline.nvim to display open file buffers. Click to select;
click × or middle-click to close safely (modified files prompt). Duplicate filenames
include directory prefixes. H/L and Space Bn/Bp follow the same buffer-number order.
Tool/picker buffers are excluded; these are buffer tabs, not Neovim tab pages.

Neovim buffers are not VS Code editor tabs. Closing a buffer removes it from all
windows displaying it, while retaining the windows. Ctrl-x closes a tool window
instead when used in a special buffer. Ctrl-x in a picker closes the picker; it
does not delete its selected buffer.

## Files

| Keys | Action |
| --- | --- |
| Space Fe | Reveal file in explorer for file operations |
| Space Fn | Open a new path; creates parent directories, save with :w |
| Space Fr | Rename current file |
| Space Fl / Space FL | Copy cwd-relative / absolute file path |

Explorer keys:

- j/k, gg/G: navigate; h: collapse; l, Enter, o: expand/open.
- a: add file; use a trailing `/` to create a directory.
- r: rename; m: move; c: copy; d: delete (confirmation / system trash).
- y: yank file path(s) for p to copy/paste. **Unlike VS Code, y is not the
  relative-path clipboard shortcut.** Use Space Fl/FL from the file buffer.
- Tab: select files for batch operations; this differs from search-input Tab.
- `/`: filter/search the explorer; Esc closes the picker from its input.
- H: toggle hidden files; I: toggle ignored files.
- Ctrl-x: close explorer; Ctrl-l: focus editor to its right.

Initially copy/move/delete are explorer operations, not duplicated under every
VS Code Space F shortcut. Destructive shortcuts are intentionally not global.
Space Fn is relative to cwd, not the explorer's selected directory; explorer a
is the selected-directory equivalent.

## Agent context

| Keys | Action |
| --- | --- |
| Space y | Copy current file/line reference to the system clipboard |
| Visual Space y | Copy selected line range to the system clipboard |

Examples: `@src/main.ts#L12` and `@src/main.ts#L12-20`. This matches the Claude
format in the installed VS Code Context Link extension (not `:L12`). Normal mode
always includes the current line; visual character/line/block selections include
whole line numbers, not the selected text. Paths are cwd-relative, with an absolute
fallback outside cwd. Unnamed and tool buffers warn without changing the clipboard.
Space y does not change normal Vim y or start an agent/send any content.

## Windows

| Keys | Action |
| --- | --- |
| Space h / Space v | Horizontal / vertical split |
| Space wh/wj/wk/wl | Move window left/down/up/right |
| Space wW | Focus previously used window |
| Space w= | Equalize window sizes |
| Space wm | Maximize current window; Space w= restores equal sizes |
| Space wr | Resize mode: h/l narrower/wider, j/k shorter/taller (H/J/K/L in steps of 10), = equalize; any other key (Esc) finishes |
| Space wd | Close window, not buffer |

## Editing and configuration

- Visual p: paste without replacing the yank register.
- Visual < / >: indent while retaining selection.
- j/k: move by display line when wrapping; counted motions retain real-line behavior.
- Surround (nvim-surround): `ysiw"` surrounds a word with quotes; `cs"'` changes
  quotes; `ds"` removes quotes; visual `S` surrounds selection; `dsf` removes a
  function call; `.` repeats.
- Auto-pairs: typing `(`, `[`, `{`, quotes inserts the closing pair (insert mode only).
- Space uw: toggle wrapping. Space ui: toggle indent guides. Space u.: toggle whitespace dots.
- Space uh: toggle LSP inlay hints for the buffer (off by default, as in Pylance).
- Space gg: open lazygit in a float (files opened from it land in Neovim).
- Space .: toggle a per-project scratch buffer (filetype follows the current file, else Markdown; in a Lua scratch, Enter runs it). Space s.: pick saved scratches.
- Space ub: toggle breadcrumbs (file path → enclosing symbols; clickable menus).
- Space uz: toggle zen mode (centered, distraction-free, dims other blocks; hides breadcrumbs and inline blame without losing their settings).
- Space um: toggle Markdown rendering everywhere (`:RenderMarkdown buf_toggle` for one buffer).
- Space pL: plugin manager.
- Space pk: this reference.
- Space pp: SPEC.md (design and status).

## Language actions

| Keys | Action |
| --- | --- |
| gd / gr / gi / gt | Definition / references / implementation / type definition |
| gpd / gpi / gpt | Preview definition / implementation / type results |
| gh | Definition preview picker |
| K / Space lh | Hover |
| gq / Space la | Code actions (Space la also in visual mode) |
| gl | Line diagnostics |
| Space ld / Space lD | Document / workspace diagnostics |
| ]d / [d, Space lj / Space lk | Next / previous diagnostic |
| ]e / [e | Next / previous error |
| Space lr / Space rs | Rename symbol |
| Space ls / Space ss | Document symbols |
| Space li | Organize imports (Ruff for Python) |
| Space lf | Format document manually |
| Visual Space lv | Format selection through Conform |
| Space lm | Change filetype |
| Space pM | Mason tool manager |

Goto mappings are buffer-local when an LSP attaches and require server support.
`gq`, `gr`, and `gt` intentionally replace their native Vim meanings in LSP buffers.
Neovim's default `grn`/`gra`/`grr`/`gri`/`grt`/`grx` maps are removed so `gr` fires
immediately instead of waiting for a longer key sequence.
Peek opens a picker with a preview rather than a VS Code inline peek widget.

In insert-mode completion: Ctrl-j/k, Ctrl-n/p, Tab/Shift-Tab navigate; Enter
accepts; Ctrl-e dismisses; Ctrl-Space requests completion and Ctrl-; toggles it
(Ctrl-; requires terminal support for extended keys). Snippets show with a `~`
suffix; Enter expands one. While a snippet is active, Tab/Shift-Tab jump between its
placeholders (use Ctrl-j/k for the menu); otherwise Tab falls back to indentation. The first item is preselected
but does not insert text until accepted. No ghost text is enabled.

Formatting is never automatic on save. Black/SQLFluff are document formatters;
Conform handles selection formatting as supported by the formatter/diff behavior.

## Git and reviewing agent changes

| Keys | Action |
| --- | --- |
| Space gt | Open repository changes in Diffview |
| Space gD | Review staged changes (HEAD versus index) |
| Space gq | Close Git review/history and return to editor |
| Space gh / Space gH | Current file / repository history |
| Space gj / Space gk or ]c / [c | Next / previous hunk |
| Space gv | Preview hunk in a rounded float |
| Space gs | Stage/unstage current hunk; visual mode selects a line range |
| Space gS | Stage current file buffer, including unsaved edits |
| Space gU | Unstage current file, keeping working-tree and buffer edits |
| Space gr | Reset unstaged hunk; visual mode selects lines; confirmation required |
| Space gR | Reset all unstaged buffer edits; confirmation required |
| Space gb | Blame line in a focused popup (j/k scroll); inside: o open PR, y copy PR link, c open commit, q/Esc close |
| Space gp / Space gP | Open / copy the PR that introduced the current line (falls back to the commit page) |
| Space gB | Toggle delayed inline blame (enabled initially) |

Hunk/blame/stage/reset mappings are buffer-local to files attached to Gitsigns.
Gutter signs show unstaged changes as thick bars and staged changes as thin bars;
diagnostics may take sign-column priority. Untracked files appear in Diffview but
do not receive Gitsigns actions until tracked; stage them explicitly from review.
These are a deliberate subset of VS Code Git bindings: Space gp is not repurposed
from push, but checkout/branch/commit/push/stash shortcuts are not configured.

Start with Space gt, select a changed file, review the old/new sides, then close
with Ctrl-x or Space gq. Working changes compare index versus working tree; staged
changes compare HEAD versus index. Diffview uses its own Neovim tab page, while
the top buffer bar remains a buffer list. In review/history:

- j/k, h/l, Enter/o: navigate/collapse/open panel entries.
- Tab/Shift-Tab or H/L: next/previous changed file.
- Ctrl-e: focus the Git file panel; Ctrl-h/j/k/l: normal window navigation.
- File panel s: explicitly stage/unstage the selected file; R: refresh changes.
- gf: open the file back in the editor tab; Ctrl-x/Space gq: close the entire review.
  Panel q also closes review. Default restore, stage-all and merge-resolution
  shortcuts are disabled; these are not a configured merge-tool workflow.

Reset compares against the index, not necessarily HEAD. It edits only the buffer,
leaves the file unsaved, and can be undone with u; :w applies it to disk. Cancel is
the first choice. If the buffer/hunk context changes while confirmation is open,
the reset is refused. Staging changes the real Git index only when you request it.
No automatic staging, commit, fetch or push actions are enabled.

## Bookmarks (VS Code Bookmarks layout)

| Keys | Action |
| --- | --- |
| Space bt / Space bm | Toggle bookmark on the current line |
| Space bj / Space bk | Next / previous bookmark across files (wraps) |
| Space bl / Space sm | Project bookmarks picker (Ctrl-d deletes the selected one) |
| Space bL | Current-file bookmarks picker |
| Space bc / Space bC | Clear bookmarks in this file / whole project (confirm) |

Bookmarks are per working directory, saved under `~/.local/share/nvim/bookmarks/`,
follow line edits, and are re-anchored by line text when an agent rewrites the file.
Deleting a bookmarked line removes its bookmark.

## Movement (Flash: Sneak + EasyMotion)

| Keys | Action |
| --- | --- |
| s{chars}{label} | Jump anywhere visible: type a char or two, then the red label |
| S | Select a Tree-sitter node with labels (normal/operator; visual S stays surround) |
| f/t/F/T then ; , | Native line-local char motions, with highlighted targets |
| Operator + r | Remote action, e.g. `yr` + jump yanks there and returns |
| Operator/visual R | Tree-sitter search selection |
| / then Ctrl-s | Toggle Flash labels during a normal search |

## Problems and lists (Trouble)

| Keys | Action |
| --- | --- |
| Space xx / Space xX | Problems panel: workspace / current file |
| Space xq / Space xl | Quickfix / location list panel |
| Space xs | Symbols outline (right) |
| Space xr | LSP references/definitions panel |
| ]q / [q | Next / previous item (Trouble when open, else quickfix) |

Enter jumps, q closes, o jumps and closes, p previews. Space ld/lD remain the
picker-style diagnostics search.

## Copilot

| Keys | Action |
| --- | --- |
| Tab | Accept grey suggestion when the menu is closed and no snippet is active |
| Ctrl-l | Accept suggestion (always) |
| Alt-] / Alt-[ | Next / previous alternative suggestion |
| Ctrl-] | Dismiss suggestion |
| Space uc | Toggle Copilot suggestions |

Statusline icon: hidden when Copilot is not attached, plain when ready, blue while
working, yellow for warnings, red for errors (e.g. not signed in), `off` when toggled
off. Clicking it signs in, shows the problem, or toggles suggestions.
Sign in once with `:LspCopilotSignIn`.

## Agent panel

| Keys | Action |
| --- | --- |
| Space aa | Toggle the current agent panel |
| Space as | Select an installed agent |
| Space ad | Detach the current agent session |
| Space af | Send the current file reference to the agent |
| Space at | Send current context (or visual selection) to the agent |
| Space ap | Select an agent prompt |

In the panel, Ctrl-z returns to the editor, Ctrl-h moves left, Ctrl-q enters
terminal normal mode, and q hides the panel from normal mode. Agent CLIs must be
installed separately. Sidekick does not enable Copilot next-edit suggestions.
