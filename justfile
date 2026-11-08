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
