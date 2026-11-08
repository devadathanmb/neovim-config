-- Language servers, diagnostics, completion, hover/rename, formatters, schemas.
-- Optional: NVIM_TEST_ESLINT_NODE_MODULES, NVIM_TEST_REMOTE_SCHEMAS=1 (see AGENTS.md).
local h = dofile(vim.fn.stdpath("config") .. "/tests/helpers.lua")
local mason = vim.fn.stdpath("data") .. "/mason/bin/"
local temp

local function write(name, lines)
  local path = temp .. "/" .. name
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
  return path
end
local function open(name, lines)
  local path = write(name, lines)
  vim.cmd.edit(path)
  return vim.api.nvim_get_current_buf(), path
end
local function client(name, buf)
  h.wait(function()
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf, name = name })) do
      if c.initialized then
        return true
      end
    end
    return false
  end, "server did not attach: " .. name, 20000)
  return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
end
local function diagnostic(buf, predicate, label)
  assert(
    vim.wait(20000, function()
      for _, d in ipairs(vim.diagnostic.get(buf)) do
        if predicate(d) then
          return true
        end
      end
      return false
    end, 100),
    "missing diagnostic: " .. label .. " " .. vim.inspect(vim.diagnostic.get(buf))
  )
end
local function format(buf)
  local done, failure
  require("conform").format({ bufnr = buf, async = true }, function(err)
    failure = err
    done = true
  end)
  h.wait(function()
    return done
  end, "formatter timed out", 20000)
  assert(not failure, tostring(failure))
end
local function completion(c, buf, line, character, label)
  local result = c:request_sync("textDocument/completion", {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    position = { line = line, character = character },
    context = { triggerKind = 1 },
  }, 15000, buf)
  assert(result and not result.err, "completion request failed: " .. c.name)
  local items = result.result and (result.result.items or result.result) or {}
  for _, item in ipairs(items) do
    if item.label == label then
      return
    end
  end
  error("completion not found: " .. c.name .. " / " .. label .. " " .. vim.inspect(items))
end
local function line(buf, n)
  return vim.api.nvim_buf_get_lines(buf, n - 1, n, false)[1]
end
local function stop_clients()
  local clients = vim.lsp.get_clients({ _uninitialized = true })
  for _, c in ipairs(clients) do
    c:stop(5000)
  end
  -- is_stopped() is already true while shutdown is pending; wait for exit/removal.
  return vim.wait(10000, function()
    for _, c in ipairs(clients) do
      if vim.lsp.get_client_by_id(c.id) then
        return false
      end
    end
    return true
  end, 50)
end

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      temp = vim.fn.resolve(vim.fn.fnamemodify(vim.fn.tempname(), ":h")) .. "/nvim-language-" .. vim.fn.getpid()
      vim.fn.mkdir(temp, "p")
    end,
    pre_case = h.no_errors.pre_case,
    post_case = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          vim.bo[buf].modified = false
        end
      end
      h.no_errors.post_case()
    end,
    post_once = function()
      -- Keep the workspace if servers are still running inside it.
      if not stop_clients() then
        return
      end
      vim.cmd("silent! %bwipeout!")
      vim.fn.delete(temp, "rf")
    end,
  },
})

T["setup"] = MiniTest.new_set()

T["setup"]["tools come from Mason"] = function()
  for _, executable in ipairs({
    "basedpyright-langserver",
    "ruff",
    "tsc",
    "vscode-eslint-language-server",
    "yaml-language-server",
    "vscode-json-language-server",
    "lua-language-server",
    "docker-langserver",
    "black",
    "prettier",
    "sqlfluff",
    "stylua",
    "tree-sitter",
  }) do
    assert(vim.fn.exepath(executable):find(mason, 1, true) == 1, "tool is not Mason-local: " .. executable)
  end
end

T["setup"]["completion keys and no ghost text"] = function()
  local blink = require("blink.cmp.config")
  h.eq(blink.completion.ghost_text.enabled(), false)
  h.eq(blink.keymap["<C-;>"], { "hide", "show" })
  h.eq(blink.keymap["<C-Space>"], { "show", "show_documentation", "hide_documentation" })
end

