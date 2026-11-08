local M = {}

-- Installed eagerly; any other language is installed the first time a buffer needs it.
M.parsers = {
  "python", "javascript", "typescript", "tsx", "sql", "yaml", "json",
  "ini", "toml", "lua", "bash", "markdown", "markdown_inline", "regex", "vim", "vimdoc",
  "diff", "gitcommit", "git_rebase", "gitignore", "dockerfile", "html", "css", "query",
}

-- Parsers outside the nvim-treesitter registry. Pin revisions; bump deliberately.
M.custom = {
  gritql = {
    install_info = {
      url = "https://github.com/biomejs/tree-sitter-gritql",
      revision = "ecaec54b30685c23e65013b2f116a1fb65284f2e",
      queries = "queries",
    },
  },
}

local function register_custom()
  local parsers = require("nvim-treesitter.parsers")
  for lang, spec in pairs(M.custom) do parsers[lang] = spec end
end

local attempted = {}

local function attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then return false end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang or not vim.treesitter.language.add(lang) then return false end
  if not pcall(vim.treesitter.start, buf, lang) then return false end
  if vim.treesitter.query.get(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  return true
end

-- Install a missing parser in the background, then attach every buffer using it.
local function ensure(buf)
  if attach(buf) then return end
  local ft = vim.bo[buf].filetype
  if ft == "" or vim.bo[buf].buftype ~= "" then return end
  local lang = vim.treesitter.language.get_lang(ft)
  if not lang or attempted[lang] or vim.fn.executable("tree-sitter") ~= 1 then return end
  if not vim.tbl_contains(require("nvim-treesitter").get_available(), lang) then return end
  attempted[lang] = true
  require("nvim-treesitter").install(lang):await(function(err)
    vim.schedule(function()
      if err then return end
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.treesitter.language.get_lang(vim.bo[b].filetype) == lang then
          attach(b)
        end
      end
    end)
  end)
end

function M.setup()
  local treesitter = require("nvim-treesitter")
  treesitter.setup()
  register_custom()

  vim.filetype.add({ extension = { grit = "gritql" } })
  vim.treesitter.language.register("ini", { "dosini", "ini" })
  vim.treesitter.language.register("json", "jsonc")

  local group = vim.api.nvim_create_augroup("personal_treesitter", { clear = true })
  -- :TSUpdate rebuilds the registry, which drops custom entries unless re-added.
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "TSUpdate", callback = register_custom })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(event) ensure(event.buf) end,
  })

  -- Background install of the baseline set (a no-op once present).
  local function install()
    if vim.fn.executable("tree-sitter") ~= 1 then return end
    local installed = treesitter.get_installed()
    local missing = vim.tbl_filter(function(lang) return not vim.tbl_contains(installed, lang) end, M.parsers)
    if #missing == 0 then return end
    treesitter.install(missing):await(function()
      vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then attach(buf) end
        end
      end)
    end)
  end
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "MasonToolsUpdateCompleted", callback = install })
  vim.schedule(install)
end

return M
