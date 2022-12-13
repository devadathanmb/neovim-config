-- This is the colorscheme name
local colorscheme = "vscode"

-- Protected call to load colorscheme
local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end

-- For dark theme (neovim's default)
vim.o.background = 'dark'

require(colorscheme).setup({
    transparent_mode = true,
})


