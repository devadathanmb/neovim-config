-- VS Code Bookmarks-style line bookmarks: per project (cwd), persisted as JSON,
-- tracked with extmarks while a file is loaded, and re-anchored by line text after
-- external rewrites (e.g. agents editing in another pane).
local M = {}

local ns = vim.api.nvim_create_namespace("personal_bookmarks")
local SEARCH_RADIUS = 200

--- @type table<string, {line: integer, text: string}[]>? relpath -> bookmarks (1-based lines)
local store
local store_root

local function root()
  return vim.fs.normalize(vim.fn.getcwd())
end

local function store_path(dir)
  return vim.fn.stdpath("data") .. "/bookmarks/" .. dir:gsub("[/\\:]", "%%") .. ".json"
end

---@return table<string, {line: integer, text: string}[]>
local function load()
  local dir = root()
  if store and store_root == dir then
    return store
  end
  store_root, store = dir, {}
  local path = store_path(dir)
  if vim.uv.fs_stat(path) then
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
    if ok and type(data) == "table" then
      store = data
    end
  end
  return assert(store)
end

local function relpath(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return nil
  end
  return vim.fs.relpath(root(), vim.fs.normalize(name))
end

local function line_text(buf, line)
  return vim.trim(vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or "")
end

--- Read extmark positions of a loaded buffer back into the store.
local function sync(buf)
  local rel = relpath(buf)
  if not rel or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local marks = {}
  local seen = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
    local line = mark[2] + 1
    if not mark[4].invalid and not seen[line] then
      seen[line] = true
      marks[#marks + 1] = { line = line, text = line_text(buf, line) }
    end
  end
  table.sort(marks, function(a, b)
    return a.line < b.line
  end)
  load()[rel] = #marks > 0 and marks or nil
end

local function save()
  if not store then
    return
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    sync(buf)
  end
  local path = store_path(store_root)
  if next(store) == nil then
    if vim.uv.fs_stat(path) then
      vim.fn.delete(path)
    end
    return
  end
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ vim.json.encode(store) }, path)
end

--- Find where a bookmark's text now lives: the stored line if it still matches,
--- otherwise the nearest identical line, otherwise the clamped stored line.
local function relocate(buf, mark)
  local count = vim.api.nvim_buf_line_count(buf)
  local line = math.min(math.max(mark.line, 1), count)
  if mark.text == "" or line_text(buf, line) == mark.text then
    return line
  end
  for offset = 1, SEARCH_RADIUS do
    for _, candidate in ipairs({ mark.line - offset, mark.line + offset }) do
      if candidate >= 1 and candidate <= count and line_text(buf, candidate) == mark.text then
        return candidate
      end
    end
  end
  return line
end

local function place(buf)
  local rel = relpath(buf)
  if not rel or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, mark in ipairs(load()[rel] or {}) do
    local line = relocate(buf, mark)
    vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
      sign_text = "\u{f02e}",
      sign_hl_group = "BookmarkSign",
      priority = 20,
      invalidate = true,
    })
  end
end

local function mark_at(buf, line)
  return vim.api.nvim_buf_get_extmarks(buf, ns, { line - 1, 0 }, { line - 1, -1 }, {})[1]
end

function M.toggle()
  local buf, line = vim.api.nvim_get_current_buf(), vim.fn.line(".")
  if not relpath(buf) then
    return vim.notify("Bookmarks need a file inside the working directory", vim.log.levels.WARN)
  end
  local existing = mark_at(buf, line)
  if existing then
    vim.api.nvim_buf_del_extmark(buf, ns, existing[1])
  else
    vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
      sign_text = "\u{f02e}",
      sign_hl_group = "BookmarkSign",
      priority = 20,
      invalidate = true,
    })
  end
  save()
end

