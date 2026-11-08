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

-- Keep Markdown fence/language labels hidden when a native LSP preview gains focus.
-- Retain the fence text in the buffer so Tree-sitter can still inject the language.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function(event)
    for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
      if vim.w[win].lsp_floating_bufnr then
        vim.wo[win].conceallevel = 2
        vim.wo[win].concealcursor = "nvic"
      end
    end
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
