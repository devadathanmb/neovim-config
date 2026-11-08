local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

local function copy_path(absolute)
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("This buffer has no file path", vim.log.levels.WARN)
    return
  end
  if not absolute then
    path = vim.fs.relpath(vim.fn.getcwd(), path) or path
  end
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. path)
end

map("n", "<leader>y", function()
  require("config.context").copy(false)
end, "Copy line context for agents")
map("x", "<leader>y", function()
  require("config.context").copy(true)
end, "Copy selected context for agents")

map("n", "<leader>e", function()
  Snacks.explorer()
end, "Toggle explorer")
map("n", "<C-e>", function()
  Snacks.explorer.reveal()
end, "Focus explorer / reveal file")
map("n", "<leader>f", function()
  Snacks.picker.files()
end, "Find files")
map("n", "<leader>sf", function()
  Snacks.picker.files()
end, "Find files")
map("n", "<leader>sl", function()
  Snacks.picker.grep()
end, "Project grep")
map("n", "<leader>sb", function()
  Snacks.picker.buffers()
end, "Search buffers")
map("n", "<leader>sz", function()
  Snacks.picker.lines()
end, "Search buffer text")
map("n", "<leader>sL", function()
  Snacks.picker.resume()
end, "Resume last search")
map("n", "<leader>;", function()
  Snacks.picker.commands()
end, "Commands")
map("n", "<leader>pL", "<cmd>Lazy<cr>", "Plugin manager")
map("n", "<leader>pk", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/KEYMAPS.md")
end, "Keybinding reference")
map("n", "<leader>pp", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/SPEC.md")
end, "Spec and status")

map("n", "H", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "L", "<cmd>bnext<cr>", "Next buffer")
map("n", "<C-x>", function()
  if vim.bo.buftype ~= "" then
    vim.cmd.close()
  else
    Snacks.bufdelete()
  end
end, "Close buffer / tool window")
map("n", "<leader>Bd", function()
  Snacks.bufdelete()
end, "Close buffer")
map("n", "<leader>Bc", function()
  Snacks.bufdelete.other()
end, "Close other buffers")
map("n", "<leader>Bb", function()
  Snacks.picker.buffers()
end, "List buffers")
map("n", "<leader>Bn", "<cmd>bnext<cr>", "Next buffer")
map("n", "<leader>Bp", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "<leader>BN", "<cmd>enew<cr>", "New scratch buffer")
map("n", "<leader>By", function()
  vim.fn.setreg("+", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
end, "Copy buffer to clipboard")

map("n", "<leader>Fe", function()
  Snacks.explorer.reveal()
end, "File operations in explorer")
map("n", "<leader>Fr", function()
  Snacks.rename.rename_file()
end, "Rename current file")
map("n", "<leader>Fl", function()
  copy_path(false)
end, "Copy relative file path")
map("n", "<leader>FL", function()
  copy_path(true)
end, "Copy absolute file path")
map("n", "<leader>Fn", function()
  vim.ui.input({ prompt = "New file (relative to cwd): " }, function(path)
    if path and path ~= "" then
      path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
      vim.fn.mkdir(vim.fs.dirname(path), "p")
      vim.cmd.edit(vim.fn.fnameescape(path))
    end
  end)
end, "New file (write to save)")

for key, direction in pairs({ h = "left", j = "below", k = "above", l = "right" }) do
  map("n", "<C-" .. key .. ">", "<C-w>" .. key, "Focus window " .. direction)
  map("n", "<leader>w" .. key, "<C-w>" .. key:upper(), "Move window " .. direction)
end
map("n", "<leader>h", "<cmd>split<cr>", "Split horizontally")
map("n", "<leader>v", "<cmd>vsplit<cr>", "Split vertically")
map("n", "<leader>w=", "<C-w>=", "Equalize windows")
map("n", "<leader>wd", "<cmd>close<cr>", "Close window")
map("n", "<leader>wW", "<C-w>p", "Previous window")
map("n", "<leader>wm", "<C-w>_<C-w>|", "Maximize window (w= restores)")

-- Resize mode: keep resizing with h/j/k/l until any other key (Esc) is pressed.
local function resize_mode()
  local steps = {
    h = "vertical resize -2",
    l = "vertical resize +2",
    j = "resize -2",
    k = "resize +2",
    H = "vertical resize -10",
    L = "vertical resize +10",
    J = "resize -10",
    K = "resize +10",
    ["="] = "wincmd =",
  }
  local hint =
    { { "Resize: ", "ModeMsg" }, { "h/l narrower/wider  j/k shorter/taller  H/J/K/L big steps  = equal  Esc done" } }
  local ui = #vim.api.nvim_list_uis() > 0
  while true do
    if ui then
      vim.api.nvim_echo(hint, false, {})
      vim.cmd.redraw()
    end
    local ok, key = pcall(vim.fn.getcharstr)
    if not ok or not steps[key] then
      break
    end
    vim.cmd(steps[key])
  end
  vim.api.nvim_echo({ { "" } }, false, {})
end
map("n", "<leader>wr", resize_mode, "Resize mode (h/j/k/l, Esc to finish)")

map("n", "<C-n>", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", "Clear search highlight")
-- Native visual P replaces the selection without yanking it (works at line end too).
map("x", "p", "P", "Paste without replacing register")
map("x", ">", ">gv", "Indent and keep selection")
map("x", "<", "<gv", "Unindent and keep selection")
-- Expression mappings preserve counted motions while navigating wrapped text.
vim.keymap.set(
  { "n", "x" },
  "j",
  "v:count == 0 ? 'gj' : 'j'",
  { expr = true, silent = true, desc = "Down display line" }
)
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up display line" })
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, "Toggle line wrapping")
map("n", "<leader>ui", function()
  vim.g.snacks_indent = vim.g.snacks_indent == false
  if vim.g.snacks_indent then
    Snacks.indent.enable()
  else
    Snacks.indent.disable()
  end
end, "Toggle indent guides")
map("n", "<leader>gg", function()
  Snacks.lazygit()
end, "Lazygit")
map("n", "<leader>.", function()
  Snacks.scratch()
end, "Toggle scratch buffer")
map("n", "<leader>s.", function()
  Snacks.scratch.select()
end, "Find scratch buffers")
map("n", "<leader>ub", function()
  require("config.breadcrumbs").toggle()
end, "Toggle breadcrumbs")
map("n", "<leader>uz", function()
  Snacks.zen()
end, "Toggle zen mode")
map("n", "<leader>u.", function()
  vim.wo.list = not vim.wo.list
end, "Toggle whitespace dots")
map("n", "]]", function()
  Snacks.words.jump(vim.v.count1)
end, "Next reference")
map("n", "[[", function()
  Snacks.words.jump(-vim.v.count1)
end, "Previous reference")
