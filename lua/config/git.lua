local M = {}

function M.attach(buf)
  local gs = require("gitsigns")
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end
  local function navigate(direction)
    if vim.wo.diff then
      vim.cmd.normal({ args = { direction == "next" and "]c" or "[c" }, bang = true })
    else
      gs.nav_hunk(direction)
    end
  end
  map("n", "]c", function()
    navigate("next")
  end, "Next Git hunk")
  map("n", "[c", function()
    navigate("prev")
  end, "Previous Git hunk")
  map("n", "<leader>gj", function()
    navigate("next")
  end, "Next Git hunk")
  map("n", "<leader>gk", function()
    navigate("prev")
  end, "Previous Git hunk")
  map("n", "<leader>gv", gs.preview_hunk, "Preview Git hunk")
  map("n", "<leader>gs", gs.stage_hunk, "Stage/unstage hunk")
  map("x", "<leader>gs", function()
    local range = { math.min(vim.fn.line("."), vim.fn.line("v")), math.max(vim.fn.line("."), vim.fn.line("v")) }
    vim.cmd.normal({ args = { "\27" }, bang = true })
    gs.stage_hunk(range)
  end, "Stage/unstage selected lines")
  map("n", "<leader>gS", gs.stage_buffer, "Stage file buffer")
  map("n", "<leader>gU", gs.reset_buffer_index, "Unstage file (keep edits)")
  map("n", "<leader>gr", function()
    M.reset(false)
  end, "Reset hunk (confirm)")
  map("x", "<leader>gr", function()
    M.reset(false, true)
  end, "Reset selected lines (confirm)")
  map("n", "<leader>gR", function()
    M.reset(true)
  end, "Reset file buffer (confirm)")
  map("n", "<leader>gb", function()
    M.blame_popup()
  end, "Blame line (focused; o opens PR)")
  map("n", "<leader>gp", function()
    M.pull_request("open")
  end, "Open PR for current line")
  map("n", "<leader>gP", function()
    M.pull_request("copy")
  end, "Copy PR link for current line")
  map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")
end

-- Blame → pull request ------------------------------------------------------

local pr_cache = {} -- sha -> PR list (GitHub results are stable per commit)

--- Blame one line of the buffer as currently edited (stdin contents keep line
--- numbers aligned with unsaved edits). Calls back with commit info or an error.
local function blame(buf, lnum, callback)
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or vim.bo[buf].buftype ~= "" then
    return callback(nil, "Blame needs a file buffer")
  end
  local cwd = vim.fs.dirname(file)
  local contents = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
  vim.system(
    { "git", "blame", "--porcelain", "-L", lnum .. "," .. lnum, "--contents", "-", "--", file },
    { cwd = cwd, text = true, stdin = contents },
    function(res)
      vim.schedule(function()
        local sha = res.code == 0 and res.stdout:match("^(%x+)") or nil
        if not sha then
          return callback(nil, "Git blame failed: " .. vim.trim(res.stderr or ""))
        end
        if sha:match("^0+$") then
          return callback(nil, "Line is not committed yet")
        end
        callback({ sha = sha, summary = res.stdout:match("\nsummary ([^\n]*)") or "", cwd = cwd })
      end)
    end
  )
end

--- All PRs containing the commit (open or merged; squash/merge commits included).
local function find_prs(commit, callback)
  if pr_cache[commit.sha] then
    return callback(pr_cache[commit.sha])
  end
  if vim.fn.executable("gh") ~= 1 then
    return callback(nil, "gh CLI not found")
  end
  vim.system({
    "gh",
    "api",
    "repos/{owner}/{repo}/commits/" .. commit.sha .. "/pulls",
    "--jq",
    "[.[] | {number, title, url: .html_url, state, merged: (.merged_at != null)}]",
  }, { cwd = commit.cwd, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return callback(nil, vim.trim(res.stderr or "gh failed"))
      end
      local ok, prs = pcall(vim.json.decode, res.stdout)
      if not ok then
        return callback(nil, "Unexpected gh output")
      end
      pr_cache[commit.sha] = prs
      callback(prs)
    end)
  end)
end

