local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
  vim.notify("Bufferline not loaded")
  return
end

bufferline.setup({
})
