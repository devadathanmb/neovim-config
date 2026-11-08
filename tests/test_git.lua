-- Gitsigns hunks/staging, guarded resets, blame popup, Diffview review/history.
-- Cases share one fixture repository with two unstaged hunks (lines 3 and 23);
-- each case leaves it in that state.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local select = vim.ui.select
local temp, cwd, path, buf, base, changed, gs

local function git(...)
  local args = { "git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false",
    "-c", "user.name=Neovim Fixture", "-c", "user.email=fixture@example.invalid" }
  vim.list_extend(args, { ... })
  local result = vim.system(args, { cwd = temp, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
local function staged(text) return git("diff", "--cached"):find(text, 1, true) ~= nil end
local function nothing_staged() return git("diff", "--cached") == "" end
local function hunks(count) return function() return #(gs.get_hunks(buf) or {}) == count end end
local function line(n) return vim.api.nvim_buf_get_lines(buf, n - 1, n, false)[1] end

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      cwd = vim.fn.getcwd()
      temp = h.tempdir()
      git("init", "-q")
      base = {}
      for i = 1, 30 do base[i] = "line " .. i end
      path = temp .. "/sample file.txt"
      vim.fn.writefile(base, path)
      git("add", "--", "sample file.txt")
      git("commit", "-qm", "Fixture baseline")
      changed = vim.deepcopy(base)
      changed[3], changed[23] = "agent edit three", "agent edit twenty-three"
      vim.fn.writefile(changed, path)
      vim.fn.chdir(temp)
      vim.cmd.edit(vim.fn.fnameescape(path))
      buf = vim.api.nvim_get_current_buf()
      gs = require("gitsigns")
    end,
    -- No v:errmsg check here: gitsigns hunk navigation runs `silent! foldopen!`,
    -- which records E490 in v:errmsg even though nothing failed.
    pre_case = function()
      if vim.api.nvim_get_current_buf() ~= buf then vim.api.nvim_set_current_buf(buf) end
    end,
    post_case = function() vim.ui.select = select end,
    post_once = function()
      pcall(vim.cmd, "DiffviewClose")
      pcall(gs.detach_all)
      vim.wait(200)
      vim.cmd("silent! %bwipeout!")
      vim.fn.chdir(cwd)
      vim.fn.delete(temp, "rf")
    end,
  },
})

T["signs"] = MiniTest.new_set()

T["signs"]["attach with hunks and a change summary"] = function()
  h.wait(hunks(2), "Gitsigns did not attach with two hunks")
  h.wait(function() return vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.changed == 2 end, "wrong gutter change summary")
end

T["signs"]["git actions are buffer-local"] = function()
  for _, lhs in ipairs({ "<Space>gj", "<Space>gk", "<Space>gv", "<Space>gs", "<Space>gS", "<Space>gU", "<Space>gr",
    "<Space>gR", "<Space>gb", "<Space>gB", "<Space>gp", "<Space>gP", "]c", "[c" }) do
    h.eq({ lhs, vim.fn.maparg(lhs, "n", false, true).buffer }, { lhs, 1 })
  end
end

T["signs"]["navigate and preview hunks"] = function()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  h.action("<Space>gj")
  h.wait(function() return vim.fn.line(".") == 3 end, "next hunk mapping failed")
  h.action("<Space>gv")
  local preview = h.floats()[1]
  assert(preview, "hunk preview did not open")
  h.assert_rounded(preview, "hunk preview")
  vim.api.nvim_win_close(preview, true)
end

T["staging"] = MiniTest.new_set()

T["staging"]["stage hunk toggles one hunk only"] = function()
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  h.action("<Space>gs")
  h.wait(function() return staged("+agent edit three") end, "stage hunk failed")
  assert(not staged("+agent edit twenty-three"), "staging one hunk staged another")
  h.wait(hunks(1), "unstaged hunk cache did not refresh")
  h.action("<Space>gs")
  h.wait(nothing_staged, "stage hunk did not toggle staged hunk back off")
  h.wait(hunks(2), "unstaged hunks did not return")
end

T["staging"]["stage and unstage file keep working-tree edits"] = function()
  h.action("<Space>gS")
  h.wait(function() return staged("+agent edit twenty-three") end, "stage file failed")
  h.action("<Space>gU")
  h.wait(nothing_staged, "unstage file failed")
  h.eq(vim.fn.readfile(path)[3], changed[3])
  h.wait(hunks(2), "unstage did not restore hunk cache")
end

