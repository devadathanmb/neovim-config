local status_ok, neoscroll = pcall(require, "neoscroll")
if not status_ok then
    vim.notify("Unable to load neoscroll plugin")
    return
end

neoscroll.setup()
