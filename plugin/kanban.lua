if vim.g.loaded_kanban then
  return
end

vim.g.loaded_kanban = 1

vim.keymap.set("n", "<Leader>k", function()
  require("me.dotenv").load()
  require("me.kanban").toggle()
end, { desc = "Kanban" })