T["staging"]["visual stage takes only the selected hunk"] = function()
  vim.api.nvim_win_set_cursor(0, { 24, 0 })
  h.keys("Vk gs")
  h.wait(function() return staged("+agent edit twenty-three") end, "visual stage failed")
  assert(not staged("+agent edit three"), "visual stage included unrelated hunk")
  h.eq(vim.fn.mode(), "n")
  h.action("<Space>gU")
  h.wait(nothing_staged, "visual stage cleanup failed")
  h.wait(hunks(2), "visual stage cache did not settle")
end

T["reset"] = MiniTest.new_set({
  hooks = { pre_case = function() vim.api.nvim_win_set_cursor(0, { 3, 0 }) end },
})

T["reset"]["cancel keeps changes"] = function()
  vim.ui.select = function(_, _, callback) callback("Cancel") end
  h.action("<Space>gr")
  h.eq(line(3), changed[3])
end

T["reset"]["stale prompt refuses to reset"] = function()
  local pending
  vim.ui.select = function(_, _, callback) pending = callback end
  h.action("<Space>gr")
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "edit while prompt open" })
  pending("Reset")
  h.eq(line(3), changed[3])
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { base[1] })
  h.wait(hunks(2), "hunks did not settle after prompt race")
end

T["reset"]["confirmed hunk reset edits only the buffer and is undoable"] = function()
  vim.ui.select = function(_, _, callback) callback("Reset") end
  h.action("<Space>gr")
  h.wait(function() return line(3) == base[3] end, "confirmed reset failed")
  h.eq(line(23), changed[23])
  h.eq(vim.fn.readfile(path)[3], changed[3])
  vim.cmd.undo()
  h.wait(function() return line(3) == changed[3] end, "hunk reset was not undoable")
  h.wait(hunks(2), "undo did not restore hunks")
end

T["reset"]["confirmed file reset leaves the index alone"] = function()
  vim.ui.select = function(_, _, callback) callback("Reset") end
  h.action("<Space>gR")
  h.wait(function() return vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), base) end, "file reset failed")
  assert(nothing_staged(), "reset modified the index")
  vim.cmd.undo()
  h.wait(hunks(2), "undo did not restore file edits")
  vim.bo[buf].modified = false
end

T["blame popup takes focus with PR keys"] = function()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  h.action("<Space>gb")
  h.wait(function()
    for _, win in ipairs(h.floats()) do
      local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
      if text:find("Neovim Fixture", 1, true) and vim.api.nvim_get_current_win() == win
        and vim.fn.maparg("o", "n", false, true).buffer == 1 and vim.fn.maparg("y", "n", false, true).buffer == 1 then
        vim.api.nvim_win_close(win, true)
        return true
      end
    end
  end, "line blame popup did not take focus with fixture author and PR keys")
end

T["diffview"] = MiniTest.new_set()

T["diffview"]["review opens side by side in its own tab"] = function()
  local lib = require("diffview.lib")
  local tabs = #vim.api.nvim_list_tabpages()
  h.keys(" gt")
  h.wait(function()
    local view = lib.get_current_view()
    return view and view.initialized and #view.files.working > 0
  end, "Git review did not load changed files")
  h.eq(#vim.api.nvim_list_tabpages(), tabs + 1)
  assert(nothing_staged(), "opening review staged changes")
  local function diff_windows()
    return vim.tbl_filter(function(win) return vim.wo[win].diff end, vim.api.nvim_tabpage_list_wins(0))
  end
  h.wait(function() return #diff_windows() == 2 end, "review is not side-by-side")
  for _, win in ipairs(diff_windows()) do
    assert(not vim.wo[win].wrap and not vim.wo[win].list, "review window options not applied")
    assert(vim.wo[win].winhighlight:find("DiffChange:GitReview", 1, true), "side-specific review colors missing")
  end
  h.eq(vim.fn.maparg("<C-x>", "n", false, true).desc, "Close Git review")
  assert(require("diffview.config").get_config().keymaps.disable_defaults, "unguarded default shortcuts are enabled")
  h.keys("<C-x>")
  h.wait(function() return #vim.api.nvim_list_tabpages() == tabs end, "review close did not restore editor tab")
  h.eq(vim.api.nvim_get_current_buf(), buf)
end

T["diffview"]["file history handles paths with spaces"] = function()
  local lib = require("diffview.lib")
  h.keys(" gh")
  h.wait(function()
    local view = lib.get_current_view()
    return view and view.panel and not view.panel.updating and view.panel.cur_item and view.panel.cur_item[2]
      and view.panel.entries and #view.panel.entries > 0
  end, "history did not load filename containing spaces")
  -- Closing while the diff layout is still opening races diffview's scroll sync.
  h.wait(function()
    local layout = lib.get_current_view().cur_layout
    return layout and layout:is_valid() and layout:is_files_loaded()
  end, "history diff did not finish opening")
  vim.cmd.DiffviewClose()
  assert(nothing_staged(), "history changed the index")
end

return T
