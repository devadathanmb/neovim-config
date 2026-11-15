local group = vim.api.nvim_create_augroup("personal_config", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 180 })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "yaml", "lua" },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
  end,
})

-- checktime respects modified buffers; never force-reload unsaved edits.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = group,
  callback = function()
    if vim.fn.mode() == "n" and vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  callback = function(event)
    vim.notify("Reloaded external changes: " .. vim.fn.fnamemodify(event.file, ":t"))
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Do not continue comments with o/O",
  callback = function()
    vim.opt_local.formatoptions:remove("o")
  end,
})
