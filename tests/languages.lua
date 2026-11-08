local temp = vim.fn.resolve(vim.fn.fnamemodify(vim.fn.tempname(), ":h")) .. "/nvim-language-" .. vim.fn.getpid()
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
  assert(vim.wait(20000, function()
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf, name = name })) do
      if c.initialized then return true end
    end
    return false
  end, 50), "server did not attach: " .. name)
  return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
end
local function diagnostic(buf, predicate, label)
  assert(vim.wait(20000, function()
    for _, d in ipairs(vim.diagnostic.get(buf)) do
      if predicate(d) then return true end
    end
    return false
  end, 100), "missing diagnostic: " .. label .. " " .. vim.inspect(vim.diagnostic.get(buf)))
end
local function format(buf)
  local done, failure
  require("conform").format({ bufnr = buf, async = true }, function(err)
    failure = err
    done = true
  end)
  assert(vim.wait(20000, function() return done end, 50), "formatter timed out")
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
    if item.label == label then return end
  end
  error("completion not found: " .. c.name .. " / " .. label .. " " .. vim.inspect(items))
end

local function run()
  local mason = vim.fn.stdpath("data") .. "/mason/bin/"
  for _, executable in ipairs({ "basedpyright-langserver", "ruff", "tsc", "vscode-eslint-language-server", "yaml-language-server", "vscode-json-language-server", "lua-language-server", "docker-langserver", "black", "prettier", "sqlfluff", "stylua", "tree-sitter" }) do
    assert(vim.fn.exepath(executable):find(mason, 1, true) == 1, "tool is not Mason-local: " .. executable)
  end
  assert(require("blink.cmp.config").completion.ghost_text.enabled() == false)
  for _, parser in ipairs(require("config.treesitter").parsers) do
    assert(vim.treesitter.language.add(parser), "missing parser: " .. parser)
  end
  write("lua-project/.luarc.json", { '{}' })
  local lua_buf = open("lua-project/sample.lua", { "unknown_lua_global()", "math.ab" })
  local lua = client("lua_ls", lua_buf)
  assert(not (lua.config.settings.Lua.workspace or {}).library, "Neovim runtime leaked into another Lua project")
  diagnostic(lua_buf, function(d) return d.code == "undefined-global" end, "Lua undefined global")
  completion(lua, lua_buf, 1, 7, "abs(x)")
  vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/init.lua"))
  local config_buf = vim.api.nvim_get_current_buf()
  local config_lua = client("lua_ls", config_buf)
  assert(config_lua.config.settings.Lua.runtime.version == "LuaJIT", "Neovim Lua runtime not configured")
  assert(vim.tbl_contains(config_lua.config.settings.Lua.workspace.library, vim.env.VIMRUNTIME), "Neovim runtime library missing")
  write("lua-project/stylua.toml", { 'indent_type = "Spaces"', "indent_width = 2" })
  lua_buf = open("lua-project/format.lua", { "local function greet()", 'print("hello")', "end" })
  format(lua_buf)
  assert(vim.api.nvim_buf_get_lines(lua_buf, 1, 2, false)[1] == '  print("hello")', "StyLua ignored project config")
  vim.api.nvim_buf_set_lines(lua_buf, 1, 2, false, { 'print("hello")' })
  vim.cmd.write()
  assert(vim.api.nvim_buf_get_lines(lua_buf, 1, 2, false)[1] == 'print("hello")', "save unexpectedly formatted Lua")
  print("PASS: Lua LSP diagnostics, completion, workspace settings and manual StyLua formatting")

  local docker = open("docker/Dockerfile", { "FROM alpine", "BADINSTRUCTION value" })
  local dockerls = client("dockerls", docker)
  assert(vim.treesitter.highlighter.active[docker], "Dockerfile Tree-sitter highlighting not active")
  diagnostic(docker, function(d) return d.message:lower():find("badinstruction", 1, true) ~= nil end, "Dockerfile invalid instruction")
  assert(dockerls:supports_method("textDocument/formatting", docker), "Dockerfile formatting not supported")
  vim.api.nvim_buf_set_lines(docker, 0, -1, false, { "FROM alpine", "  RUN echo hello" })
  format(docker)
  assert(vim.api.nvim_buf_get_lines(docker, 1, 2, false)[1] == "RUN echo hello", "Dockerfile formatter did not apply edits")
  vim.bo[docker].modified = false
  print("PASS: Dockerfile LSP, diagnostics, highlighting and manual formatting")

  write("pyproject.toml", { "[project]", 'name = "neovim-language-test"', 'version = "0.0.0"' })
  vim.fn.mkdir(temp .. "/.venv/bin", "p")
  assert(vim.uv.fs_symlink(vim.fn.exepath("python3"), temp .. "/.venv/bin/python"))
  assert(require("config.languages.python").python_path(temp) == temp .. "/.venv/bin/python")

  local buf = open("sample.py", { "import os", 'value: int = "wrong"', "unknown_name", "os.pa" })
  local pyright = client("basedpyright", buf)
  local ruff = client("ruff", buf)
  assert(not ruff.server_capabilities.hoverProvider, "Ruff hover must not override basedpyright")
  assert(pyright.settings.python.pythonPath == temp .. "/.venv/bin/python", "wrong Python environment: " .. vim.inspect(pyright.settings.python))
  diagnostic(buf, function(d) return d.source == "basedpyright" end, "Python types")
  diagnostic(buf, function(d) return d.source == "Ruff" and d.code == "F821" end, "Ruff undefined name")
  completion(pyright, buf, 3, 5, "path")
  assert(vim.fn.maparg("gd", "n", false, true).buffer == 1)
  print("PASS: Python environment, basedpyright/Ruff diagnostics, LSP completion and mappings")
  vim.bo[buf].modified = false

  buf = open("imports.py", { "import sys", "import os", "print(os.name, sys.version)" })
  client("basedpyright", buf)
  client("ruff", buf)
  vim.fn.maparg("<Space>li", "n", false, true).callback()
  assert(vim.wait(10000, function()
    return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "import os"
  end, 50), "Ruff organize imports action failed")
  vim.bo[buf].modified = false

  buf = open("symbols.py", {
    "def greet(name: str) -> str:", "    return name.upper()", "", 'greeting = greet("hello")',
  })
  pyright = client("basedpyright", buf)
  local position = { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = 5 } }
  local hover = pyright:request_sync("textDocument/hover", position, 10000, buf)
  assert(hover and not hover.err and hover.result and hover.result.contents, "Python hover failed")
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  local hover_win
  vim.lsp.buf.hover()
  assert(vim.wait(5000, function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "markdown" then
        hover_win = win
        return true
      end
    end
    return false
  end, 20), "LSP hover window did not open")
  local hover_border = vim.api.nvim_win_get_config(hover_win).border
  assert(hover_border and hover_border[1] == "╭" and hover_border[5] == "╯", "LSP hover has no rounded border")
  vim.api.nvim_win_close(hover_win, true)
  local rename = pyright:request_sync("textDocument/rename", vim.tbl_extend("force", position, { newName = "salute" }), 10000, buf)
  assert(rename and not rename.err and rename.result, "Python rename failed")
  vim.lsp.util.apply_workspace_edit(rename.result, pyright.offset_encoding)
  local renamed = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  assert(renamed[1] == "def salute(name: str) -> str:" and renamed[4] == 'greeting = salute("hello")', "Python rename missed definition or reference")
  vim.bo[buf].modified = false
  print("PASS: bordered Python hover and rename edits; Ruff organize-imports code action")

  buf = open("format.py", { "value={'one':1,'two':2}" })
  format(buf)
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == 'value = {"one": 1, "two": 2}', "Black formatting failed")
  vim.cmd.write()
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == 'value = {"one": 1, "two": 2}')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "value=  1" })
  vim.cmd.write()
  vim.wait(300)
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "value=  1", "save unexpectedly formatted buffer")

  write("package.json", { '{"name":"neovim-language-test","private":true}' })
  write("package-lock.json", { '{"lockfileVersion":3}' })
  write("tsconfig.json", { '{"compilerOptions":{"strict":true,"noEmit":true},"include":["*.ts"]}' })
  buf = open("sample.ts", { 'const answer: number = "wrong";', "Math.ab" })
  local ts = client("tsc", buf)
  diagnostic(buf, function(d) return tonumber(d.code) == 2322 end, "TypeScript types")
  completion(ts, buf, 1, 7, "abs")
  assert(#vim.lsp.get_clients({ bufnr = buf, name = "eslint" }) == 0, "ESLint attached without project config")
  print("PASS: TypeScript diagnostics/completion; ESLint stays off without project config")
  vim.bo[buf].modified = false
  buf = open("format.ts", { "const answer={one:1,two:2}" })
  format(buf)
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "const answer = { one: 1, two: 2 };", "Prettier formatting failed")
  vim.bo[buf].modified = false

  local eslint_modules = vim.env.NVIM_TEST_ESLINT_NODE_MODULES
  if eslint_modules and eslint_modules ~= "" then
    eslint_modules = vim.fn.fnamemodify(eslint_modules, ":p"):gsub("/$", "")
    assert(vim.fn.filereadable(eslint_modules .. "/eslint/package.json") == 1, "ESLint library not found in " .. eslint_modules)
    write("eslint/package.json", { '{"name":"neovim-eslint-test","private":true}' })
    write("eslint/package-lock.json", { '{"lockfileVersion":3}' })
    write("eslint/eslint.config.cjs", {
      'module.exports = [{ files: ["**/*.js"], rules: { "no-undef": "error", semi: ["error", "always"] } }];',
    })
    assert(vim.uv.fs_symlink(eslint_modules, temp .. "/eslint/node_modules", { dir = true }))
    buf = open("eslint/sample.js", { "unknown_name()" })
    client("eslint", buf)
    diagnostic(buf, function(d) return d.source == "eslint" and d.code == "no-undef" end, "ESLint no-undef")
    diagnostic(buf, function(d) return d.source == "eslint" and d.code == "semi" end, "ESLint semi")
    vim.cmd("LspEslintFixAll")
    assert(vim.wait(10000, function()
      return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "unknown_name();"
    end, 50), "ESLint fix-all failed")
    vim.bo[buf].modified = false
    print("PASS: project ESLint attachment, diagnostics and fix-all")
  else
    print("SKIP: project ESLint fixture (set NVIM_TEST_ESLINT_NODE_MODULES to an installed project's node_modules)")
  end

  write("schema.json", { '{"type":"object","required":["required_field"],"properties":{"required_field":{"type":"string"}}}' })
  buf = open("sample.yaml", { "# yaml-language-server: $schema=./schema.json", "other: value" })
  client("yamlls", buf)
  diagnostic(buf, function(d) return d.message:find("required_field", 1, true) end, "YAML local schema")

  if vim.env.NVIM_TEST_REMOTE_SCHEMAS == "1" then
    local manifest = {
      "apiVersion: apps/v1", "kind: Deployment", "metadata:", "  name: neovim-test",
      "spec:", '  replicas: "not-a-number"', "  selector:", "    matchLabels:",
      "      app: neovim-test", "  template:", "    metadata:", "      labels:",
      "        app: neovim-test", "    spec:", "      containers:", "        - name: test",
      "          image: nginx:latest",
    }
    local function has_kubernetes_schema(c, buffer)
      local response = c:request_sync("yaml/get/jsonSchema", vim.uri_from_bufnr(buffer), 30000, buffer)
      assert(response and not response.err, "schema selection request failed: " .. vim.inspect(response))
      for _, schema in ipairs(response.result or {}) do
        if schema.uri:lower():find("kubernetes", 1, true) then return true end
      end
      return false
    end
    for _, name in ipairs({ "deployment.k8s.yaml", "k8s/deployment.yaml", "kubernetes/deployment.yml" }) do
      buf = open(name, manifest)
      local yaml = client("yamlls", buf)
      assert(has_kubernetes_schema(yaml, buf), "Kubernetes schema not selected: " .. name)
      diagnostic(buf, function(d)
        return d.lnum == 5 and d.message:lower():find("integer", 1, true)
      end, "Kubernetes replicas type: " .. name)
    end
    buf = open("unrelated.yaml", manifest)
    assert(not has_kubernetes_schema(client("yamlls", buf), buf), "Kubernetes schema leaked into unrelated YAML")
    print("PASS: remote Kubernetes schema selection/validation; unrelated YAML excluded")
  else
    print("SKIP: remote Kubernetes schemas (set NVIM_TEST_REMOTE_SCHEMAS=1; requires network)")
  end

  buf = open("sample.jsonc", { "// comments are valid JSONC", '{"$schema":"./schema.json","other":1}' })
  client("jsonls", buf)
  diagnostic(buf, function(d) return d.message:find("required_field", 1, true) end, "JSONC local schema")
  assert(vim.treesitter.get_parser(buf):lang() == "json", "JSONC highlighting not active")
  print("PASS: YAML/JSONC schema diagnostics and JSONC highlighting")

  buf = open("sample.sql", { "select  1 as one" })
  require("lint").try_lint("sqlfluff")
  diagnostic(buf, function(d) return d.source == "sqlfluff" end, "SQLFluff")
  format(buf)
  local sql = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  assert(not sql:find("select  1", 1, true), "SQLFluff did not format")
  vim.bo[buf].modified = false
  write("mysql/.sqlfluff", { "[sqlfluff]", "dialect = mysql" })
  local mysql_file = write("mysql/sample.sql", { "SELECT `one` FROM `table`;" })
  local result = vim.system({ mason .. "sqlfluff", "lint", "--format=json", "--stdin-filename", mysql_file, "-" }, {
    cwd = temp, stdin = "SELECT `one` FROM `table`;\n", text = true,
  }):wait(15000)
  assert(result.code == 0 or result.code == 1, "SQLFluff config failed: " .. (result.stderr or ""))
  for _, file in ipairs(vim.json.decode(result.stdout)) do
    for _, violation in ipairs(file.violations) do
      assert(violation.code ~= "PRS", "Postgres default overrode MySQL project config")
    end
  end
  print("PASS: SQLFluff diagnostics/formatting; project dialect overrides Postgres default")

  buf = open("sample.ini", { "[section]", "key=value" })
  assert(vim.treesitter.get_parser(buf):lang() == "ini", "INI highlighting not active")
  assert(vim.v.errmsg == "", "Neovim error: " .. vim.v.errmsg)
  print("PASS: INI highlighting; manual Black/Prettier formatting; no format-on-save")
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  local clients = vim.lsp.get_clients({ _uninitialized = true })
  for _, c in ipairs(clients) do c:stop(5000) end
  -- is_stopped() is already true while shutdown is pending; wait for exit/removal.
  local exited = vim.wait(10000, function()
    for _, c in ipairs(clients) do
      if vim.lsp.get_client_by_id(c.id) then return false end
    end
    return true
  end, 50)
  if not exited then
    ok = false
    err = (err and err .. "\n" or "") .. "LSP teardown timed out; temporary workspace retained: " .. temp
  end
  if not exited then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
    return
  end
  print("PASS: LSP clients exited before workspace cleanup")
  vim.cmd("silent! %bwipeout!")
  vim.fn.delete(temp, "rf")
  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  else
    vim.cmd("qa!")
  end
end)
