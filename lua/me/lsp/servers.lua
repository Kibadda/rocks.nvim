---@type { filetypes: string[], root_markers: string[], config: vim.lsp.ClientConfig }[]
local servers = {
  {
    filetypes = { "lua" },
    root_markers = { ".luarc.json", "stylua.toml", ".stylua.toml" },
    config = {
      cmd = { "lua-language-server" },
      before_init = function(params, config)
        if not params.rootPath or type(params.rootPath) ~= "string" then
          return
        end

        config.settings.Lua.workspace.library = config.settings.Lua.workspace.library or {}

        ---@diagnostic disable-next-line:param-type-mismatch
        if params.rootPath:find(vim.fn.stdpath "config") then
          config.settings.Lua.runtime.version = "LuaJIT"

          table.insert(config.settings.Lua.workspace.library, vim.env.VIMRUNTIME .. "/lua")
          table.insert(config.settings.Lua.workspace.library, vim.fn.stdpath "data" .. "/rocks/share/lua/5.1")

          for name, type in vim.fs.dir(vim.fn.stdpath "data" .. "/site/pack/rocks/start/") do
            if type == "directory" then
              table.insert(
                config.settings.Lua.workspace.library,
                vim.fn.stdpath "data" .. "/site/pack/rocks/start/" .. name .. "/lua"
              )
            end
          end
        end

        if vim.fn.isdirectory(params.rootPath .. "/lua") == 1 then
          table.insert(config.settings.Lua.workspace.library, params.rootPath .. "/lua")
        end
      end,
      settings = {
        Lua = {
          runtime = {
            pathStrict = true,
          },
          format = {
            enable = false,
          },
          workspace = {
            checkThirdParty = false,
          },
          hint = {
            enable = true,
            arrayIndex = "Disable",
          },
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    },
  },
}

local lsp = require "me.lsp"
for _, server in ipairs(servers) do
  lsp.register(server)
end
