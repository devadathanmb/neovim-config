local function run()
  local function toasts()
    return vim.tbl_filter(function(win)
      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_notif"
    end, vim.api.nvim_list_wins())
  end
  local main = vim.api.nvim_get_current_win()
  local before = vim.fn.execute("messages")
  vim.notify("Copied @src/main.ts#L12-20", vim.log.levels.INFO, { timeout = 300, id = "toast-test" })
  assert(vim.wait(2000, function() return #toasts() > 0 end, 10), "notification did not open a toast")
  local win = toasts()[1]
  local config = vim.api.nvim_win_get_config(win)
  assert(config.relative == "editor" and not config.focusable, "toast is not a non-focusable editor float")
  assert(config.border[1] == "╭" and config.border[5] == "╯", "toast border is not rounded")
  assert(config.col > vim.o.columns / 2, "toast is not on the right")
  assert(vim.api.nvim_get_current_win() == main, "toast stole editor focus")
  assert(vim.fn.execute("messages") == before, "toast still printed to the message area")
  local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
  assert(hl("SnacksNotifierInfo").bg == 0x161b22, "toast does not match float palette")
  assert(hl("SnacksNotifierBorderInfo").fg == 0x6e7681, "toast border is too dim")
  assert(vim.wait(2000, function() return #toasts() == 0 end, 20), "toast did not expire")
  assert(#Snacks.notifier.get_history() > 0, "expired toast is missing from history")
  vim.cmd.colorscheme("github_personal")
  assert(hl("SnacksNotifierInfo").bg == 0x161b22, "theme reload lost toast styling")
  print("PASS: notification toast placement, border, focus, message-area replacement, expiry, history and colors")
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)
