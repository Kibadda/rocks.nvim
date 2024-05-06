require("mason").setup {
  ui = {
    border = "single",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
}

vim.keymap.set("n", "<Leader>M", "<Cmd>Mason<CR>", { desc = "Mason" })

local registry = require "mason-registry"
local installed = registry.get_installed_package_names()

local function install(name)
  if not vim.tbl_contains(installed, name) then
    registry.get_package(name):install()
  end
end

for _, server in ipairs(require "me.lsp.servers") do
  install(server.config.name or server.config.cmd[1])
end

for _, tool in ipairs { "stylua" } do
  install(tool)
end
