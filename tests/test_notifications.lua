-- Snacks notifier toasts: placement, focus, expiry, history and colors.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")

local function toasts()
  return vim.tbl_filter(function(win)
    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_notif"
  end, vim.api.nvim_list_wins())
end

local T = MiniTest.new_set({ hooks = h.no_errors })

T["toast is a non-focusable float on the right"] = function()
  local main = vim.api.nvim_get_current_win()
  local before = vim.fn.execute("messages")
  vim.notify("Copied @src/main.ts#L12-20", vim.log.levels.INFO, { timeout = 300, id = "toast-test" })
  h.wait(function() return #toasts() > 0 end, "notification did not open a toast", 2000)
  local win = toasts()[1]
  local config = vim.api.nvim_win_get_config(win)
  assert(config.relative == "editor" and not config.focusable, "toast is not a non-focusable editor float")
  h.assert_rounded(win, "toast")
  assert(config.col > vim.o.columns / 2, "toast is not on the right")
  h.eq(vim.api.nvim_get_current_win(), main)
  h.eq(vim.fn.execute("messages"), before)
end

T["toast uses the float palette"] = function()
  h.eq(h.hl("SnacksNotifierInfo").bg, 0x161b22)
  h.eq(h.hl("SnacksNotifierBorderInfo").fg, 0x6e7681)
end

T["toast expires into history"] = function()
  h.wait(function() return #toasts() == 0 end, "toast did not expire", 2000)
  assert(#Snacks.notifier.get_history() > 0, "expired toast is missing from history")
end

T["theme reload keeps toast styling"] = function()
  vim.cmd.colorscheme("github_personal")
  h.eq(h.hl("SnacksNotifierInfo").bg, 0x161b22)
end

return T
