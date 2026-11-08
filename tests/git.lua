local temp, cwd = vim.fn.tempname(), vim.fn.getcwd()
local select = vim.ui.select
local function git(...)
  local args = { "git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-c", "user.name=Neovim Fixture", "-c", "user.email=fixture@example.invalid" }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { cwd = temp, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
local function await(test, label)
  assert(vim.wait(8000, test, 20), label)
end
local function action(lhs, mode)
  local mapping = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(mapping.callback, "missing callback: " .. lhs)
  mapping.callback()
end
local function keys(value)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(value, true, false, true), "xt", false)
end

local function run()
  vim.fn.mkdir(temp, "p")
  git("init", "-q")
  local base = {}
  for i = 1, 30 do base[i] = "line " .. i end
  local path = temp .. "/sample file.txt"
  vim.fn.writefile(base, path)
  git("add", "--", "sample file.txt")
  git("commit", "-qm", "Fixture baseline")
  local changed = vim.deepcopy(base)
  changed[3], changed[23] = "agent edit three", "agent edit twenty-three"
  vim.fn.writefile(changed, path)
  vim.fn.chdir(temp)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local gs = require("gitsigns")
  local function hunks(count) return function() return #(gs.get_hunks(buf) or {}) == count end end
  await(hunks(2), "Gitsigns did not attach with two hunks")
  await(function() return vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.changed == 2 end, "wrong gutter change summary")
  for _, lhs in ipairs({ "<Space>gj", "<Space>gk", "<Space>gv", "<Space>gs", "<Space>gS", "<Space>gU", "<Space>gr", "<Space>gR", "<Space>gb", "<Space>gB", "<Space>gp", "<Space>gP", "]c", "[c" }) do
    assert(vim.fn.maparg(lhs, "n", false, true).buffer == 1, "Git action is not buffer-local: " .. lhs)
  end
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  action("<Space>gj")
  await(function() return vim.fn.line(".") == 3 end, "next hunk mapping failed")
  action("<Space>gv")
  local preview
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then preview = win end
  end
  assert(preview and vim.api.nvim_win_get_config(preview).border[1] == "╭", "hunk preview lacks rounded border")
  vim.api.nvim_win_close(preview, true)
  action("<Space>gs")
  await(function() return git("diff", "--cached"):find("+agent edit three", 1, true) ~= nil end, "stage hunk failed")
  assert(not git("diff", "--cached"):find("+agent edit twenty-three", 1, true), "staging one hunk staged another")
  await(hunks(1), "unstaged hunk cache did not refresh")
  action("<Space>gs")
  await(function() return git("diff", "--cached") == "" end, "stage hunk did not toggle staged hunk back off")
  await(hunks(2), "unstaged hunks did not return")
  action("<Space>gS")
  await(function() return git("diff", "--cached"):find("+agent edit twenty-three", 1, true) ~= nil end, "stage file failed")
  action("<Space>gU")
  await(function() return git("diff", "--cached") == "" end, "unstage file failed")
  assert(vim.fn.readfile(path)[3] == changed[3], "unstage discarded working-tree edits")
  await(hunks(2), "unstage did not restore hunk cache")
  vim.api.nvim_win_set_cursor(0, { 24, 0 })
  keys("Vk gs")
  await(function() return git("diff", "--cached"):find("+agent edit twenty-three", 1, true) ~= nil end, "visual stage failed")
  assert(not git("diff", "--cached"):find("+agent edit three", 1, true), "visual stage included unrelated hunk")
  assert(vim.fn.mode() == "n", "visual stage left selection active")
  action("<Space>gU")
  await(function() return git("diff", "--cached") == "" end, "visual stage cleanup failed")
  await(hunks(2), "visual stage cache did not settle")
  vim.api.nvim_win_set_cursor(0, { 3, 0 })

  vim.ui.select = function(_, _, callback) callback("Cancel") end
  action("<Space>gr")
  assert(vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1] == changed[3], "cancel reset discarded changes")
  local pending
  vim.ui.select = function(_, _, callback) pending = callback end
  action("<Space>gr")
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "edit while prompt open" })
  pending("Reset")
  assert(vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1] == changed[3], "stale reset prompt discarded edits")
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { base[1] })
  await(hunks(2), "hunks did not settle after prompt race")
  vim.ui.select = function(_, _, callback) callback("Reset") end
  action("<Space>gr")
  await(function() return vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1] == base[3] end, "confirmed reset failed")
  assert(vim.api.nvim_buf_get_lines(buf, 22, 23, false)[1] == changed[23], "hunk reset discarded unrelated hunk")
  assert(vim.fn.readfile(path)[3] == changed[3], "reset wrote to disk without :w")
  vim.cmd.undo()
  await(function() return vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1] == changed[3] end, "hunk reset was not undoable")
  await(hunks(2), "undo did not restore hunks")
  action("<Space>gR")
  await(function() return vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), base) end, "file reset failed")
  assert(git("diff", "--cached") == "", "reset modified the index")
  vim.cmd.undo()
  await(hunks(2), "undo did not restore file edits")
  vim.ui.select = select
  vim.bo.modified = false

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  action("<Space>gb")
  await(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
        if text:find("Neovim Fixture", 1, true) and vim.api.nvim_get_current_win() == win
          and vim.fn.maparg("o", "n", false, true).buffer == 1 and vim.fn.maparg("y", "n", false, true).buffer == 1 then
          vim.api.nvim_win_close(win, true)
          return true
        end
      end
    end
  end, "line blame popup did not take focus with fixture author and PR keys")
  local tabs = #vim.api.nvim_list_tabpages()
  keys(" gt")
  local lib = require("diffview.lib")
  await(function()
    local view = lib.get_current_view()
    return view and view.initialized and #view.files.working > 0
  end, "Git review did not load changed files")
  assert(#vim.api.nvim_list_tabpages() == tabs + 1, "review did not open an isolated tab page")
  assert(git("diff", "--cached") == "", "opening review staged changes")
  await(function()
    local count = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[win].diff then count = count + 1 end
    end
    return count == 2
  end, "review diff windows did not initialize")
  local diff_windows = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      diff_windows = diff_windows + 1
      assert(not vim.wo[win].wrap and not vim.wo[win].list, "review window options not applied")
      assert(vim.wo[win].winhighlight:find("DiffChange:GitReview", 1, true), "side-specific review colors missing")
      assert(vim.fn.maparg("<C-x>", "n", false, true).desc == "Close Git review", "review close mapping missing")
    end
  end
  assert(diff_windows == 2, "review is not side-by-side")
  local config = require("diffview.config").get_config()
  assert(config.keymaps.disable_defaults, "unguarded default restore/merge shortcuts are enabled")
  keys("<C-x>")
  await(function() return #vim.api.nvim_list_tabpages() == tabs end, "review close did not restore editor tab")
  assert(vim.api.nvim_get_current_buf() == buf, "review close lost original editor buffer")
  keys(" gh")
  await(function()
    local view = lib.get_current_view()
    return view and view.panel and not view.panel.updating and view.panel.cur_item and view.panel.cur_item[2]
      and view.panel.entries and #view.panel.entries > 0
  end, "history did not load filename containing spaces")
  -- Closing while the diff layout is still opening races diffview's scroll sync.
  await(function()
    local layout = lib.get_current_view().cur_layout
    return layout and layout:is_valid() and layout:is_files_loaded()
  end, "history diff did not finish opening")
  vim.cmd.DiffviewClose()
  assert(git("diff", "--cached") == "", "history changed the index")
  print("PASS: Git signs/hunks, preview, stage/unstage, guarded undoable resets, blame, side-by-side review, file history")
  gs.detach_all()
  vim.wait(200)
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  vim.ui.select = select
  pcall(vim.cmd, "DiffviewClose")
  pcall(function() require("gitsigns").detach_all() end)
  vim.fn.chdir(cwd)
  vim.fn.delete(temp, "rf")
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)