T["setup"]["baseline parsers are installed"] = function()
  for _, parser in ipairs(require("config.treesitter").parsers) do
    assert(vim.treesitter.language.add(parser), "missing parser: " .. parser)
  end
end

T["lua"] = MiniTest.new_set()

T["lua"]["diagnostics and completion without Neovim runtime"] = function()
  write("lua-project/.luarc.json", { "{}" })
  local buf = open("lua-project/sample.lua", { "unknown_lua_global()", "math.ab" })
  local lua = client("lua_ls", buf)
  assert(not (lua.config.settings.Lua.workspace or {}).library, "Neovim runtime leaked into another Lua project")
  diagnostic(buf, function(d)
    return d.code == "undefined-global"
  end, "Lua undefined global")
  completion(lua, buf, 1, 7, "abs(x)")
end

T["lua"]["config workspace gets the Neovim runtime"] = function()
  vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/init.lua"))
  local lua = client("lua_ls", vim.api.nvim_get_current_buf())
  h.eq(lua.config.settings.Lua.runtime.version, "LuaJIT")
  assert(
    vim.tbl_contains(lua.config.settings.Lua.workspace.library, vim.env.VIMRUNTIME),
    "Neovim runtime library missing"
  )
end

T["lua"]["StyLua formats manually with project config"] = function()
  write("lua-project/stylua.toml", { 'indent_type = "Spaces"', "indent_width = 2" })
  local buf = open("lua-project/format.lua", { "local function greet()", 'print("hello")', "end" })
  format(buf)
  h.eq(line(buf, 2), '  print("hello")')
  vim.api.nvim_buf_set_lines(buf, 1, 2, false, { 'print("hello")' })
  vim.cmd("silent write")
  h.eq(line(buf, 2), 'print("hello")')
end

T["dockerfile LSP, highlighting and formatting"] = function()
  local buf = open("docker/Dockerfile", { "FROM alpine", "BADINSTRUCTION value" })
  local dockerls = client("dockerls", buf)
  assert(vim.treesitter.highlighter.active[buf], "Dockerfile Tree-sitter highlighting not active")
  diagnostic(buf, function(d)
    return d.message:lower():find("badinstruction", 1, true) ~= nil
  end, "Dockerfile invalid instruction")
  assert(dockerls:supports_method("textDocument/formatting", buf), "Dockerfile formatting not supported")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "FROM alpine", "  RUN echo hello" })
  format(buf)
  h.eq(line(buf, 2), "RUN echo hello")
end

T["python"] = MiniTest.new_set()

T["python"]["project venv, diagnostics, completion and mappings"] = function()
  write("pyproject.toml", { "[project]", 'name = "neovim-language-test"', 'version = "0.0.0"' })
  vim.fn.mkdir(temp .. "/.venv/bin", "p")
  assert(vim.uv.fs_symlink(vim.fn.exepath("python3"), temp .. "/.venv/bin/python"))
  h.eq(require("config.languages.python").python_path(temp), temp .. "/.venv/bin/python")
  local buf = open("sample.py", { "import os", 'value: int = "wrong"', "unknown_name", "os.pa" })
  local pyright = client("basedpyright", buf)
  local ruff = client("ruff", buf)
  assert(not ruff.server_capabilities.hoverProvider, "Ruff hover must not override basedpyright")
  h.eq(pyright.settings.python.pythonPath, temp .. "/.venv/bin/python")
  diagnostic(buf, function(d)
    return d.source == "basedpyright"
  end, "Python types")
  diagnostic(buf, function(d)
    return d.source == "Ruff" and d.code == "F821"
  end, "Ruff undefined name")
  completion(pyright, buf, 3, 5, "path")
  h.eq(vim.fn.maparg("gd", "n", false, true).buffer, 1)
end

T["python"]["Ruff organizes imports"] = function()
  local buf = open("imports.py", { "import sys", "import os", "print(os.name, sys.version)" })
  client("basedpyright", buf)
  client("ruff", buf)
  h.action("<Space>li")
  h.wait(function()
    return line(buf, 1) == "import os"
  end, "Ruff organize imports action failed", 10000)
end

