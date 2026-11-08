local exit_code, exit_signal
local id

vim.schedule(function()
  local ok, err = xpcall(function()
    local executable = vim.fn.stdpath("data") .. "/mason/bin/tsc"
    assert(vim.fn.executable(executable) == 1, "Mason TypeScript is not installed")
    id = assert(vim.lsp.start({
      name = "tsc-shutdown-probe",
      cmd = { executable, "--lsp", "--stdio" },
      root_dir = vim.fn.getcwd(),
      on_exit = function(code, signal)
        exit_code, exit_signal = code, signal
      end,
    }, { attach = false }))
    assert(
      vim.wait(15000, function()
        local client = vim.lsp.get_client_by_id(id)
        return exit_code ~= nil or (client and client.initialized)
      end, 50),
      "TypeScript initialization timed out"
    )
    local client = assert(vim.lsp.get_client_by_id(id), "TypeScript exited before shutdown")
    assert(client.initialized, "TypeScript did not initialize")
    local response = client:request_sync("shutdown", nil, 5000)
    assert(response and not response.err, "shutdown request failed: " .. vim.inspect(response))
    assert(client:notify("exit"), "exit notification failed")
    assert(
      vim.wait(10000, function()
        return exit_code ~= nil
      end, 50),
      "TypeScript exit timed out"
    )
    assert(
      exit_code == 0 and exit_signal == 0,
      "TypeScript graceful shutdown failed: exit=" .. tostring(exit_code) .. " signal=" .. tostring(exit_signal)
    )
    print("PASS: TypeScript initialized and exited cleanly without opening any files")
  end, debug.traceback)
  if not ok then
    local client = id and vim.lsp.get_client_by_id(id)
    if client then
      client:stop(true)
      vim.wait(2000, function()
        return vim.lsp.get_client_by_id(id) == nil
      end, 50)
    end
    io.stderr:write(err .. "\n")
  end
  vim.cmd(ok and "qa!" or "cquit 1")
end)
