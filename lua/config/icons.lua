local M = {}

-- Reuse which-key's bundled UI catalog instead of maintaining glyph literals.
function M.which_key(name)
  for _, icon in ipairs(require("which-key.icons").rules) do
    if icon.pattern == name or icon.plugin == name then
      return vim.deepcopy(icon)
    end
  end
  error("Unknown which-key icon: " .. name)
end

function M.setup()
  local icons = require("nvim-web-devicons")
  -- Single-color terminal equivalents of the installed Material Icon Theme SVGs.
  local material = {
    ts = "#0288d1",
    tsx = "#0288d1",
    js = "#ffca28",
    jsx = "#ffca28",
    mjs = "#ffca28",
    cjs = "#ffca28",
    json = "#f9a825",
    jsonc = "#f9a825",
    yaml = "#ff5252",
    yml = "#ff5252",
    md = "#42a5f5",
    mdx = "#42a5f5",
  }
  local overrides = {}
  for extension, color in pairs(material) do
    local icon = icons.get_icons_by_extension()[extension]
    if icon then
      overrides[extension] = vim.tbl_extend("force", icon, { color = color })
    end
  end
  icons.setup({ color_icons = true, default = true, strict = true, prefix = true, override_by_extension = overrides })
  -- Snacks passes full paths; devicons expects basenames for filename matches.
  local get_icon = icons.get_icon
  icons.get_icon = function(name, extension, opts)
    return get_icon(name and vim.fs.basename(name), extension, opts)
  end
end

return M
