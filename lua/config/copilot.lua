-- GitHub Copilot through the official copilot-language-server (Mason) and
-- Neovim's native LSP inline completion (ghost text). No Copilot plugin.
local M = {}

-- Mirrors VS Code `github.copilot.enable` (plaintext/scminput off, markdown on).
local disabled_filetypes = { text = true, gitcommit = true, gitrebase = true, help = true }
-- Never send likely-secret files, whatever their filetype.
local secret_patterns = { "^%.env", "%.env$", "%.pem$", "%.key$", "^id_[%w_]+$", "%.netrc$", "credentials" }

M.status = {} -- client_id -> { kind = "Normal"|"Warning"|"Error"|"Inactive", busy = bool, message = string }

local function allowed(buf)
  if vim.bo[buf].buftype ~= "" or disabled_filetypes[vim.bo[buf].filetype] then
    return false
  end
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf))
  if name == "" then
    return false
  end
  for _, pattern in ipairs(secret_patterns) do
    if name:match(pattern) then
      return false
    end
  end
  return true
end

local function refresh_statusline()
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh({ place = { "statusline" } })
  end
end

function M.setup()
  vim.lsp.config("copilot", {
    -- Not calling on_dir prevents attachment for excluded buffers.
    root_dir = function(buf, on_dir)
      if allowed(buf) then
        on_dir(vim.fs.root(buf, ".git") or vim.fn.getcwd())
      end
    end,
    on_exit = function(_, _, client_id)
      M.status[client_id] = nil
      vim.schedule(refresh_statusline)
    end,
    handlers = {
      didChangeStatus = function(_, params, ctx)
        M.status[ctx.client_id] = { kind = params.kind, busy = params.busy, message = params.message }
        refresh_statusline()
      end,
    },
  })

  vim.lsp.inline_completion.enable(true)

  local function map(lhs, rhs, desc)
    vim.keymap.set("i", lhs, rhs, { desc = desc })
  end
  map("<C-l>", function()
    vim.lsp.inline_completion.get()
  end, "Accept Copilot suggestion")
  map("<M-]>", function()
    vim.lsp.inline_completion.select({ count = 1 })
  end, "Next Copilot suggestion")
  map("<M-[>", function()
    vim.lsp.inline_completion.select({ count = -1 })
  end, "Previous Copilot suggestion")
  map("<C-]>", function()
    M.dismiss()
  end, "Dismiss Copilot suggestion")
  vim.keymap.set("n", "<leader>uc", M.toggle, { desc = "Toggle Copilot suggestions" })
  vim.keymap.set("n", "<leader>pc", "<cmd>checkhealth vim.lsp<cr>", { desc = "Copilot / LSP health" })
end

--- Accept the visible suggestion; returns false when there is none (Tab fallback).
function M.accept()
  return vim.lsp.inline_completion.get()
end

--- Native inline completion has no dismiss API; aborting through on_accept does it.
function M.dismiss()
  if not vim.lsp.inline_completion.get({
    on_accept = function()
      return nil
    end,
  }) then
    return vim.api.nvim_feedkeys(vim.keycode("<C-]>"), "n", false)
  end
end

function M.toggle()
  local enable = not vim.lsp.inline_completion.is_enabled()
  vim.lsp.inline_completion.enable(enable)
  vim.notify("Copilot suggestions " .. (enable and "enabled" or "disabled"))
  refresh_statusline()
end

--- Statusline: nothing when Copilot is not attached to this buffer.
function M.statusline()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "copilot" })[1]
  if not client then
    return ""
  end
  local status = M.status[client.id] or {}
  if not vim.lsp.inline_completion.is_enabled() then
    return "\u{f4b8} off"
  end
  if status.kind == "Error" then
    return "\u{f4b9}"
  end
  if status.kind == "Warning" or status.kind == "Inactive" then
    return "\u{f4ba}"
  end
  return "\u{f4b8}"
end

function M.statusline_color()
  local theme = require("theme.github")
  local client = vim.lsp.get_clients({ bufnr = 0, name = "copilot" })[1]
  local status = client and M.status[client.id] or {}
  local key
  if not vim.lsp.inline_completion.is_enabled() then
    key = "descriptionForeground"
  elseif status.kind == "Error" then
    key = "notificationsErrorIcon.foreground"
  elseif status.kind == "Warning" or status.kind == "Inactive" then
    key = "notificationsWarningIcon.foreground"
  elseif status.busy then
    key = "notificationsInfoIcon.foreground"
  else
    key = "statusBar.foreground"
  end
  return { fg = theme.color(key) }
end

function M.statusline_click()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "copilot" })[1]
  local status = client and M.status[client.id]
  if status and status.message and status.message:lower():find("not signed in", 1, true) then
    vim.cmd("LspCopilotSignIn")
  elseif status and status.message and status.message ~= "" and status.kind ~= "Normal" then
    vim.notify("Copilot: " .. status.message, vim.log.levels.WARN)
  else
    M.toggle()
  end
end

return M
