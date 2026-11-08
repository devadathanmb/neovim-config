-- Bookmarks (per-project persistence, text re-anchoring, cross-file navigation),
-- Flash mappings and the Trouble problems panel.
local function run()
  local temp = vim.fn.tempname()
  vim.fn.mkdir(temp, "p")
  vim.cmd.cd(temp)
  local a, b = temp .. "/a.txt", temp .. "/b.txt"
  vim.fn.writefile({ "one", "two", "three", "four", "five" }, a)
  vim.fn.writefile({ "alpha", "beta", "gamma" }, b)
  local bm = require("config.bookmarks")
  local function lines(items)
    return vim.tbl_map(function(item) return vim.fs.basename(item.file) .. ":" .. item.line end, items)
  end

  vim.cmd.edit(a)
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  bm.toggle()
  vim.cmd.edit(b)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  bm.toggle()
  assert(vim.deep_equal(lines(bm.list()), { "a.txt:3", "b.txt:2" }), vim.inspect(lines(bm.list())))

  -- Cross-file next/previous with wrap-around.
  bm.next(1)
  assert(vim.fs.basename(vim.api.nvim_buf_get_name(0)) == "a.txt" and vim.fn.line(".") == 3, "next did not wrap to a.txt:3")
  bm.next(1)
  assert(vim.fs.basename(vim.api.nvim_buf_get_name(0)) == "b.txt" and vim.fn.line(".") == 2, "next did not cross files")
  bm.next(-1)
  assert(vim.fs.basename(vim.api.nvim_buf_get_name(0)) == "a.txt", "previous did not cross files")

  -- In-buffer edits move the bookmark with its line.
  vim.cmd.edit(a)
  vim.api.nvim_buf_set_lines(0, 0, 0, false, { "inserted" })
  vim.cmd.write()
  assert(vim.deep_equal(lines(bm.list()), { "a.txt:4", "b.txt:2" }), "bookmark did not follow edit")

  -- External rewrite (agent in another pane): re-anchored by line text after reload.
  vim.fn.writefile({ "new header", "another", "inserted", "one", "two", "three", "four", "five" }, a)
  vim.uv.fs_utime(a, os.time() + 5, os.time() + 5)
  vim.cmd.checktime()
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "new header", "external change not reloaded")
  assert(vim.deep_equal(lines(bm.list()), { "a.txt:6", "b.txt:2" }), "not re-anchored: " .. vim.inspect(lines(bm.list())))

  -- Persistence: a fresh load of the store sees the same bookmarks.
  local path = vim.fn.stdpath("data") .. "/bookmarks/" .. vim.fs.normalize(vim.fn.getcwd()):gsub("[/\\:]", "%%") .. ".json"
  local saved = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  assert(saved["a.txt"][1].line == 6 and saved["a.txt"][1].text == "three", "store not persisted: " .. vim.inspect(saved))

  -- Toggle off, then clear the file.
  vim.api.nvim_win_set_cursor(0, { 6, 0 })
  bm.toggle()
  assert(vim.deep_equal(lines(bm.list()), { "b.txt:2" }), "toggle off failed")
  vim.cmd.edit(b)
  bm.clear(false)
  assert(#bm.list() == 0 and not vim.uv.fs_stat(path), "clear did not remove store")
  print("PASS: bookmarks toggle/list, cross-file next/prev, edit tracking, external re-anchoring, persistence, clear")

  for _, key in ipairs({ "s", "S" }) do
    assert(vim.fn.maparg(key, "n") ~= "", "flash mapping missing: " .. key)
  end
  assert(vim.fn.maparg("S", "x") == "" or vim.fn.maparg("S", "x"):find("surround", 1, true) or vim.fn.maparg("S", "x", false, true).desc ~= "Flash select syntax node",
    "visual S must stay nvim-surround")
  print("PASS: Flash mappings and visual-S surround ownership")

  vim.diagnostic.set(vim.api.nvim_create_namespace("nav_test"), 0, {
    { lnum = 0, col = 0, message = "synthetic problem", severity = vim.diagnostic.severity.ERROR },
  })
  vim.cmd("Trouble diagnostics open")
  assert(vim.wait(3000, function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "trouble" then
        return table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)):find("synthetic problem") ~= nil
      end
    end
  end, 50), "Trouble did not list the diagnostic")
  vim.cmd("Trouble diagnostics close")
  print("PASS: Trouble problems panel lists diagnostics")
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qall!")
end)
