pcall(vim.api.nvim_del_augroup_by_name, "FileExplorer")

local group = vim.api.nvim_create_augroup("ProjectExplorer", { clear = true })

local function open_directory(buf, dir)
  Snacks.explorer({ cwd = dir })
  Snacks.bufdelete(buf)
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  nested = true,
  callback = function(event)
    if event.file == "" or vim.fn.isdirectory(event.file) == 0 or vim.g.SessionLoad then
      return
    end
    local dir = vim.fn.fnamemodify(event.file, ":p")
    if vim.v.vim_did_enter == 1 then
      open_directory(event.buf, dir)
      return
    end

    vim.api.nvim_create_autocmd("UIEnter", {
      group = group,
      once = true,
      nested = true,
      callback = function()
        if vim.v.this_session == "" and vim.api.nvim_get_current_buf() == event.buf then
          open_directory(event.buf, dir)
        end
      end,
    })
  end,
})
