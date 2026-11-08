return {
  servers = { "lua_ls" },
  tools = { "stylua" },
  formatters_by_ft = { lua = { "stylua" } },
  setup_lsp = function()
    vim.lsp.config("lua_ls", {
      on_init = function(client)
        local root = client.config.root_dir
        if not root or vim.uv.fs_realpath(root) ~= vim.uv.fs_realpath(vim.fn.stdpath("config")) then
          return
        end
        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
          runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
          workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
        })
      end,
    })
  end,
}
