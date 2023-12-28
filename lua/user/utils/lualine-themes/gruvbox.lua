local colors = {
  pink = "#D3869B",
  red = "#FB4934",
  orange = "#d65d0e",
  green = "#98971A",
  blue = "#076678",
  violet = "#B16286",
  purple = "#8F3F71",
  white = "#FBF1C7",
  gray = "#1e1e1e", -- 15% lighter than black
  black = "#1e1e1e",
}

colors.black = "NONE"
colors.gray = "NONE"

return {
  normal = {
    a = { fg = colors.white, bg = colors.blue },
    b = { fg = colors.white, bg = colors.gray },
    c = { fg = colors.white, bg = colors.black },
  },
  insert = {
    a = { fg = colors.white, bg = colors.orange },
  },
  visual = {
    a = { fg = colors.white, bg = colors.purple },
  },
  replace = {
    a = { fg = colors.white, bg = colors.pink },
  },
  command = {
    a = { fg = colors.white, bg = colors.green },
  },
  terminal = {
    a = { fg = colors.white, bg = colors.violet },
  },
  pending = {
    a = { fg = colors.white, bg = colors.red },
  },
  inactive = {
    a = { fg = colors.white, bg = colors.black },
  },
}
