set shell := ["sh", "-eu", "-c"]
set positional-arguments

# List available commands.
default:
    @just --list --unsorted

# Start Neovim; first launch bootstraps plugins and Mason tools.
setup: _check-config
    nvim

# Open Neovim's interactive health report.
health: _check-config
    nvim -c checkhealth

# Run all mini.test suites (tests/test_*.lua), reporting every failure.
test: _check-config
    @failed=0; \
    for suite in smoke theme workflow notifications git navigation languages; do \
      printf '\n=== %s ===\n' "$suite"; \
      TEST_SUITE="$suite" nvim --headless "+luafile tests/run.lua" || failed=1; \
    done; \
    exit "$failed"

# Format all Lua with the Mason StyLua (twice: StyLua is not always idempotent).
fmt:
    @stylua="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin/stylua"; \
    "$stylua" lua tests init.lua && "$stylua" lua tests init.lua

# Check formatting without changing files; run before committing.
check:
    @"${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin/stylua" --check lua tests init.lua

# Fast feedback while iterating: every suite except the slow language servers.
test-fast: _check-config
    @failed=0; \
    for suite in smoke theme workflow notifications git navigation; do \
      printf '\n=== %s ===\n' "$suite"; \
      TEST_SUITE="$suite" nvim --headless "+luafile tests/run.lua" || failed=1; \
    done; \
    exit "$failed"

# Print startup time (best of five runs, milliseconds).
startup: _check-config
    @log=$(mktemp); best=""; \
    for i in 1 2 3 4 5; do \
      rm -f "$log"; \
      nvim --headless --startuptime "$log" -c 'lua vim.defer_fn(function() vim.cmd("qa!") end, 100)'; \
      t=$(awk '/NVIM STARTED/ {print $1}' "$log" | tail -1); \
      if [ -z "$best" ] || [ "$(echo "$t < $best" | bc)" = 1 ]; then best=$t; fi; \
    done; \
    rm -f "$log"; printf 'startup: %.1f ms (best of 5)\n' "$best"

# Run one suite, optionally only cases containing a filter: just test-suite git "reset"
test-suite suite filter="": _check-config
    @test -f "tests/test_$1.lua" || { printf 'Unknown suite: %s\n' "$1" >&2; exit 2; }; \
    TEST_SUITE="$1" TEST_FILTER="$2" nvim --headless "+luafile tests/run.lua"

# Probe the upstream TypeScript shutdown bug (currently expected to fail).
test-ts-shutdown:
    nvim --headless -u NONE '+luafile tests/ts_shutdown.lua'

# Avoid accidentally testing or bootstrapping a different Neovim config.
[private]
_check-config:
    @nvim --headless -u NONE -c 'lua if vim.uv.fs_realpath(vim.fn.stdpath("config")) ~= vim.uv.fs_realpath(vim.fn.getcwd()) then io.stderr:write("Active Neovim config is not this checkout; check NVIM_APPNAME and XDG_CONFIG_HOME.\n"); vim.cmd.cquit(1) end' -c qa
