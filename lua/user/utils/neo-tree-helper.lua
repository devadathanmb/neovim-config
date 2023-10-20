-- Helper function to open neotree in a new buffer
local M = {}

function M.open_neo_tree(data)
  local directory = vim.fn.isdirectory(data.file) == 1

  if not directory then
    return
  end

  -- change to the directory
  vim.cmd.cd(data.file)

  -- open the tree
  require("neo-tree")
end

return M