T["python"]["bordered hover and rename"] = function()
  local buf =
    open("symbols.py", { "def greet(name: str) -> str:", "    return name.upper()", "", 'greeting = greet("hello")' })
  local pyright = client("basedpyright", buf)
  local position = { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = 5 } }
  local hover = pyright:request_sync("textDocument/hover", position, 10000, buf)
  assert(hover and not hover.err and hover.result and hover.result.contents, "Python hover failed")
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  vim.lsp.buf.hover()
  local hover_win
  h.wait(function()
    for _, win in ipairs(h.floats()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "markdown" then
        hover_win = win
        return true
      end
    end
  end, "LSP hover window did not open", 5000)
  h.assert_rounded(hover_win, "LSP hover")
  vim.api.nvim_win_close(hover_win, true)
  local rename =
    pyright:request_sync("textDocument/rename", vim.tbl_extend("force", position, { newName = "salute" }), 10000, buf)
  assert(rename and not rename.err and rename.result, "Python rename failed")
  vim.lsp.util.apply_workspace_edit(rename.result, pyright.offset_encoding)
  local renamed = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  h.eq({ renamed[1], renamed[4] }, { "def salute(name: str) -> str:", 'greeting = salute("hello")' })
end

T["python"]["Black formats manually, never on save"] = function()
  local buf = open("format.py", { "value={'one':1,'two':2}" })
  format(buf)
  h.eq(line(buf, 1), 'value = {"one": 1, "two": 2}')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "value=  1" })
  vim.cmd("silent write")
  vim.wait(300)
  h.eq(line(buf, 1), "value=  1")
end

T["typescript"] = MiniTest.new_set()

