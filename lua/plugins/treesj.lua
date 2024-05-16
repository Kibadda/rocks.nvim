require("me.lazy").on("treesj", {
  by_keys = {
    { mode = "n", lhs = "gJ", rhs = "<Cmd>TSJToggle<CR>", desc = "Join/Split Lines" },
  },
}, function()
  require("treesj").setup {
    use_default_keymaps = false,
    max_join_length = 1000,
  }
end)
