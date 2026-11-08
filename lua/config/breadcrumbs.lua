local M = { enabled = false, zen = false }
local winbar = "%{%v:lua.dropbar()%}"

function M.allow(buf, win)
  return M.enabled
    and not M.zen
    and vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_win_is_valid(win)
    and vim.bo[buf].buftype == ""
    and vim.bo[buf].filetype ~= "help"
    and vim.api.nvim_buf_get_name(buf) ~= ""
    and vim.fn.win_gettype(win) == ""
    and (vim.wo[win].winbar == "" or vim.wo[win].winbar == winbar)
end

function M.refresh()
  local bar = require("dropbar.utils").bar
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if M.allow(buf, win) then
      bar.attach(buf, win)
    elseif vim.wo[win].winbar == winbar then
      -- Never clear another plugin's winbar.
      vim.wo[win].winbar = ""
    end
  end
  vim.cmd.redrawstatus()
end

function M.toggle()
  M.enabled = not M.enabled
  M.refresh()
end

function M.set_zen(active)
  M.zen = active
  M.refresh()
end

function M.setup()
  require("dropbar").setup({
    bar = { enable = M.allow },
    menu = { win_configs = { border = "rounded" } },
  })
  -- An ineligible buffer may replace a file in a window that already has a bar.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("config_breadcrumbs", { clear = true }),
    callback = M.refresh,
    desc = "Keep breadcrumbs limited to normal file windows",
  })
end

return M