--- All bookmarks of this project, ordered by file then line.
function M.list()
  local bookmarks = load()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    sync(buf)
  end
  local items = {}
  for rel, marks in pairs(bookmarks) do
    for _, mark in ipairs(marks) do
      items[#items + 1] = { file = vim.fs.joinpath(store_root, rel), rel = rel, line = mark.line, text = mark.text }
    end
  end
  table.sort(items, function(a, b)
    return a.rel == b.rel and a.line < b.line or a.rel < b.rel
  end)
  return items
end

local function jump(item)
  if vim.fs.normalize(vim.api.nvim_buf_get_name(0)) ~= vim.fs.normalize(item.file) then
    vim.cmd.edit(vim.fn.fnameescape(item.file))
  end
  vim.api.nvim_win_set_cursor(0, { math.min(item.line, vim.api.nvim_buf_line_count(0)), 0 })
  vim.cmd("normal! zz")
end

--- Next/previous bookmark across files (wraps around), like VS Code Bookmarks.
function M.next(direction)
  local items = M.list()
  if #items == 0 then
    return vim.notify("No bookmarks in this project", vim.log.levels.INFO)
  end
  local rel, line = relpath(0) or "", vim.fn.line(".")
  local function after(item)
    return item.rel > rel or (item.rel == rel and item.line > line)
  end
  local function before(item)
    return item.rel < rel or (item.rel == rel and item.line < line)
  end
  if direction > 0 then
    for _, item in ipairs(items) do
      if after(item) then
        return jump(item)
      end
    end
    jump(items[1])
  else
    for i = #items, 1, -1 do
      if before(items[i]) then
        return jump(items[i])
      end
    end
    jump(items[#items])
  end
end

function M.pick(current_file)
  local rel = relpath(0)
  Snacks.picker.pick({
    title = current_file and "Bookmarks (file)" or "Bookmarks",
    finder = function()
      local items = {}
      for _, item in ipairs(M.list()) do
        if not current_file or item.rel == rel then
          items[#items + 1] =
            { file = item.file, pos = { item.line, 0 }, text = item.rel .. " " .. item.text, line = item.text }
        end
      end
      return items
    end,
    format = "file",
    actions = {
      delete_bookmark = function(picker, item)
        if not item then
          return
        end
        local buf = vim.fn.bufnr(item.file)
        if buf > 0 and vim.api.nvim_buf_is_loaded(buf) then
          local mark = mark_at(buf, item.pos[1])
          if mark then
            vim.api.nvim_buf_del_extmark(buf, ns, mark[1])
          end
        else
          local bookmarks = load()
          local r = vim.fs.relpath(store_root, item.file)
          if not r then
            return
          end
          bookmarks[r] = vim.tbl_filter(function(m)
            return m.line ~= item.pos[1]
          end, bookmarks[r] or {})
          if #bookmarks[r] == 0 then
            bookmarks[r] = nil
          end
        end
        save()
        picker:find()
      end,
    },
    win = { input = { keys = { ["<C-d>"] = { "delete_bookmark", mode = { "n", "i" }, desc = "Delete bookmark" } } } },
  })
end

function M.clear(all)
  if all then
    vim.ui.select({ "Cancel", "Clear" }, { prompt = "Clear all bookmarks in this project?" }, function(choice)
      if choice ~= "Clear" then
        return
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        end
      end
      store = {}
      save()
    end)
  else
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    save()
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("personal_bookmarks", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(e)
      place(e.buf)
    end,
  })
  -- Re-anchor by text after an external reload. (No FileChangedShell handler: defining
  -- one replaces Neovim's reload/conflict prompt. Reloads only happen to unmodified
  -- buffers, whose stored positions are current as of their last write/toggle.)
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = group,
    callback = function(e)
      place(e.buf)
      save()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufUnload", "VimLeavePre" }, {
    group = group,
    callback = function(e)
      if e.event == "BufUnload" then
        sync(e.buf)
      end
      save()
    end,
  })
  vim.api.nvim_create_autocmd("DirChangedPre", {
    group = group,
    callback = function()
      save()
      store = nil
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        place(buf)
      end
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    place(buf)
  end

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<leader>bt", M.toggle, "Toggle bookmark")
  map("<leader>bm", M.toggle, "Toggle bookmark")
  map("<leader>bj", function()
    M.next(1)
  end, "Next bookmark")
  map("<leader>bk", function()
    M.next(-1)
  end, "Previous bookmark")
  map("<leader>bl", function()
    M.pick(false)
  end, "Bookmarks (project)")
  map("<leader>bL", function()
    M.pick(true)
  end, "Bookmarks (current file)")
  map("<leader>bc", function()
    M.clear(false)
  end, "Clear bookmarks in file")
  map("<leader>bC", function()
    M.clear(true)
  end, "Clear all project bookmarks")
  map("<leader>sm", function()
    M.pick(false)
  end, "Search bookmarks")
end

return M
