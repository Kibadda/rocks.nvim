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

local installed = require("mason-registry").get_installed_package_names()

for _, name in ipairs {
  "lua-language-server",
  "stylua",
} do
  if not vim.tbl_contains(installed, name) then
    require("mason-registry").get_package(name):install()
  end
end
