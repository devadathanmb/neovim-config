local M = {
  servers = { "lua_ls" },
  tools = { "stylua" },
  formatters_by_ft = { lua = { "stylua" } },
}

-- Shared by the editor and the repository-wide LuaLS check.
function M.config_settings()
  local library = { vim.env.VIMRUNTIME }
  local plugins = require("lazy.core.config").plugins
  for _, name in ipairs({ "mini.test", "snacks.nvim" }) do
    if plugins[name] then
      library[#library + 1] = plugins[name].dir .. "/lua"
    end
  end
  return {
    runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
    workspace = { checkThirdParty = false, library = library },
  }
end

function M.setup_lsp()
  vim.lsp.config("lua_ls", {
    on_init = function(client)
      local root = client.config.root_dir
      if not root or vim.uv.fs_realpath(root) ~= vim.uv.fs_realpath(vim.fn.stdpath("config")) then
        return
      end
      client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, M.config_settings())
    end,
  })
end

return M
