local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
    vim.notify("Error setting up lualine")
    return
end

-- Lualine colorscheme
local colorscheme = require("njan.darkplus-lualine")
lualine.setup({
    options = {
        theme = colorscheme,
        section_separators = ' ', component_separators = ' ',
        disabled_filetypes = {
            "NvimTree",
        },
    },
})
