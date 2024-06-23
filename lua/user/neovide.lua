if not vim.g.neovide then
  return
end

-- Change dir to home
vim.fn.chdir(vim.env.HOME)

vim.o.guifont = "BlexMono Nerd Font:h16"
vim.g.neovide_cursor_trail_size = 0.0
vim.g.neovide_padding_top = 0
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_right = 0
vim.g.neovide_padding_left = 10

vim.g.neovide_input_macos_option_key_is_meta = true