T["typescript"]["diagnostics and completion; ESLint off without config"] = function()
  write("package.json", { '{"name":"neovim-language-test","private":true}' })
  write("package-lock.json", { '{"lockfileVersion":3}' })
  write("tsconfig.json", { '{"compilerOptions":{"strict":true,"noEmit":true},"include":["*.ts"]}' })
  local buf = open("sample.ts", { 'const answer: number = "wrong";', "Math.ab" })
  local ts = client("tsc", buf)
  diagnostic(buf, function(d)
    return tonumber(d.code) == 2322
  end, "TypeScript types")
  completion(ts, buf, 1, 7, "abs")
  h.eq(#vim.lsp.get_clients({ bufnr = buf, name = "eslint" }), 0)
end

T["typescript"]["Prettier formats manually"] = function()
  local buf = open("format.ts", { "const answer={one:1,two:2}" })
  format(buf)
  h.eq(line(buf, 1), "const answer = { one: 1, two: 2 };")
end

T["typescript"]["project ESLint diagnostics and fix-all"] = function()
  local modules = vim.env.NVIM_TEST_ESLINT_NODE_MODULES
  if not modules or modules == "" then
    MiniTest.skip("set NVIM_TEST_ESLINT_NODE_MODULES to an installed project's node_modules")
  end
  modules = vim.fn.fnamemodify(modules, ":p"):gsub("/$", "")
  assert(vim.fn.filereadable(modules .. "/eslint/package.json") == 1, "ESLint library not found in " .. modules)
  write("eslint/package.json", { '{"name":"neovim-eslint-test","private":true}' })
  write("eslint/package-lock.json", { '{"lockfileVersion":3}' })
  write("eslint/eslint.config.cjs", {
    'module.exports = [{ files: ["**/*.js"], rules: { "no-undef": "error", semi: ["error", "always"] } }];',
  })
  assert(vim.uv.fs_symlink(modules, temp .. "/eslint/node_modules", { dir = true }))
  local buf = open("eslint/sample.js", { "unknown_name()" })
  client("eslint", buf)
  diagnostic(buf, function(d)
    return d.source == "eslint" and d.code == "no-undef"
  end, "ESLint no-undef")
  diagnostic(buf, function(d)
    return d.source == "eslint" and d.code == "semi"
  end, "ESLint semi")
  vim.cmd("LspEslintFixAll")
  h.wait(function()
    return line(buf, 1) == "unknown_name();"
  end, "ESLint fix-all failed", 10000)
end

T["schemas"] = MiniTest.new_set()

T["schemas"]["YAML local schema"] = function()
  write(
    "schema.json",
    { '{"type":"object","required":["required_field"],"properties":{"required_field":{"type":"string"}}}' }
  )
  local buf = open("sample.yaml", { "# yaml-language-server: $schema=./schema.json", "other: value" })
  client("yamlls", buf)
  diagnostic(buf, function(d)
    return d.message:find("required_field", 1, true)
  end, "YAML local schema")
end

T["schemas"]["JSONC local schema and highlighting"] = function()
  local buf = open("sample.jsonc", { "// comments are valid JSONC", '{"$schema":"./schema.json","other":1}' })
  client("jsonls", buf)
  diagnostic(buf, function(d)
    return d.message:find("required_field", 1, true)
  end, "JSONC local schema")
  h.eq(vim.treesitter.get_parser(buf):lang(), "json")
end

T["schemas"]["Kubernetes schemas only for k8s paths"] = function()
  if vim.env.NVIM_TEST_REMOTE_SCHEMAS ~= "1" then
    MiniTest.skip("set NVIM_TEST_REMOTE_SCHEMAS=1; requires network")
  end
  local manifest = {
    "apiVersion: apps/v1",
    "kind: Deployment",
    "metadata:",
    "  name: neovim-test",
    "spec:",
    '  replicas: "not-a-number"',
    "  selector:",
    "    matchLabels:",
    "      app: neovim-test",
    "  template:",
    "    metadata:",
    "      labels:",
    "        app: neovim-test",
    "    spec:",
    "      containers:",
    "        - name: test",
    "          image: nginx:latest",
  }
  local function has_kubernetes_schema(c, buffer)
    local response = c:request_sync("yaml/get/jsonSchema", vim.uri_from_bufnr(buffer), 30000, buffer)
    assert(response and not response.err, "schema selection request failed: " .. vim.inspect(response))
    for _, schema in ipairs(response.result or {}) do
      if schema.uri:lower():find("kubernetes", 1, true) then
        return true
      end
    end
    return false
  end
  for _, name in ipairs({ "deployment.k8s.yaml", "k8s/deployment.yaml", "kubernetes/deployment.yml" }) do
    local buf = open(name, manifest)
    assert(has_kubernetes_schema(client("yamlls", buf), buf), "Kubernetes schema not selected: " .. name)
    diagnostic(buf, function(d)
      return d.lnum == 5 and d.message:lower():find("integer", 1, true)
    end, "Kubernetes replicas type: " .. name)
  end
  local buf = open("unrelated.yaml", manifest)
  assert(not has_kubernetes_schema(client("yamlls", buf), buf), "Kubernetes schema leaked into unrelated YAML")
end

T["sql"] = MiniTest.new_set()

T["sql"]["SQLFluff lints and formats"] = function()
  local buf = open("sample.sql", { "select  1 as one" })
  require("lint").try_lint("sqlfluff")
  diagnostic(buf, function(d)
    return d.source == "sqlfluff"
  end, "SQLFluff")
  format(buf)
  assert(
    not table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find("select  1", 1, true),
    "SQLFluff did not format"
  )
end

T["sql"]["project dialect overrides the Postgres default"] = function()
  write("mysql/.sqlfluff", { "[sqlfluff]", "dialect = mysql" })
  local file = write("mysql/sample.sql", { "SELECT `one` FROM `table`;" })
  local result = vim
    .system({ mason .. "sqlfluff", "lint", "--format=json", "--stdin-filename", file, "-" }, {
      cwd = temp,
      stdin = "SELECT `one` FROM `table`;\n",
      text = true,
    })
    :wait(15000)
  assert(result.code == 0 or result.code == 1, "SQLFluff config failed: " .. (result.stderr or ""))
  for _, entry in ipairs(vim.json.decode(result.stdout)) do
    for _, violation in ipairs(entry.violations) do
      assert(violation.code ~= "PRS", "Postgres default overrode MySQL project config")
    end
  end
end

T["INI highlighting"] = function()
  local buf = open("sample.ini", { "[section]", "key=value" })
  h.eq(vim.treesitter.get_parser(buf):lang(), "ini")
end

-- Last: servers must exit before post_once deletes their workspace.
T["LSP clients exit cleanly"] = function()
  assert(stop_clients(), "LSP teardown timed out; temporary workspace retained: " .. temp)
end

return T
