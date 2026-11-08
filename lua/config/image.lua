-- Snacks image terminal detection inside tmux.
--
-- Snacks only trusts tmux's client terminal name when `extended-keys` is exactly
-- `on`; with `always` (our tmux.conf) it falls back to an XTVERSION query whose
-- reply never reaches TermResponse under extended keys. Detection then times out
-- as "unknown" (no Kitty graphics) and the reply can leak in as typed keys, which
-- stalls pickers. Seed detection from tmux's client terminal name instead.
-- Mirrors snacks.image.terminal._detect (snacks 882c996); recheck on snacks updates.
local M = {}

function M.setup()
  if not vim.env.TMUX then return end
  local out = vim.fn.system({ "tmux", "display-message", "-p", "#{client_termname}" })
  if vim.v.shell_error ~= 0 then return end
  local term = vim.trim(out):gsub("^xterm%-", "")
  if term == "" then return end
  local terminal = require("snacks.image.terminal")
  if terminal._terminal then return end
  terminal._terminal = { terminal = term, version = "unknown" }
  -- Skipping snacks' detection also skips its tmux passthrough wrapper, without
  -- which tmux drops every graphics command (blank image area). Mirror it here.
  pcall(vim.fn.system, { "tmux", "set", "-p", "allow-passthrough", "all" })
  terminal.transform = function(data)
    return ("\027Ptmux;" .. data:gsub("\027", "\027\027")) .. "\027\\"
  end
end

return M