-- Snacks resolves the remote (GitHub/GitLab/Bitbucket/…) from the current file.
local function commit_url(commit, callback)
  local ok, err = pcall(Snacks.gitbrowse, { what = "commit", commit = commit.sha, notify = false, open = callback })
  if not ok then
    vim.notify("No browsable remote for this commit: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function deliver(url, action, label)
  if action == "copy" then
    vim.fn.setreg("+", url)
    vim.notify("Copied " .. label .. ": " .. url)
  else
    vim.ui.open(url)
    vim.notify("Opened " .. label)
  end
end

local function describe(pr)
  local state = pr.merged and "merged" or pr.state
  return ("#%d %s (%s)"):format(pr.number, pr.title, state)
end

--- Resolve the PR for a commit and open/copy it; falls back to the commit page.
function M.resolve_pr(commit, action)
  find_prs(commit, function(prs, err)
    if not prs or #prs == 0 then
      local reason = err and ("PR lookup failed (" .. err .. ")") or "No PR contains " .. commit.sha:sub(1, 7)
      vim.notify(reason .. "; using the commit page", vim.log.levels.WARN)
      return commit_url(commit, function(url)
        deliver(url, action, "commit")
      end)
    end
    if #prs == 1 then
      return deliver(prs[1].url, action, "PR #" .. prs[1].number)
    end
    vim.ui.select(
      prs,
      { prompt = "Pull requests containing " .. commit.sha:sub(1, 7), format_item = describe },
      function(pr)
        if pr then
          deliver(pr.url, action, "PR #" .. pr.number)
        end
      end
    )
  end)
end

function M.pull_request(action)
  blame(vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1], function(commit, err)
    if not commit then
      return vim.notify(err, vim.log.levels.WARN)
    end
    M.resolve_pr(commit, action)
  end)
end

local function blame_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[win].gitsigns_preview == "blame" then
      return win
    end
  end
end

local function set_footer(win, text)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, { footer = { { " " .. text .. " ", "FloatFooter" } }, footer_pos = "right" })
  end
end

