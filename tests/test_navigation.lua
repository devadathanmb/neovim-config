-- Bookmarks (persistence, re-anchoring, cross-file), Flash mappings, Trouble.
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local bm = require("config.bookmarks")
local temp, cwd, a, b

local function lines(items)
  return vim.tbl_map(function(item) return vim.fs.basename(item.file) .. ":" .. item.line end, items)
end
local function at()
  return vim.fs.basename(vim.api.nvim_buf_get_name(0)) .. ":" .. vim.fn.line(".")
end
local function store()
  return vim.fn.stdpath("data") .. "/bookmarks/" .. vim.fs.normalize(vim.fn.getcwd()):gsub("[/\\:]", "%%") .. ".json"
end

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      cwd = vim.fn.getcwd()
      temp = h.tempdir()
      vim.cmd.cd(temp)
      a, b = temp .. "/a.txt", temp .. "/b.txt"
      vim.fn.writefile({ "one", "two", "three", "four", "five" }, a)
      vim.fn.writefile({ "alpha", "beta", "gamma" }, b)
    end,
    pre_case = h.no_errors.pre_case,
    post_case = h.no_errors.post_case,
    post_once = function()
      pcall(bm.clear, false)
      vim.cmd.cd(cwd)
      vim.fn.delete(temp, "rf")
    end,
  },
})

-- Bookmark cases build on each other, like a session of real use.
T["bookmarks"] = MiniTest.new_set()

T["bookmarks"]["toggle and list across files"] = function()
  vim.cmd.edit(a)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  bm.toggle()
  vim.cmd.edit(b)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  bm.toggle()
  h.eq(lines(bm.list()), { "a.txt:3", "b.txt:2" })
end

T["bookmarks"]["next/previous cross files and wrap"] = function()
  bm.next(1)
  h.eq(at(), "a.txt:3")
  bm.next(1)
  h.eq(at(), "b.txt:2")
  bm.next(-1)
  h.eq(at(), "a.txt:3")
end

T["bookmarks"]["follow in-buffer edits"] = function()
  vim.cmd.edit(a)
  vim.api.nvim_buf_set_lines(0, 0, 0, false, { "inserted" })
  vim.cmd("silent write")
  h.eq(lines(bm.list()), { "a.txt:4", "b.txt:2" })
end

T["bookmarks"]["re-anchor by text after external rewrite"] = function()
  vim.fn.writefile({ "new header", "another", "inserted", "one", "two", "three", "four", "five" }, a)
  vim.uv.fs_utime(a, os.time() + 5, os.time() + 5)
  vim.cmd.checktime()
  h.eq(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], "new header")
  h.eq(lines(bm.list()), { "a.txt:6", "b.txt:2" })
end

T["bookmarks"]["persist per project"] = function()
  local saved = vim.json.decode(table.concat(vim.fn.readfile(store()), "\n"))
  h.eq({ saved["a.txt"][1].line, saved["a.txt"][1].text }, { 6, "three" })
end

T["bookmarks"]["toggle off and clear remove the store"] = function()
  vim.cmd.edit(a)
  vim.api.nvim_win_set_cursor(0, { 6, 0 })
  bm.toggle()
  h.eq(lines(bm.list()), { "b.txt:2" })
  vim.cmd.edit(b)
  bm.clear(false)
  h.eq(#bm.list(), 0)
  assert(not vim.uv.fs_stat(store()), "clear did not remove store")
end

T["flash owns s/S; visual S stays nvim-surround"] = function()
  for _, key in ipairs({ "s", "S" }) do
    assert(vim.fn.maparg(key, "n") ~= "", "flash mapping missing: " .. key)
  end
  local visual = vim.fn.maparg("S", "x", false, true)
  assert(visual.desc ~= "Flash select syntax node", "visual S must stay nvim-surround")
end

T["trouble lists diagnostics"] = function()
  vim.cmd.edit(a)
  vim.diagnostic.set(vim.api.nvim_create_namespace("nav_test"), 0, {
    { lnum = 0, col = 0, message = "synthetic problem", severity = vim.diagnostic.severity.ERROR },
  })
  vim.cmd("Trouble diagnostics open")
  MiniTest.finally(function() vim.cmd("Trouble diagnostics close") end)
  h.wait(function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "trouble" then
        return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false)):find("synthetic problem") ~= nil
      end
    end
  end, "Trouble did not list the diagnostic", 3000)
end

T["grug-far replaces across project files"] = function()
  vim.fn.writefile({ "local old_name = 1", "print(old_name)" }, temp .. "/one.lua")
  vim.fn.writefile({ "return old_name" }, temp .. "/two.lua")
  for _, lhs in ipairs({ "<Space>sr", "<Space>sw", "<Space>sR" }) do
    assert(vim.fn.maparg(lhs, "n") ~= "", "missing search/replace mapping: " .. lhs)
  end
  assert(vim.fn.maparg("<Space>sr", "x") ~= "", "missing visual search/replace mapping")
  local grug = require("grug-far")
  local windows = #vim.api.nvim_list_wins()
  grug.open({ instanceName = "test", prefills = { search = "old_name", replacement = "new_name", paths = temp } })
  MiniTest.finally(function() pcall(grug.kill_instance, "test") end)
  h.eq(#vim.api.nvim_list_wins(), windows + 1)
  local inst = grug.get_instance("test")
  h.wait(function()
    local info = inst:get_status_info()
    return info.status == "success" and info.stats and info.stats.matches == 3
  end, "grug-far did not find the three matches")
  inst:replace()
  h.wait(function()
    return vim.fn.readfile(temp .. "/one.lua")[2] == "print(new_name)" and vim.fn.readfile(temp .. "/two.lua")[1] == "return new_name"
  end, "grug-far did not write the replacement")
  h.wait(function() return inst:get_status_info().status == "success" end, "grug-far replace did not finish")
end

return T