--- Full blame popup that takes focus (so j/k scroll it instead of closing it),
--- with PR shortcuts and the resolved PR shown in its footer.
function M.blame_popup()
  local buf, lnum = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
  require("gitsigns").blame_line({ full = true }, function()
    vim.schedule(function()
      local win = blame_window()
      if not win then
        return
      end
      vim.api.nvim_set_current_win(win)
      local popup = vim.api.nvim_win_get_buf(win)
      local function close()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end
      local hints = "o PR · y copy PR · c commit · q close"
      set_footer(win, hints)
      blame(buf, lnum, function(commit)
        if not commit then
          return
        end
        local function key(lhs, fn, desc)
          vim.keymap.set("n", lhs, fn, { buffer = popup, nowait = true, desc = desc })
        end
        key("o", function()
          close()
          M.resolve_pr(commit, "open")
        end, "Open PR")
        key("y", function()
          close()
          M.resolve_pr(commit, "copy")
        end, "Copy PR link")
        key("c", function()
          close()
          commit_url(commit, function(url)
            deliver(url, "open", "commit")
          end)
        end, "Open commit")
        find_prs(commit, function(prs)
          if not prs or not vim.api.nvim_win_is_valid(win) then
            return
          end
          local first = prs[1]
          local label = #prs == 0 and "no PR"
            or (
              #prs == 1 and ("PR #%d (%s)"):format(first.number, first.merged and "merged" or first.state)
              or (#prs .. " PRs")
            )
          set_footer(win, label .. " · " .. hints)
        end)
      end)
      vim.keymap.set("n", "q", close, { buffer = popup, nowait = true, desc = "Close blame" })
      vim.keymap.set("n", "<Esc>", close, { buffer = popup, nowait = true, desc = "Close blame" })
    end)
  end)
end

function M.reset(all, visual)
  local gs = require("gitsigns")
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local tick, cursor = vim.api.nvim_buf_get_changedtick(buf), vim.api.nvim_win_get_cursor(win)
  local hunks = vim.deepcopy(gs.get_hunks(buf))
  if not hunks or #hunks == 0 then
    vim.notify("No unstaged hunks to reset", vim.log.levels.INFO)
    return
  end
  local range = visual and { math.min(cursor[1], vim.fn.line("v")), math.max(cursor[1], vim.fn.line("v")) } or nil
  if visual then
    vim.cmd.normal({ args = { "\27" }, bang = true })
  end
  local target = all and "all unstaged edits" or (visual and "selected unstaged lines" or "the current unstaged hunk")
  vim.ui.select({ "Cancel", "Reset" }, {
    prompt = "Discard " .. target .. " in " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t") .. "?",
  }, function(choice)
    if choice ~= "Reset" then
      return
    end
    if
      not vim.api.nvim_buf_is_valid(buf)
      or not vim.api.nvim_win_is_valid(win)
      or vim.api.nvim_win_get_buf(win) ~= buf
      or vim.api.nvim_buf_get_changedtick(buf) ~= tick
      or not vim.deep_equal(gs.get_hunks(buf), hunks)
      or (not all and not range and vim.api.nvim_win_get_cursor(win)[1] ~= cursor[1])
    then
      vim.notify("Git context changed; review the hunk and reset again", vim.log.levels.WARN)
      return
    end
    vim.api.nvim_win_call(win, function()
      if all then
        gs.reset_buffer()
      else
        gs.reset_hunk(range)
      end
    end)
  end)
end

function M.diffview()
  local actions = require("diffview.actions")
  local function close()
    vim.cmd.DiffviewClose()
  end
  local function shared()
    return {
      { "n", "<C-x>", close, { desc = "Close Git review" } },
      { "n", "<leader>gq", close, { desc = "Close Git review" } },
      { "n", "<C-e>", actions.focus_files, { desc = "Focus Git files" } },
      { "n", "<Tab>", actions.select_next_entry, { desc = "Next changed file" } },
      { "n", "<S-Tab>", actions.select_prev_entry, { desc = "Previous changed file" } },
      { "n", "H", actions.select_prev_entry, { desc = "Previous changed file" } },
      { "n", "L", actions.select_next_entry, { desc = "Next changed file" } },
      { "n", "gf", actions.goto_file_edit, { desc = "Open file outside review" } },
    }
  end
  local files, history = shared(), shared()
  for _, maps in ipairs({ files, history }) do
    vim.list_extend(maps, {
      { "n", "j", actions.next_entry },
      { "n", "k", actions.prev_entry },
      { "n", "<CR>", actions.select_entry },
      { "n", "o", actions.select_entry },
      { "n", "l", actions.select_entry },
      { "n", "h", actions.close_fold },
      { "n", "q", close },
    })
  end
  vim.list_extend(files, {
    { "n", "s", actions.toggle_stage_entry, { desc = "Stage/unstage selected file" } },
    { "n", "R", actions.refresh_files, { desc = "Refresh Git changes" } },
  })
  return {
    enhanced_diff_hl = true,
    file_panel = {
      win_config = {
        width = 35,
        win_opts = { winhighlight = "Normal:GithubUiPanel,NormalNC:GithubUiPanel,CursorLine:GithubUiSelection" },
      },
    },
    file_history_panel = {
      win_config = {
        win_opts = { winhighlight = "Normal:GithubUiPanel,NormalNC:GithubUiPanel,CursorLine:GithubUiSelection" },
      },
    },
    view = { default = { layout = "diff2_horizontal" }, file_history = { layout = "diff2_horizontal" } },
    keymaps = { disable_defaults = true, view = shared(), file_panel = files, file_history_panel = history },
    hooks = {
      diff_buf_win_enter = function(buf, win, ctx)
        vim.wo[win].wrap = false
        vim.wo[win].list = false
        if ctx.layout_name == "diff2_horizontal" then
          local side = ctx.symbol == "a" and "Removed" or "Added"
          local highlights = vim.tbl_filter(function(item)
            return not item:match("^DiffChange:") and not item:match("^DiffText:")
          end, vim.split(vim.wo[win].winhighlight, ",", { trimempty = true }))
          vim.list_extend(
            highlights,
            { "DiffChange:GitReview" .. side .. "Line", "DiffText:GitReview" .. side .. "Text" }
          )
          vim.wo[win].winhighlight = table.concat(highlights, ",")
        end
        -- The panel may be the only window when lualine first caches this tab's focus.
        if vim.bo[buf].buftype == "" then
          vim.api.nvim_win_call(win, function()
            require("lualine").refresh({ place = { "statusline" }, force = true })
          end)
        end
      end,
    },
  }
end

return M
